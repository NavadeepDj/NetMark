// Web no-op implementation to avoid dart:ffi usage
import 'tflite_interpreter_base.dart';

class TfliteInterpreterWeb implements TfliteInterpreter {
  @override
  bool get isLoaded => false;

  @override
  Future<void> loadModel(String assetPath) async {
    throw UnsupportedError('TFLite is not supported on web in this project.');
  }

  @override
  void run(Object input, Object output) {
    throw UnsupportedError('TFLite is not supported on web in this project.');
  }

  @override
  void close() {}
}


