import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService(FlutterSecureStorage(/*aOptions: _getAndroidOptions()*/));
});

class TokenStorageService {
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';
  TokenStorageService(this._storage);

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      print("[TokenStorage] Token saved successfully.");
    } catch (e) {
      print("[TokenStorage] Error saving token: $e");
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token;
    } catch (e) {
      print("[TokenStorage] Error reading token: $e");
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      print("[TokenStorage] Token deleted successfully.");
    } catch (e) {
      print("[TokenStorage] Error deleting token: $e");
    }
  }
}