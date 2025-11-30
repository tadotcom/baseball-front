import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepositoryImpl(dio);
});

abstract class AuthRepository {
  Future<(User, String)> login(String email, String password);
  Future<(User, String)> register(String email, String password, String nickname);
  Future<void> logout();
  Future<void> deleteAccount();
  Future<void> requestPasswordReset(String email);
}

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;

  AuthRepositoryImpl(this._dio);

  @override
  Future<(User, String)> login(String email, String password) async {
    try {
      print("[AuthRepository] Attempting login via API for $email");
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null && responseData['user'] != null && responseData['token'] != null) {
          final user = User.fromJson(responseData['user'] as Map<String, dynamic>);
          final token = responseData['token'] as String;
          print("[AuthRepository] Login API success. Token received.");
          return (user, token);
        } else {
          print("[AuthRepository] Login API error: Invalid response structure.");
          throw Exception('Login failed: Invalid response structure from server.');
        }
      } else {
        print("[AuthRepository] Login API error: Status code ${response.statusCode}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: "Login failed with status ${response.statusCode}",
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[AuthRepository] Login API DioException: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.statusCode == 401) {
        throw Exception(e.response?.data?['error']?['message'] ?? 'E-401-02: メールアドレスまたはパスワードが正しくありません');
      }
      if (e.response?.statusCode == 422) {
        final details = e.response?.data?['error']?['details'] as List?;
        final firstError = details?.isNotEmpty ?? false ? details!.first['message'] : '入力内容を確認してください';
        throw Exception(e.response?.data?['error']?['message'] ?? firstError);
      }
      throw Exception("Login failed: ${e.message ?? 'Unknown API error'}");
    } catch (e) {
      print("[AuthRepository] Login unexpected error: $e");
      throw Exception("Login failed: An unexpected error occurred.");
    }
  }

  @override
  Future<(User, String)> register(String email, String password, String nickname) async {
    try {
      print("[AuthRepository] Attempting registration via API for $email");
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'password_confirmation': password,
          'nickname': nickname,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null && responseData['user'] != null && responseData['token'] != null) {
          final user = User.fromJson(responseData['user'] as Map<String, dynamic>);
          final token = responseData['token'] as String;
          print("[AuthRepository] Registration API success. Token received.");
          return (user, token);
        } else {
          print("[AuthRepository] Registration API error: Invalid response structure.");
          throw Exception('Registration failed: Invalid response structure.');
        }
      } else {
        print("[AuthRepository] Registration API error: Status code ${response.statusCode}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: "Registration failed with status ${response.statusCode}",
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[AuthRepository] Registration API DioException: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.statusCode == 409 || e.response?.statusCode == 422) {
        final errorCode = e.response?.data?['error']?['code'] ?? 'Unknown Error';
        final errorMessage = e.response?.data?['error']?['message'] ?? '登録に失敗しました。入力内容を確認してください。';
        final details = e.response?.data?['error']?['details'] as List?;
        final firstDetail = details?.isNotEmpty ?? false ? details!.first['message'] : null;
        throw Exception("$errorCode: ${firstDetail ?? errorMessage}"); // Return specific error message
      }
      throw Exception("Registration failed: ${e.message ?? 'Unknown API error'}");
    } catch (e) {
      print("[AuthRepository] Registration unexpected error: $e");
      throw Exception("Registration failed: An unexpected error occurred.");
    }
  }

  @override
  Future<void> logout() async {
    try {
      print("[AuthRepository] Calling logout API endpoint...");
      await _dio.post('/auth/logout');
      print("[AuthRepository] Logout API call successful.");
    } on DioException catch (e) {
      print("[AuthRepository] Logout API failed (non-critical): ${e.message}");
    } catch (e) {
      print("[AuthRepository] Logout unexpected error (non-critical): $e");
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      print("[AuthRepository] Calling delete account API endpoint...");
      final response = await _dio.delete('/auth/me');

      if (response.statusCode != 204) {
        throw Exception("Account deletion failed with status ${response.statusCode}");
      }
      print("[AuthRepository] Delete account API call successful.");

    } on DioException catch (e) {
      print("[AuthRepository] Account deletion API DioException: ${e.message}");
      throw Exception("Account deletion failed: ${e.message ?? 'Unknown API error'}");
    } catch (e) {
      print("[AuthRepository] Account deletion unexpected error: $e");
      throw Exception("Account deletion failed: An unexpected error occurred.");
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      print("[AuthRepository] Calling password reset API endpoint for $email");
      final response = await _dio.post(
        '/auth/password/reset',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
      throw Exception("Password reset request failed with status ${response.statusCode}");
      }
      print("[AuthRepository] Password reset request successful.");

    } on DioException catch (e) {
      print("[AuthRepository] Password reset API DioException: ${e.message}");
      if (e.response?.statusCode == 404) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'E-404-01: ユーザーが見つかりません');
      }
      throw Exception("Password reset failed: ${e.message ?? 'Unknown API error'}");
    } catch (e) {
      print("[AuthRepository] Password reset unexpected error: $e");
      throw Exception("Password reset failed: An unexpected error occurred.");
    }
  }
}