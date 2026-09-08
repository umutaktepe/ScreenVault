import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../../core/network/pocketbase_client.dart';
import '../database/database_service.dart';
import '../sync/pocketbase_sync_engine.dart';

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
      // Clear previous local active user data before logging in
      await DatabaseService().clearActiveUserData();

      final authData = await _pb.collection('users').authWithPassword(email.trim(), password);
      debugPrint('[Auth] Logged in successfully: ${authData.record.id}');

      // Ensure clean state before fresh sync
      await DatabaseService().clearActiveUserData();
      await PocketBaseSyncEngine().syncAll();

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
      // Clear any leftover local data before account creation to guarantee zero-contamination
      await DatabaseService().clearActiveUserData();

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

  /// Verifies current user's password against PocketBase.
  /// Returns null if verified successfully, or a descriptive error message string if failed.
  Future<String?> verifyPasswordDetailed(String password) async {
    if (!isLoggedIn) {
      return 'Oturum açık değil.';
    }

    String identifier = userEmail.trim();
    if (identifier.isEmpty) {
      final user = currentUser;
      if (user != null) {
        identifier = user.getStringValue('username').trim();
      }
    }

    if (identifier.isEmpty) {
      try {
        final refreshed = await _pb.collection('users').authRefresh();
        identifier = refreshed.record.getStringValue('email').trim();
        if (identifier.isEmpty) {
          identifier = refreshed.record.getStringValue('username').trim();
        }
      } catch (_) {}
    }

    if (identifier.isEmpty) {
      return 'Kullanıcı hesabı tespit edilemedi. Onaylamak için lütfen "SIFIRLA" yazın.';
    }

    try {
      // Use an isolated PocketBase instance without existing Authorization headers
      final isolatedPb = PocketBase(
        _client.serverUrl,
        httpClientFactory: () => NgrokHttpClient(),
      );

      await isolatedPb
          .collection('users')
          .authWithPassword(identifier, password)
          .timeout(const Duration(seconds: 8));
      return null; // Null means verification succeeded
    } on TimeoutException {
      return 'Sunucu yanıt vermedi (Zaman aşımı). Bilgisayarınız ve telefonunuzun aynı Wi-Fi ağında olduğundan ve PocketBase\'in açık olduğundan emin olun. (Acil durum için "SIFIRLA" yazabilirsiniz)';
    } on ClientException catch (e) {
      debugPrint('[Auth] Password verification ClientException: ${e.statusCode} ${e.response}');
      if (e.statusCode == 400) {
        return 'Girdiğiniz şifre hatalı. Lütfen tekrar deneyin.';
      } else if (e.statusCode == 429) {
        return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyin veya "SIFIRLA" yazarak sıfırlayın.';
      } else if (e.statusCode == 0) {
        return 'PocketBase sunucusuna ulaşılamadı. Sunucunuzun açık olduğundan ve aynı Wi-Fi ağına bağlı olduğunuzdan emin olun. (Acil durum için "SIFIRLA" yazabilirsiniz)';
      } else {
        final msg = e.response['message'] ?? 'Doğrulanamadı';
        return 'Sunucu hatası (${e.statusCode}): $msg';
      }
    } catch (e) {
      debugPrint('[Auth] Password verification network error: $e');
      return 'Sunucuya bağlanılamadı. (Acil durum için "SIFIRLA" yazabilirsiniz)';
    }
  }

  /// Verifies current user's password against PocketBase (backward compatible boolean)
  Future<bool> verifyPassword(String password) async {
    final err = await verifyPasswordDetailed(password);
    return err == null;
  }

  /// Logs out, wipes local active user data, and clears the local auth token
  Future<void> logout() async {
    await DatabaseService().clearActiveUserData();
    _pb.authStore.clear();
    debugPrint('[Auth] Logged out and active user data cleared');
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
