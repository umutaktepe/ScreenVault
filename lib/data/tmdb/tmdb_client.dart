import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// Robust TMDB API v3 HTTP Client with serialized Rate Limiting and 429 Retry-After support
class TmdbClient {
  final Dio _dio;
  final HttpClient _fallbackClient = HttpClient();

  // Serialized FIFO Token Bucket rate limiter (max 35 requests/second)
  final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerWindow = 35;
  static const Duration _rateWindow = Duration(seconds: 1);
  Future<void> _throttleQueue = Future.value();

  TmdbClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                  'User-Agent': 'ScreenVault/1.0',
                },
              ),
            ) {
    _fallbackClient.userAgent = 'ScreenVault/1.0';
  }

  Future<void> _throttle() {
    final completer = Completer<void>();
    _throttleQueue = _throttleQueue.then((_) async {
      final now = DateTime.now();
      _requestTimestamps.removeWhere((t) => now.difference(t) > _rateWindow);

      if (_requestTimestamps.length >= _maxRequestsPerWindow) {
        final oldest = _requestTimestamps.first;
        final waitDuration = _rateWindow - now.difference(oldest);
        if (waitDuration > Duration.zero) {
          await Future.delayed(waitDuration);
        }
      }
      _requestTimestamps.add(DateTime.now());
      completer.complete();
    }).catchError((e) {
      completer.complete();
    });
    return completer.future;
  }

  /// Sends a GET request with automatic 429 retry and fallback
  Future<Map<String, dynamic>> get(Uri uri, {int retries = 3}) async {
    await _throttle();

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await _dio.getUri<Map<String, dynamic>>(uri);
        if (response.data != null) {
          return response.data!;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          // Handle 429 Too Many Requests with Retry-After header
          int delaySeconds = 1;
          final retryAfter = e.response?.headers.value('retry-after');
          if (retryAfter != null) {
            delaySeconds = int.tryParse(retryAfter) ?? 1;
          }
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        if (e.response?.statusCode == 401) {
          return {};
        }

        if (attempt == retries - 1) {
          return await _fallbackGet(uri);
        }
      } catch (_) {
        if (attempt == retries - 1) {
          return await _fallbackGet(uri);
        }
      }
    }

    return await _fallbackGet(uri);
  }

  Future<Map<String, dynamic>> _fallbackGet(Uri uri) async {
    try {
      final request = await _fallbackClient.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  void dispose() {
    _dio.close();
    _fallbackClient.close();
  }
}
