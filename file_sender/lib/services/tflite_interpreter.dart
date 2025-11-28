export 'tflite_interpreter_base.dart';

// Conditional export based on platform
// ignore: uri_does_not_exist
export 'tflite_interpreter_io.dart'
    if (dart.library.js) 'tflite_interpreter_web.dart';
