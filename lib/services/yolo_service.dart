import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Prediction {
  final double x1; // normalized 0..1
  final double y1; // normalized 0..1
  final double x2; // normalized 0..1
  final double y2; // normalized 0..1
  final double score;
  final int classId;
  final String label;

  Prediction({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.score,
    required this.classId,
    required this.label,
  });

  double get width => x2 - x1;
  double get height => y2 - y1;

  @override
  String toString() {
    return 'Prediction(label: $label, score: ${score.toStringAsFixed(2)}, bbox: [${x1.toStringAsFixed(3)}, ${y1.toStringAsFixed(3)}, ${x2.toStringAsFixed(3)}, ${y2.toStringAsFixed(3)}])';
  }
}

class YoloService {
  static const String modelAsset = 'assets/ml/yolov8n.tflite';
  static const int inputSize = 640;

  Interpreter? _interpreter;
  bool _isLoaded = false;

  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux;
  }

  Future<void> load() async {
    if (_isLoaded && _interpreter != null) return;

    if (!isPlatformSupported) {
      throw UnsupportedError(
        'YOLO object detection is not supported on this platform (web).',
      );
    }

    try {
      _interpreter = await Interpreter.fromAsset(modelAsset);
      _isLoaded = true;
      print("YOLO model loaded successfully.");
    } catch (e) {
      print("Failed to load YOLO model: $e");
      // Keep _isLoaded = false, we will check it before running
    }
  }

  // Run YOLO model on an image file.
  // Returns a list of predictions filtered by confidence threshold and NMS.
  Future<List<Prediction>> detectObjects(File imageFile, {double threshold = 0.25, double iouThreshold = 0.45}) async {
    await load();
    if (_interpreter == null) {
      print("YOLO interpreter is null. Model failed to load.");
      return [];
    }

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image.');
    }

    // Resize image to 640x640
    final resized = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Build float input buffer [1, 640, 640, 3]
    final input = _buildInput(resized);

    // Check outputs
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape; // e.g. [1, 84, 8400] or [1, 8400, 84] or [1, 25200, 85]

    int numAnchors;
    int numElements;
    bool isAnchorsFirst = false;

    if (outputShape[1] > outputShape[2]) {
      numAnchors = outputShape[1];
      numElements = outputShape[2];
      isAnchorsFirst = true;
    } else {
      numElements = outputShape[1];
      numAnchors = outputShape[2];
      isAnchorsFirst = false;
    }

    final numClasses = numElements - (numElements == 85 || numElements > 80 ? 5 : 4);
    final bool isYolov5 = numElements == (numClasses + 5); // has objectness score

    // Allocate output buffer
    List<List<List<double>>>? outputBuffer3D;
    List<List<double>>? outputBuffer2D;

    if (isAnchorsFirst) {
      // Shape: [1, numAnchors, numElements]
      outputBuffer2D = List.generate(numAnchors, (_) => List.filled(numElements, 0.0));
      _interpreter!.run(input, [outputBuffer2D]);
    } else {
      // Shape: [1, numElements, numAnchors]
      outputBuffer3D = List.generate(1, (_) => List.generate(numElements, (_) => List.filled(numAnchors, 0.0)));
      _interpreter!.run(input, outputBuffer3D);
    }

    final List<Prediction> candidates = [];

    for (int i = 0; i < numAnchors; i++) {
      double xCenter, yCenter, w, h;
      double objConf = 1.0;
      double maxClassScore = 0.0;
      int bestClassId = -1;

      if (isAnchorsFirst) {
        final row = outputBuffer2D![i];
        xCenter = row[0];
        yCenter = row[1];
        w = row[2];
        h = row[3];
        if (isYolov5) {
          objConf = row[4];
          for (int c = 0; c < numClasses; c++) {
            final score = row[5 + c];
            if (score > maxClassScore) {
              maxClassScore = score;
              bestClassId = c;
            }
          }
        } else {
          for (int c = 0; c < numClasses; c++) {
            final score = row[4 + c];
            if (score > maxClassScore) {
              maxClassScore = score;
              bestClassId = c;
            }
          }
        }
      } else {
        final buffer = outputBuffer3D![0];
        xCenter = buffer[0][i];
        yCenter = buffer[1][i];
        w = buffer[2][i];
        h = buffer[3][i];
        if (isYolov5) {
          objConf = buffer[4][i];
          for (int c = 0; c < numClasses; c++) {
            final score = buffer[5 + c][i];
            if (score > maxClassScore) {
              maxClassScore = score;
              bestClassId = c;
            }
          }
        } else {
          for (int c = 0; c < numClasses; c++) {
            final score = buffer[4 + c][i];
            if (score > maxClassScore) {
              maxClassScore = score;
              bestClassId = c;
            }
          }
        }
      }

      final confidence = objConf * maxClassScore;
      if (confidence >= threshold && bestClassId >= 0) {
        // Detect if coordinates are already normalized
        final bool areCoordsPixel = xCenter > 2.0 || w > 2.0;
        final double divisor = areCoordsPixel ? inputSize.toDouble() : 1.0;

        final double x1 = ((xCenter - w / 2.0) / divisor).clamp(0.0, 1.0);
        final double y1 = ((yCenter - h / 2.0) / divisor).clamp(0.0, 1.0);
        final double x2 = ((xCenter + w / 2.0) / divisor).clamp(0.0, 1.0);
        final double y2 = ((yCenter + h / 2.0) / divisor).clamp(0.0, 1.0);

        final label = 'Part ${bestClassId + 1}';

        candidates.add(Prediction(
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          score: confidence,
          classId: bestClassId,
          label: label,
        ));
      }
    }

    // Apply Non-Maximum Suppression
    return _nms(candidates, iouThreshold);
  }

  // Crops the detected box from the original image and returns a temporary file.
  static Future<File?> cropPrediction(File originalImageFile, Prediction pred) async {
    try {
      final bytes = await originalImageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final int x = (pred.x1 * decoded.width).round().clamp(0, decoded.width - 1);
      final int y = (pred.y1 * decoded.height).round().clamp(0, decoded.height - 1);
      final int w = (pred.width * decoded.width).round().clamp(1, decoded.width - x);
      final int h = (pred.height * decoded.height).round().clamp(1, decoded.height - y);

      final cropped = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      final croppedBytes = img.encodeJpg(cropped);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/yolo_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(croppedBytes);
      return tempFile;
    } catch (e) {
      print("Error cropping image: $e");
      return null;
    }
  }

  List<List<List<List<double>>>> _buildInput(img.Image image) {
    final buffer = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List.filled(3, 0.0)),
      ),
    );

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        // Normalize coordinates to 0..1 range
        buffer[0][y][x][0] = pixel.r / 255.0;
        buffer[0][y][x][1] = pixel.g / 255.0;
        buffer[0][y][x][2] = pixel.b / 255.0;
      }
    }
    return buffer;
  }

  List<Prediction> _nms(List<Prediction> predictions, double iouThreshold) {
    predictions.sort((a, b) => b.score.compareTo(a.score));
    final List<Prediction> selected = [];

    for (var pred in predictions) {
      bool keep = true;
      for (var sel in selected) {
        if (_boxIoU(pred, sel) > iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) {
        selected.add(pred);
      }
    }
    return selected;
  }

  double _boxIoU(Prediction a, Prediction b) {
    final double x1 = math.max(a.x1, b.x1);
    final double y1 = math.max(a.y1, b.y1);
    final double x2 = math.min(a.x2, b.x2);
    final double y2 = math.min(a.y2, b.y2);

    final double interArea = math.max(0.0, x2 - x1) * math.max(0.0, y2 - y1);
    final double areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final double areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    final double unionArea = areaA + areaB - interArea;

    if (unionArea == 0.0) return 0.0;
    return interArea / unionArea;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
