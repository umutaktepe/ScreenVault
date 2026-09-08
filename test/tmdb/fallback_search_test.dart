import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/tmdb/tmdb_client.dart';
import 'package:screenvault/data/tmdb/tmdb_service.dart';

void main() {
  group('TMDB 4-Stage Fallback Search Tests', () {
    test('Stage 1: Matches TV show directly by raw title when year is aligned or null', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/search/tv')) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'results': [
                  {
                    'id': 100,
                    'name': 'Dark',
                    'first_air_date': '2017-12-01',
                    'overview': 'A missing child sets four families on a frantic hunt.',
                  }
                ]
              },
            ));
          } else {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {}));
          }
        },
      ));

      final client = TmdbClient(dio: dio);
      final service = TmdbService(client: client);

      final result = await service.searchTvShowWithFallback('Dark', targetYear: 2017);
      expect(result, isNotNull);
      expect(result!.id, 100);
      expect(result.name, 'Dark');

      client.dispose();
      service.dispose();
    });

    test('Stage 2: Cleans bracketed year and searches with first_air_date_year', () async {
      final requestedPaths = <String>[];
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUri = options.uri.toString();
          requestedPaths.add(fullUri);

          if (fullUri.contains('query=Lost+in+Space+%282018%29') || fullUri.contains('query=Lost+in+Space+(2018)')) {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'results': []}));
          } else if (fullUri.contains('first_air_date_year=2018')) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'results': [
                  {
                    'id': 200,
                    'name': 'Lost in Space',
                    'first_air_date': '2018-04-13',
                  }
                ]
              },
            ));
          } else {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'results': []}));
          }
        },
      ));

      final client = TmdbClient(dio: dio);
      final service = TmdbService(client: client);

      final result = await service.searchTvShowWithFallback('Lost in Space (2018)');
      expect(result, isNotNull);
      expect(result!.id, 200);
      expect(result.name, 'Lost in Space');
      expect(requestedPaths.any((p) => p.contains('first_air_date_year=2018')), isTrue);

      client.dispose();
      service.dispose();
    });

    test('Stage 3: Matches candidate within ±1 year tolerance when exact year query yielded nothing', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUri = options.uri.toString();

          if (fullUri.contains('first_air_date_year=2018')) {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'results': []}));
          } else if (fullUri.contains('/search/tv') && !fullUri.contains('first_air_date_year')) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'results': [
                  {
                    'id': 301,
                    'name': 'Unorthodox Series',
                    'first_air_date': '2017-09-15',
                  }
                ]
              },
            ));
          } else {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'results': []}));
          }
        },
      ));

      final client = TmdbClient(dio: dio);
      final service = TmdbService(client: client);

      final result = await service.searchTvShowWithFallback('Unorthodox Series', targetYear: 2018);
      expect(result, isNotNull);
      expect(result!.id, 301);
      expect(result.firstAirDate?.year, 2017);

      client.dispose();
      service.dispose();
    });

    test('Stage 3 does NOT return a candidate when year differs by more than 1 year', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUri = options.uri.toString();

          if (fullUri.contains('/search/tv')) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'results': [
                  {
                    'id': 999,
                    'name': 'The Flash',
                    'first_air_date': '2014-10-07',
                  }
                ]
              },
            ));
          } else {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'results': []}));
          }
        },
      ));

      final client = TmdbClient(dio: dio);
      final service = TmdbService(client: client);

      final result = await service.searchTvShowWithFallback('The Flash', targetYear: 1990);
      expect(result, isNull);

      client.dispose();
      service.dispose();
    });

    test('Stage 4: MultiSearch fallback finds media when TV search fails', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUri = options.uri.toString();

          if (fullUri.contains('/search/multi')) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'results': [
                  {
                    'id': 404,
                    'media_type': 'tv',
                    'name': 'Special Mini-Series',
                    'first_air_date': '2020-05-01',
                  }
                ]
              },
            ));
          } else {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'results': []}));
          }
        },
      ));

      final client = TmdbClient(dio: dio);
      final service = TmdbService(client: client);

      final result = await service.searchTvShowWithFallback('Special Mini-Series', targetYear: 2020);
      expect(result, isNotNull);
      expect(result!.id, 404);
      expect(result.name, 'Special Mini-Series');

      client.dispose();
      service.dispose();
    });

    test('Movie fallback parses title year and matches primary_release_year', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUri = options.uri.toString();

          if (fullUri.contains('primary_release_year=2021')) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'results': [
                  {
                    'id': 438631,
                    'title': 'Dune',
                    'release_date': '2021-09-15',
                    'runtime': 155,
                  }
                ]
              },
            ));
          } else {
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'results': []}));
          }
        },
      ));

      final client = TmdbClient(dio: dio);
      final service = TmdbService(client: client);

      final result = await service.searchMovieWithFallback('Dune (2021)');
      expect(result, isNotNull);
      expect(result!.id, 438631);
      expect(result.title, 'Dune');

      client.dispose();
      service.dispose();
    });
  });
}
