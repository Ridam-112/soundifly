import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Lightweight on-device loopback proxy (127.0.0.1) that intercepts Android MediaPlayer
/// requests and forwards them with valid browser User-Agent and Range headers.
///
/// This eliminates the infamous Android MediaPlayer 403 Forbidden error caused by
/// Google Video / YouTube blocking native MediaPlayer HEAD requests.
class StreamProxyService {
  static HttpServer? _server;
  static int _port = 0;
  static final Map<String, String> _urlTokenMap = {};

  static int get port => _port;
  static bool get isRunning => _server != null;

  /// Starts the local proxy server on an ephemeral loopback port
  static Future<void> ensureStarted() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      debugPrint('[StreamProxyService] Local stream proxy started on 127.0.0.1:$_port');

      _server!.listen(_handleRequest, onError: (e) {
        debugPrint('[StreamProxyService] Server error: $e');
      });
    } catch (e) {
      debugPrint('[StreamProxyService] Failed to start local proxy: $e');
    }
  }

  /// Converts a remote googlevideo.com URL into a local proxy URL that Android MediaPlayer
  /// can play without 403 Forbidden errors.
  static String getProxiedUrl(String directUrl) {
    if (_port == 0 || !directUrl.contains('googlevideo.com')) {
      return directUrl;
    }
    final token = DateTime.now().microsecondsSinceEpoch.toString();
    _urlTokenMap[token] = directUrl;

    // Prune map if too large
    if (_urlTokenMap.length > 50) {
      final keysToRemove = _urlTokenMap.keys.take(20).toList();
      for (final k in keysToRemove) {
        _urlTokenMap.remove(k);
      }
    }

    return 'http://127.0.0.1:$_port/stream?token=$token';
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    final token = request.uri.queryParameters['token'];
    final targetUrl = token != null ? _urlTokenMap[token] : null;

    if (targetUrl == null || targetUrl.isEmpty) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    // Crucial: Android MediaPlayer sends HEAD first. Return 200 OK with audio/mp4 headers
    if (request.method == 'HEAD') {
      response.statusCode = HttpStatus.ok;
      response.headers.set('Content-Type', 'audio/mp4');
      response.headers.set('Accept-Ranges', 'bytes');
      response.headers.set('Content-Length', '15000000');
      await response.close();
      return;
    }

    // Handle GET: stream bytes from googlevideo with proper headers
    try {
      final client = http.Client();
      final uri = Uri.parse(targetUrl);
      final req = http.Request('GET', uri);

      req.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      // Forward Range header if requested by MediaPlayer
      final range = request.headers.value('range');
      if (range != null) {
        req.headers['Range'] = range;
      }

      final streamedRes = await client.send(req);

      response.statusCode = streamedRes.statusCode;
      streamedRes.headers.forEach((name, value) {
        if (name.toLowerCase() == 'content-type' ||
            name.toLowerCase() == 'content-length' ||
            name.toLowerCase() == 'content-range' ||
            name.toLowerCase() == 'accept-ranges') {
          response.headers.set(name, value);
        }
      });

      await streamedRes.stream.pipe(response);
    } catch (e) {
      debugPrint('[StreamProxyService] Pipe error: $e');
      if (!response.headers.persistentConnection) {
        try {
          response.statusCode = HttpStatus.internalServerError;
          await response.close();
        } catch (_) {}
      }
    }
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = 0;
    _urlTokenMap.clear();
  }
}
