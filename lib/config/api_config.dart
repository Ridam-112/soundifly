class ApiConfig {
  /// Base server URL.
  /// When deploying to a cloud server (Render, Railway, Koyeb, VPS) or tunnel (LocalTunnel, Ngrok),
  /// update this URL or pass `--dart-define=API_URL=https://your-server-url.com` during build.
  static const String serverUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001',
  );

  static String get baseUrl => '$serverUrl/api';
  static String get lyricsUrl => '$baseUrl/lyrics';
  static String get imageProxyUrl => '$baseUrl/image-proxy';
}
