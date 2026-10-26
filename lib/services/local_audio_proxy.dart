import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocalAudioProxy {
  static HttpServer? _server;
  static int? _port;
  static final http.Client _client = http.Client();

  static const String browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static Future<int> ensureStarted() async {
    if (_server != null && _port != null) return _port!;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      debugPrint('[LocalAudioProxy] Started on port $_port');
      _server!.listen(_handleRequest);
      return _port!;
    } catch (e) {
      debugPrint('[LocalAudioProxy] Start error: $e');
      return 0;
    }
  }

  static Future<String> getProxyUrl(String remoteUrl) async {
    final port = await ensureStarted();
    if (port == 0) return remoteUrl;
    final encoded = Uri.encodeComponent(remoteUrl);
    return 'http://127.0.0.1:$port/stream?url=$encoded';
  }

  static void _handleRequest(HttpRequest req) async {
    try {
      final remoteUrl = req.uri.queryParameters['url'];
      if (remoteUrl == null || remoteUrl.isEmpty) {
        req.response.statusCode = HttpStatus.badRequest;
        await req.response.close();
        return;
      }

      final targetUri = Uri.parse(remoteUrl);
      final clientReq = http.Request(req.method, targetUri);
      clientReq.headers['User-Agent'] = browserUserAgent;
      clientReq.headers['Accept'] = '*/*';

      final range = req.headers.value(HttpHeaders.rangeHeader);
      if (range != null) {
        clientReq.headers['Range'] = range;
      }

      final clientRes = await _client.send(clientReq);
      req.response.statusCode = clientRes.statusCode;

      clientRes.headers.forEach((name, val) {
        final lower = name.toLowerCase();
        if (lower != 'transfer-encoding' && lower != 'connection') {
          req.response.headers.set(name, val);
        }
      });
      req.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

      await clientRes.stream.pipe(req.response);
    } catch (e) {
      debugPrint('[LocalAudioProxy] Proxy request error: $e');
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      } catch (_) {}
    }
  }
}
