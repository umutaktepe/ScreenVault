import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/core/constants/app_constants.dart';
import 'package:screenvault/data/tmdb/tmdb_endpoints.dart';

void main() {
  group('TMDB v3 Endpoints & Configuration Tests', () {
    test('Verifies approved TMDB API v3 Key and Base URL', () {
      expect(AppConstants.tmdbApiKey, isNotEmpty);
      expect(AppConstants.tmdbBaseUrl, 'https://api.themoviedb.org/3');
    });

    test('Verifies TheTVDB bridge endpoint (/find/{id}?external_source=tvdb_id)', () {
      final uri = TmdbEndpoints.findByTvdbId(79168); // Friends TVDB ID
      expect(uri.path, '/3/find/79168');
      expect(uri.queryParameters['api_key'], AppConstants.tmdbApiKey);
      expect(uri.queryParameters['external_source'], 'tvdb_id');
    });

    test('Verifies two-stage show and season endpoints', () {
      final showUri = TmdbEndpoints.tvShowDetails(1668);
      expect(showUri.path, '/3/tv/1668');
      expect(showUri.queryParameters['append_to_response'], 'external_ids,content_ratings');

      final seasonUri = TmdbEndpoints.tvSeasonDetails(1668, 2);
      expect(seasonUri.path, '/3/tv/1668/season/2');
      expect(seasonUri.queryParameters['api_key'], AppConstants.tmdbApiKey);
    });

    test('Verifies Search and Trending endpoints', () {
      final searchUri = TmdbEndpoints.searchMulti('Behzat');
      expect(searchUri.path, '/3/search/multi');
      expect(searchUri.queryParameters['query'], 'Behzat');
      expect(searchUri.queryParameters['language'], 'tr-TR');

      final searchTvUri = TmdbEndpoints.searchTv('Çekiç ve Gül');
      expect(searchTvUri.path, '/3/search/tv');
      expect(searchTvUri.queryParameters['query'], 'Çekiç ve Gül');
      expect(searchTvUri.queryParameters['language'], 'tr-TR');
      expect(searchTvUri.queryParameters.containsKey('first_air_date_year'), isFalse);

      final searchTvWithYearUri = TmdbEndpoints.searchTv('Lost in Space', firstAirDateYear: 2018);
      expect(searchTvWithYearUri.path, '/3/search/tv');
      expect(searchTvWithYearUri.queryParameters['query'], 'Lost in Space');
      expect(searchTvWithYearUri.queryParameters['first_air_date_year'], '2018');

      final trendingUri = TmdbEndpoints.trendingAllDay();
      expect(trendingUri.path, '/3/trending/all/day');
      expect(trendingUri.queryParameters['language'], 'tr-TR');
    });

    test('Verifies TMDB image URL builder', () {
      final poster = TmdbEndpoints.imageUrl('/sample.jpg');
      expect(poster, 'https://image.tmdb.org/t/p/w500/sample.jpg');

      final backdrop = TmdbEndpoints.imageUrl('/backdrop.jpg', size: 'w780');
      expect(backdrop, 'https://image.tmdb.org/t/p/w780/backdrop.jpg');

      expect(TmdbEndpoints.imageUrl(null), '');
      expect(TmdbEndpoints.imageUrl(''), '');
    });
  });
}
