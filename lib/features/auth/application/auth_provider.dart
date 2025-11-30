import 'package:flutter/foundation.dart';
import 'package:flutter/src/material/list_tile.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/models/user.dart';
import '../../../core/services/token_storage_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  when({required StatelessWidget Function(dynamic user) data, required Padding Function() loading, required ListTile Function(dynamic e, dynamic _) error}) {}
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(tokenStorageServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final TokenStorageService _tokenStorage;

  AuthNotifier(this._authRepository, this._tokenStorage)
      : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print("[AuthProvider] Checking auth status...");
    state = state.copyWith(isLoading: true);

    try {
      final token = await _tokenStorage.getToken();

      if (token == null) {
        print("[AuthProvider] No token found, user is logged out.");
        state = const AuthState(user: null, isLoading: false);
        return;
      }

      print("[AuthProvider] Token found, user is authenticated.");

      // TODO: 本来はAPIでトークンの有効性を確認すべき
      // 例: final user = await _authRepository.getMe();
      // 今は簡易的にトークンがあれば認証済みとみなす
      // トークンがある = 認証済みとして扱う
      state = AuthState(
        user: User(
          userId: 'temp_id',
          email: 'temp@example.com',
          nickname: '認証済',
        ),
        isLoading: false,
      );
    } catch (e) {
      print("[AuthProvider] Auth status check failed: $e");
      await _tokenStorage.deleteToken();
      state = const AuthState(user: null, isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    print("[AuthProvider] Attempting login for: $email");
    state = state.copyWith(isLoading: true, error: null);

    try {
      final (user, token) = await _authRepository.login(email, password);
      print("[AuthProvider] Login successful, saving token.");
      await _tokenStorage.saveToken(token);
      print("[AuthProvider] Token saved.");
      state = AuthState(user: user, isLoading: false);
      print("[AuthProvider] Login complete. User: ${user.email}");

    } catch (e) {
      print("[AuthProvider] Login failed: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    print("[AuthProvider] Attempting logout.");
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.logout();
      print("[AuthProvider] Server logout called.");
    } catch (e) {
      print("[AuthProvider] Server logout failed (continuing local logout): $e");
    } finally {
      await _tokenStorage.deleteToken();
      print("[AuthProvider] Local token deleted. User logged out.");
      state = const AuthState(user: null, isLoading: false);
    }
  }

  Future<void> register(String email, String password, String nickname) async {
    print("[AuthProvider] Attempting registration for: $email");
    state = state.copyWith(isLoading: true, error: null);

    try {
      final (user, token) = await _authRepository.register(email, password, nickname);
      print("[AuthProvider] Registration successful, saving token.");
      await _tokenStorage.saveToken(token);
      print("[AuthProvider] Token saved.");
      state = AuthState(user: user, isLoading: false);
      print("[AuthProvider] Registration complete. User: ${user.email}");

    } catch (e) {
      print("[AuthProvider] Registration failed: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> forceLogout() async {
    print("[AuthProvider] Forcing logout due to 401.");
    await _tokenStorage.deleteToken();
    state = const AuthState(user: null, isLoading: false);
    print("[AuthProvider] Force logout complete.");
  }

  Future<void> deleteAccount() async {
    print("[AuthProvider] Attempting account deletion.");

    try {
      await _authRepository.deleteAccount();
      print("[AuthProvider] Server account deletion called.");

      await _tokenStorage.deleteToken();
      print("[AuthProvider] Local token deleted.");

      state = const AuthState(user: null, isLoading: false);
      print("[AuthProvider] Account deletion complete.");

    } catch (e) {
      print("[AuthProvider] Account deletion failed: $e");
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    print("[AuthProvider] Requesting password reset for: $email");

    try {
      await _authRepository.requestPasswordReset(email);
      print("[AuthProvider] Password reset email request successful.");
    } catch (e) {
      print("[AuthProvider] Password reset request failed: $e");
      rethrow;
    }
  }
}