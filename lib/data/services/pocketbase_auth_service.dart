import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../../core/network/pocketbase_client.dart';

/// Service managing PocketBase user authentication, profile, and registration
class PocketBaseAuthService {
  static final PocketBaseAuthService _instance = PocketBaseAuthService._internal();
  factory PocketBaseAuthService() => _instance;
  PocketBaseAuthService._internal();

  final PocketBaseClient _client = PocketBaseClient();
  PocketBase get _pb => _client.pb;

  bool get isLoggedIn => _client.isAuthenticated;
  RecordModel? get currentUser => _client.currentUser;
  String get userEmail => currentUser?.getStringValue('email') ?? '';
  String get userName {
    final name = currentUser?.getStringValue('name');
    if (name != null && name.isNotEmpty) return name;
    final email = userEmail;
    if (email.contains('@')) return email.split('@').first;
    return 'Kullanıcı';
  }

  String? get avatarUrl {
    final record = currentUser;
    if (record == null) return null;
    final avatar = record.getStringValue('avatar');
    if (avatar.isEmpty) return null;
    return '${_client.serverUrl}/api/files/${record.collectionId}/${record.id}/$avatar';
  }

  Stream<AuthStoreEvent> get authStateStream => _client.authStateStream;

  /// Signs in using email/username and password
  Future<RecordAuth> login({
    required String email,
    required String password,
  }) async {
    try {
      final authData = await _pb.collection('users').authWithPassword(email.trim(), password);
      debugPrint('[Auth] Logged in successfully: ${authData.record.id}');
      return authData;
    } catch (e) {
      debugPrint('[Auth] Login error: $e');
      rethrow;
    }
  }

  /// Registers a new user and signs in immediately
  Future<RecordAuth> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'passwordConfirm': password,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      };

      await _pb.collection('users').create(body: body);
      debugPrint('[Auth] Registered successfully, now signing in...');

      return await login(email: email, password: password);
    } catch (e) {
      debugPrint('[Auth] Registration error: $e');
      rethrow;
    }
  }

  /// Logs out and clears the local auth token
  void logout() {
    _pb.authStore.clear();
    debugPrint('[Auth] Logged out');
  }

  /// Updates user profile name and/or avatar image
  Future<RecordModel> updateProfile({
    String? name,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Oturum açılmamış.');
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();

    final files = <http.MultipartFile>[];
    if (avatarBytes != null && avatarFileName != null) {
      files.add(http.MultipartFile.fromBytes(
        'avatar',
        avatarBytes,
        filename: avatarFileName,
      ));
    }

    final updated = await _pb.collection('users').update(
      user.id,
      body: body,
      files: files,
    );

    // Refresh auth store with the updated record
    _pb.authStore.save(_pb.authStore.token, updated);
    return updated;
  }
}
