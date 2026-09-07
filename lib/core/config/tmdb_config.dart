import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../data/tmdb/tmdb_endpoints.dart';

/// Central manager for TMDB API key configuration, persistence and validation.
class TmdbConfig {
  static final TmdbConfig _instance = TmdbConfig._internal();
  factory TmdbConfig() => _instance;
  TmdbConfig._internal();

  static const String _prefKeyTmdbKey = 'tmdb_api_key';

  String _currentApiKey = '';
  bool _isInitialized = false;

  String get apiKey => _currentApiKey;
  bool get hasValidKey => _currentApiKey.isNotEmpty && _currentApiKey != 'YOUR_TMDB_API_KEY_HERE';

  /// Initializes TMDB API key from SharedPreferences or environment variable
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_prefKeyTmdbKey)?.trim();

    if (savedKey != null && savedKey.isNotEmpty && savedKey != 'YOUR_TMDB_API_KEY_HERE') {
      _currentApiKey = savedKey;
    } else {
      final key = AppConstants.tmdbApiKey.trim();
      _currentApiKey = key;
      await prefs.setString(_prefKeyTmdbKey, key);
    }

    if (_currentApiKey.isNotEmpty) {
      TmdbEndpoints.setApiKey(_currentApiKey);
    }
    _isInitialized = true;
  }

  /// Updates API key, persists to SharedPreferences, and updates TmdbEndpoints
  Future<bool> updateApiKey(String newKey) async {
    final cleanKey = newKey.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyTmdbKey, cleanKey);
    _currentApiKey = cleanKey;
    TmdbEndpoints.setApiKey(cleanKey);

    return await testApiKey(cleanKey);
  }

  /// Tests if the provided API key can successfully authenticate with TMDB v3
  Future<bool> testApiKey(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty || cleanKey == 'YOUR_TMDB_API_KEY_HERE') return false;

    try {
      final uri = Uri.parse('${AppConstants.tmdbBaseUrl}/configuration?api_key=$cleanKey');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('images')) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
