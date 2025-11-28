// IO/Native implementation (Android/iOS/Desktop)
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'tflite_interpreter_base.dart';

class TfliteInterpreterIo implements TfliteInterpreter {
  tfl.Interpreter? _interpreter;

  @override
  bool get isLoaded => _interpreter != null;

  @override
  Future<void> loadModel(String assetPath) async {
    _interpreter = await tfl.Interpreter.fromAsset(assetPath);
  }

  @override
  void run(Object input, Object output) {
    if (_interpreter == null) {
      throw StateError('Interpreter not loaded');
    }
    _interpreter!.run(input, output);
  }

  @override
  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}


