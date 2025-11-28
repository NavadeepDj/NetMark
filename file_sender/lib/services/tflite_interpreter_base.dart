abstract class TfliteInterpreter {
  bool get isLoaded;

  Future<void> loadModel(String assetPath);

  void run(Object input, Object output);

  void close();
}


