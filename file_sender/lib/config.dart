class Config {
  static String serverUrl = 'http://10.2.8.97:5000'; // Default URL

  static void updateServerUrl(String newUrl) {
    serverUrl = newUrl.trim();
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'http://$serverUrl';
    }
  }
}
