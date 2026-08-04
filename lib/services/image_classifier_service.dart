import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// On-device MobileNetV2 feature extractor (TensorFlow Lite).
class ImageClassifierService {
  static const String modelAsset = 'assets/ml/model_unquant.tflite';
  static const int inputSize = 224;

  Interpreter? _interpreter;
  bool _isQuantized = true;

  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux;
  }

  Future<void> load() async {
    if (_interpreter != null) return;

    if (!isPlatformSupported) {
      throw UnsupportedError(
        'Image recognition is not supported on this platform (web).',
      );
    }

    _interpreter = await Interpreter.fromAsset(modelAsset);
    final inputType = _interpreter!.getInputTensor(0).type;
    _isQuantized = inputType == TensorType.uint8;
  }

  // Extracts a 1001-dimensional feature embedding vector from the image.
  Future<List<double>> getEmbedding(File imageFile) async {
    await load();

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image. Try another photo.');
    }

    final resized = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = _buildInput(resized);
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final embeddingDim = outputShape.length > 1 ? outputShape[1] : outputShape.last;

    final output = [List<double>.filled(embeddingDim, 0.0)];
    _interpreter!.run(input, output);

    return output[0];
  }

  // Calculates the Cosine Similarity between two float vectors.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  Object _buildInput(img.Image image) {
    if (_isQuantized) {
      final buffer = Uint8List(inputSize * inputSize * 3);
      var i = 0;
      for (var y = 0; y < inputSize; y++) {
        for (var x = 0; x < inputSize; x++) {
          final pixel = image.getPixel(x, y);
          buffer[i++] = pixel.r.round();
          buffer[i++] = pixel.g.round();
          buffer[i++] = pixel.b.round();
        }
      }
      return buffer.reshape([1, inputSize, inputSize, 3]);
    }

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
        buffer[0][y][x][0] = (pixel.r / 127.5) - 1.0;
        buffer[0][y][x][1] = (pixel.g / 127.5) - 1.0;
        buffer[0][y][x][2] = (pixel.b / 127.5) - 1.0;
      }
    }
    return buffer;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

final imageClassifierService = ImageClassifierService();

