import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageClassifierService {
  static const String modelAsset =
      'assets/ml/mobilenet_v2_feature_vector.tflite';
  static const int inputSize = 224;

  Interpreter? _interpreter;
  bool _isQuantized = true;
  bool _isEmbeddingModel = false;

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
    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    debugPrint(
      'MODEL INPUT: shape=${inputTensor.shape} type=${inputTensor.type}',
    );
    debugPrint(
      'MODEL OUTPUT: shape=${outputTensor.shape} type=${outputTensor.type}',
    );
    _isEmbeddingModel =
        outputTensor.shape.length == 2 && outputTensor.shape.last >= 100;
    if (!_isEmbeddingModel) {
      debugPrint(
        'MODEL WARNING: output is not a feature embedding. '
        'Visual spare-part matching is disabled for this model.',
      );
    }
    final inputType = inputTensor.type;
    _isQuantized = inputType == TensorType.uint8;
  }

  Future<List<double>> getEmbedding(File imageFile) async {
    await load();
    if (!_isEmbeddingModel) {
      throw UnsupportedError(
        'Visual matching requires a trained feature-embedding model; '
        'the loaded model output is classification data.',
      );
    }

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image. Try another photo.');
    }

    final scale = math.max(
      inputSize / decoded.width,
      inputSize / decoded.height,
    );
    final resized = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
    final cropped = img.copyCrop(
      resized,
      x: (resized.width - inputSize) ~/ 2,
      y: (resized.height - inputSize) ~/ 2,
      width: inputSize,
      height: inputSize,
    );

    final input = _buildInput(cropped);
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final embeddingDim = outputShape.length > 1
        ? outputShape[1]
        : outputShape.last;

    final output = [List<double>.filled(embeddingDim, 0.0)];
    _interpreter!.run(input, output);

    final values = output[0];
    var norm = 0.0;
    for (final value in values) {
      norm += value * value;
    }
    norm = math.sqrt(norm);
    return norm == 0.0 ? values : values.map((value) => value / norm).toList();
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
    _isEmbeddingModel = false;
  }
}

final imageClassifierService = ImageClassifierService();
