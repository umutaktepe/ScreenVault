import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';

/// Robust TMDB API v3 HTTP Client with serialized Rate Limiting, global pause,
/// 429 Retry-After support with safety margins and exponential backoff + jitter.
class TmdbClient {
  final Dio _dio;
  final HttpClient _fallbackClient = HttpClient();

  // Serialized FIFO Token Bucket rate limiter (18 requests/second - 15-20 req/sec balance)
  final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerWindow = 18;
  static const Duration _rateWindow = Duration(seconds: 1);
  Future<void> _throttleQueue = Future.value();

  // Global queue pause shared across all concurrent requests
  static DateTime? _pauseUntil;

  // Callback to notify listeners (e.g. migration progress UI) of rate limiting state
  void Function(bool isPaused, Duration remaining)? onRateLimitStateChanged;

  TmdbClient({Dio? dio, this.onRateLimitStateChanged})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Accept': 'application/json',
                  'User-Agent': 'ScreenVault/1.0',
                },
              ),
            ) {
    _fallbackClient.userAgent = 'ScreenVault/1.0';
    _fallbackClient.connectionTimeout = const Duration(seconds: 10);
  }

  Future<void> _throttle() {
    final completer = Completer<void>();
    _throttleQueue = _throttleQueue.then((_) async {
      // Check global pause
      if (_pauseUntil != null) {
        final remaining = _pauseUntil!.difference(DateTime.now());
        if (remaining > Duration.zero) {
          await Future.delayed(remaining);
        }
        if (_pauseUntil != null && DateTime.now().isAfter(_pauseUntil!)) {
          _pauseUntil = null;
        }
      }

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

  /// Sends a GET request with automatic 429 retry, global queue pause, and fallback
  Future<Map<String, dynamic>> get(Uri uri, {int retries = 6}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      await _throttle();

      try {
        final response = await _dio.getUri<dynamic>(uri);
        if (response.data != null) {
          if (response.data is Map<String, dynamic>) {
            return response.data as Map<String, dynamic>;
          } else if (response.data is Map) {
            return Map<String, dynamic>.from(response.data as Map);
          }
          return {};
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // 1. HTTP 429 Too Many Requests: Apply safety margin backoff & global queue pause
        if (statusCode == 429) {
          Duration delayDuration;
          final retryAfter = e.response?.headers.value('retry-after');
          if (retryAfter != null) {
            final seconds = int.tryParse(retryAfter) ?? 2;
            // Retry-After header + 500ms safety margin
            delayDuration = Duration(milliseconds: (seconds * 1000) + 500);
          } else {
            // Exponential backoff (1.5s, 3s, 6s, 12s, 24s...) + random jitter (0-500ms)
            final baseMs = (1500 * math.pow(2, attempt)).toInt();
            final jitterMs = math.Random().nextInt(500);
            delayDuration = Duration(milliseconds: baseMs + jitterMs);
          }

          final targetResume = DateTime.now().add(delayDuration);
          if (_pauseUntil == null || targetResume.isAfter(_pauseUntil!)) {
            _pauseUntil = targetResume;
          }

          onRateLimitStateChanged?.call(true, delayDuration);
          await Future.delayed(delayDuration);
          onRateLimitStateChanged?.call(false, Duration.zero);
          continue;
        }

        // 2. Client errors (400, 401, 403, 404, etc.): Non-retryable
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return {};
        }

        // 3. Server errors or network timeouts: Retry at most once if attempt < 1
        if (attempt >= 1) {
          return await _fallbackGet(uri);
        }
      } catch (_) {
        if (attempt >= 1) {
          return await _fallbackGet(uri);
        }
      }
    }

    return await _fallbackGet(uri);
  }

  Future<Map<String, dynamic>> _fallbackGet(Uri uri) async {
    try {
      final request = await _fallbackClient.getUrl(uri);
      request.headers.set('Accept', 'application/json');
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
