import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/core/constants/app_constants.dart';
import 'package:screenvault/data/tmdb/tmdb_endpoints.dart';
import 'package:screenvault/data/tmdb/tmdb_client.dart';
import 'package:screenvault/data/tmdb/tmdb_service.dart';

void main() {
  group('TMDB Client & Endpoints Enhanced Tests', () {
    test('Verifies searchMovie endpoint with and without release year', () {
      final uriWithoutYear = TmdbEndpoints.searchMovie('Inception');
      expect(uriWithoutYear.path, '/3/search/movie');
      expect(uriWithoutYear.queryParameters['query'], 'Inception');
      expect(uriWithoutYear.queryParameters.containsKey('primary_release_year'), isFalse);

      final uriWithYear = TmdbEndpoints.searchMovie('Inception', year: 2010);
      expect(uriWithYear.path, '/3/search/movie');
      expect(uriWithYear.queryParameters['query'], 'Inception');
      expect(uriWithYear.queryParameters['primary_release_year'], '2010');
      expect(uriWithYear.queryParameters['api_key'], AppConstants.tmdbApiKey);
    });

    test('Verifies TmdbClient initialization and rate limit callbacks', () {
      bool rateLimitState = false;
      final client = TmdbClient(
        onRateLimitStateChanged: (isPaused, remaining) {
          rateLimitState = isPaused;
        },
      );

      expect(client, isNotNull);
      expect(rateLimitState, isFalse);

      // Verify client getter in TmdbService
      final service = TmdbService(client: client);
      expect(service.client, same(client));

      client.dispose();
      service.dispose();
    });

    test('Verifies TmdbClient 429 retry with Retry-After and rate limit callback', () async {
      int requestCount = 0;
      final List<bool> pauseEvents = [];

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          requestCount++;
          if (requestCount == 1) {
            // First attempt: trigger 429 with Retry-After: 0 (fast test execution)
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 429,
                headers: Headers.fromMap({'retry-after': ['0']}),
              ),
            ));
          } else {
            // Second attempt: success
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'results': [{'id': 123, 'title': 'Test Movie'}]},
            ));
          }
        },
      ));

      final client = TmdbClient(
        dio: dio,
        onRateLimitStateChanged: (isPaused, remaining) {
          pauseEvents.add(isPaused);
        },
      );

      final result = await client.get(Uri.parse('https://api.themoviedb.org/3/test'));
      expect(result['results'], isNotNull);
      expect(result['results'].first['title'], 'Test Movie');
      expect(requestCount, 2);
      expect(pauseEvents, [true, false]);

      client.dispose();
    });

    test('Verifies TmdbClient does not retry 404 or non-429 client errors', () async {
      int requestCount = 0;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          requestCount++;
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 404,
            ),
          ));
        },
      ));

      final client = TmdbClient(dio: dio);
      final result = await client.get(Uri.parse('https://api.themoviedb.org/3/not_found'));

      expect(result, isEmpty);
      // Non-retryable: MUST NOT retry 6 times! Exactly 1 attempt!
      expect(requestCount, 1);

      client.dispose();
    });
  });
}
