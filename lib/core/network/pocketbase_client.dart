import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_service.dart';

/// Custom HTTP Client that attaches the ngrok-skip-browser-warning header
/// so that mobile requests directly hit PocketBase without getting blocked by Ngrok interstitial.
class NgrokHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['ngrok-skip-browser-warning'] = 'true';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Singleton manager for the PocketBase connection, authentication store,
/// and dynamic server URL persistence.
class PocketBaseClient {
  static final PocketBaseClient _instance = PocketBaseClient._internal();
  factory PocketBaseClient() => _instance;
  PocketBaseClient._internal() {
    _initPocketBaseInstance();
  }

  // Default local network PocketBase address
  static const String defaultPocketBaseUrl = 'http://192.168.1.108:8090';

  static String get _defaultUrl {
    const fromEnv = String.fromEnvironment('POCKETBASE_URL');
    if (fromEnv.isNotEmpty && fromEnv != 'http://127.0.0.1:8090') {
      return fromEnv;
    }
    return defaultPocketBaseUrl;
  }

  static const String _prefKeyUrl = 'pocketbase_server_url';
  static const String _prefKeyToken = 'pocketbase_auth_token';
  static const String _prefKeyRecord = 'pocketbase_auth_record';

  late PocketBase _pb;
  String _currentUrl = _defaultUrl;
  bool _isInitialized = false;

  final _authStateController = StreamController<AuthStoreEvent>.broadcast();
  StreamSubscription<AuthStoreEvent>? _authStoreSubscription;

  PocketBase get pb => _pb;
  String get serverUrl => _currentUrl;
  bool get isAuthenticated => _pb.authStore.isValid;
  RecordModel? get currentUser => _pb.authStore.record;
  Stream<AuthStoreEvent> get authStateStream => _authStateController.stream;

  /// Initializes the PocketBase client, restoring saved server URL and auth tokens.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_prefKeyUrl)?.trim();
    if (savedUrl != null &&
        savedUrl.isNotEmpty &&
        savedUrl != 'http://127.0.0.1:8090' &&
        !savedUrl.contains('ngrok')) {
      _currentUrl = savedUrl;
    } else {
      _currentUrl = _defaultUrl;
      await prefs.setString(_prefKeyUrl, _currentUrl);
    }

    _initPocketBaseInstance();

    // Restore saved auth session
    final savedToken = prefs.getString(_prefKeyToken);
    final savedRecordJson = prefs.getString(_prefKeyRecord);
    if (savedToken != null && savedToken.isNotEmpty) {
      try {
        RecordModel? record;
        if (savedRecordJson != null && savedRecordJson.isNotEmpty) {
          final map = jsonDecode(savedRecordJson) as Map<String, dynamic>;
          record = RecordModel.fromJson(map);
        }
        _pb.authStore.save(savedToken, record);

        // Background refresh if token is still valid
        if (_pb.authStore.isValid) {
          _refreshAuthSilently();
        } else {
          debugPrint('[PocketBase] Saved token is expired. Clearing auth and local data.');
          _pb.authStore.clear();
          await DatabaseService().clearActiveUserData();
        }
      } catch (e) {
        debugPrint('[PocketBase] Failed to restore auth state: $e');
        _pb.authStore.clear();
        await DatabaseService().clearActiveUserData();
      }
    } else {
      final history = DatabaseService().getAllWatchRecords();
      if (history.isNotEmpty) {
        debugPrint('[PocketBase] Unauthenticated startup with lingering records. Clearing active user data.');
        await DatabaseService().clearActiveUserData();
      }
    }

    // Auto persist auth state on change via persistent controller stream
    _authStateController.stream.listen((event) async {
      final p = await SharedPreferences.getInstance();
      if (event.token.isNotEmpty) {
        await p.setString(_prefKeyToken, event.token);
        if (event.record != null) {
          await p.setString(_prefKeyRecord, jsonEncode(event.record!.toJson()));
        } else {
          await p.remove(_prefKeyRecord);
        }
      } else {
        await p.remove(_prefKeyToken);
        await p.remove(_prefKeyRecord);
      }
    });

    _isInitialized = true;
    debugPrint('[PocketBase] Initialized with URL: $_currentUrl');
  }

  void _initPocketBaseInstance() {
    _authStoreSubscription?.cancel();
    _pb = PocketBase(
      _currentUrl,
      httpClientFactory: () => NgrokHttpClient(),
    );
    _authStoreSubscription = _pb.authStore.onChange.listen((event) {
      _authStateController.add(event);
    });
  }

  /// Updates the server URL, saves it to storage, and reinitializes the client.
  Future<bool> updateServerUrl(String newUrl) async {
    String formatted = newUrl.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }
    while (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    _currentUrl = formatted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUrl, _currentUrl);

    final savedToken = _pb.authStore.token;
    final savedRecord = _pb.authStore.record;

    _initPocketBaseInstance();

    if (savedToken.isNotEmpty) {
      _pb.authStore.save(savedToken, savedRecord);
    }

    return checkHealth();
  }

  /// Checks health of an arbitrary URL without affecting current active server URL
  Future<bool> checkUrlHealth(String url) async {
    String formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }
    while (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    try {
      final testPb = PocketBase(
        formatted,
        httpClientFactory: () => NgrokHttpClient(),
      );
      final health = await testPb.health.check().timeout(const Duration(seconds: 5));
      return health.code == 200;
    } catch (e) {
      debugPrint('[PocketBase] checkUrlHealth ($formatted) failed: $e');
      return false;
    }
  }

  /// Pings the server /api/health endpoint to test connectivity.
  Future<bool> checkHealth() async {
    try {
      final health = await _pb.health.check().timeout(const Duration(seconds: 5));
      return health.code == 200;
    } catch (e) {
      debugPrint('[PocketBase] Health check failed: $e');
      return false;
    }
  }

  Future<void> _refreshAuthSilently() async {
    try {
      await _pb.collection('users').authRefresh();
      debugPrint('[PocketBase] Auth session refreshed successfully');
    } catch (e) {
      debugPrint('[PocketBase] Auth refresh skipped/failed: $e');
      if (e is ClientException && (e.statusCode == 401 || e.statusCode == 404)) {
        debugPrint('[PocketBase] User was deleted or session is invalid on server. Clearing local auth.');
        _pb.authStore.clear();
        await DatabaseService().clearActiveUserData();
      }
    }
  }
}
