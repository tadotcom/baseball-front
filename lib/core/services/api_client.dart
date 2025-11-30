import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_storage_service.dart';
import '../../main.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';

class ApiConfig {
  static const String baseUrl = 'https://api.ai-next-answer.jp/api/v1';
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(ApiInterceptor(ref));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
    request: true,
    requestHeader: true,
    responseHeader: false,
  ));

  return dio;
});


class ApiInterceptor extends Interceptor {
  final Ref _ref;
  ApiInterceptor(this._ref);
  bool _isForcingLogout = false;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _ref.read(tokenStorageServiceProvider).getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print("[API Client] Added Authorization header");
    }
    print("[API Client] Request: ${options.method} ${options.uri}");
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print("[API Client] Response: ${response.statusCode} ${response.requestOptions.uri}");
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    print("[API Client] Error: ${err.response?.statusCode} ${err.requestOptions.uri}");
    print("[API Client] Error Message: ${err.message}");
    if (err.response?.data != null) {
      print("[API Client] Error Response Data: ${err.response?.data}");
    }

    if (err.response?.statusCode == 401) {
      if (_isForcingLogout) {
        print("[API Client] Already forcing logout, rejecting subsequent 401.");
        return handler.reject(err);
      }
      _isForcingLogout = true;

      print("[API Client] 401 Unauthorized detected. Forcing logout.");

      try {
        await _ref.read(authProvider.notifier).forceLogout();
        print("[API Client] forceLogout completed via provider.");
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          print("[API Client] Navigating to Login Screen...");
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
          print("[API Client] Navigation to Login Screen completed.");
        } else {
          print("[API Client] Error: Navigator context is null or unmounted.");
        }
      } catch (e) {
        print("[API Client] Error during force logout or navigation: $e");
      } finally {
        _isForcingLogout = false;
      }

      return handler.reject(err);
    }

    if (DioExceptionType.connectionError == err.type ||
        DioExceptionType.connectionTimeout == err.type ||
        DioExceptionType.sendTimeout == err.type ||
        DioExceptionType.receiveTimeout == err.type ||
        (DioExceptionType.unknown == err.type && err.error is SocketException)) {
      print("[API Client] Connection error detected.");

      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('通信エラーが発生しました。通信環境の良い場所で再度お試しください。'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
      }

      return handler.next(DioException(
        requestOptions: err.requestOptions,
        error: "接続エラー",
        response: err.response,
        type: err.type,
      ));
    }

    return super.onError(err, handler);
  }
}




























// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'token_storage_service.dart';
// import '../../main.dart'; // Import main.dart for navigatorKey
// // TODO: Import AuthProvider for forceLogout functionality
// import '../../features/auth/application/auth_provider.dart';
// // TODO: Import LoginScreen for navigation
// //import '../../features/auth/presentation/login_screen.dart';
//
//
// // Dio Providerの定義
// final dioProvider = Provider<Dio>((ref) {
//   final dio = Dio(BaseOptions(
//     // TODO: Replace with your actual API base URL from config/env
//     baseUrl: 'https://yourdomain.com/api/v1', //
//     connectTimeout: const Duration(seconds: 15), // Slightly longer timeout
//     receiveTimeout: const Duration(seconds: 15),
//     headers: {
//       'Accept': 'application/json',
//     },
//   ));
//
//   // Add the custom interceptor
//   dio.interceptors.add(ApiInterceptor(ref));
//
//   // Optional: Add logging interceptor for development
//   // if (kDebugMode) {
//   //   dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
//   // }
//
//   return dio;
// });
//
// // Custom Interceptor
// class ApiInterceptor extends Interceptor {
//   final Ref _ref;
//   ApiInterceptor(this._ref);
//
//   // Variable to prevent multiple simultaneous 401 navigations
//   bool _isForcingLogout = false;
//
//   @override
//   Future<void> onRequest(
//       RequestOptions options, RequestInterceptorHandler handler) async {
//     // Retrieve token and add Authorization header
//     final token = await _ref.read(tokenStorageServiceProvider).getToken();
//     if (token != null) {
//       options.headers['Authorization'] = 'Bearer $token';
//     }
//     print("[API Client] Request: ${options.method} ${options.uri}");
//     return super.onRequest(options, handler);
//   }
//
//   @override
//   void onResponse(Response response, ResponseInterceptorHandler handler) {
//     print("[API Client] Response: ${response.statusCode} ${response.requestOptions.uri}");
//     super.onResponse(response, handler);
//   }
//
//   @override
//   Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
//     print("[API Client] Error: ${err.response?.statusCode} ${err.requestOptions.uri}");
//     print("[API Client] Error Message: ${err.message}");
//
//     // --- HTTP 401 Unauthorized Handling ---
//     if (err.response?.statusCode == 401) {
//       // Prevent multiple navigations if multiple requests fail simultaneously
//       if (_isForcingLogout) {
//         print("[API Client] Already forcing logout, rejecting subsequent 401.");
//         return handler.reject(err);
//       }
//       _isForcingLogout = true; // Set flag
//
//       print("[API Client] 401 Unauthorized detected. Forcing logout.");
//
//       try {
//         // Perform force logout via AuthProvider
//         // Ensure provider is accessible (use read for immediate action)
//         await _ref.read(authProvider.notifier).forceLogout();
//         print("[API Client] forceLogout completed via provider.");
//
//         // Navigate to Login Screen using the global key
//         final context = navigatorKey.currentContext;
//         if (context != null && context.mounted) {
//           print("[API Client] Navigating to Login Screen...");
//           // Use pushAndRemoveUntil for clean navigation stack
//           // Navigator.of(context).pushAndRemoveUntil(
//           //     MaterialPageRoute(builder: (_) => const LoginScreen()), // Use actual LoginScreen
//           //         (route) => false // Remove all previous routes
//           // );
//           print("[API Client] Navigation to Login Screen attempted.");
//         } else {
//           print("[API Client] Error: Navigator context is null or unmounted. Cannot navigate to login.");
//         }
//       } catch (e) {
//         print("[API Client] Error during force logout or navigation: $e");
//         // Handle potential errors during logout itself
//       } finally {
//         _isForcingLogout = false; // Reset flag
//       }
//
//       // Reject the original error after handling
//       return handler.reject(err);
//     }
//
//     // --- Offline/Connection Error Handling ---
//     if (DioExceptionType.connectionError == err.type ||
//         DioExceptionType.connectionTimeout == err.type ||
//         DioExceptionType.sendTimeout == err.type ||
//         DioExceptionType.receiveTimeout == err.type ||
//         // Sometimes SocketException falls under 'other'
//         (DioExceptionType.unknown == err.type && err.error is SocketException)
//     ) {
//
//       print("[API Client] Connection error detected.");
//       // Show a generic offline message SnackBar
//       final context = navigatorKey.currentContext;
//       if (context != null && context.mounted) {
//         // Ensure SnackBar is shown safely after build phases complete
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           ScaffoldMessenger.maybeOf(context)?.showSnackBar(
//             const SnackBar(
//               content: Text('通信エラーが発生しました。通信環境の良い場所で再度お試しください。'),
//               duration: Duration(seconds: 4), // Slightly longer duration
//               backgroundColor: Colors.redAccent,
//             ),
//           );
//         });
//       } else {
//         print("[API Client] Error: Navigator context is null or unmounted. Cannot show connection error SnackBar.");
//       }
//       // Pass the error along, potentially transformed
//       return handler.next(DioException(
//         requestOptions: err.requestOptions,
//         error: "接続エラー", // User-friendly error type?
//         response: err.response,
//         type: err.type,
//       ));
//     }
//
//     // Handle other specific HTTP errors if needed
//     // if (err.response?.statusCode == 403) { ... }
//     // if (err.response?.statusCode == 404) { ... }
//     // if (err.response?.statusCode == 422) { ... } // Validation errors usually handled by provider/UI
//
//     // For all other errors, pass them along
//     return super.onError(err, handler);
//   }
// }
//
// // Helper extension for SocketException check if needed
// extension DioErrorX on DioException {
//   bool get isSocketException => type == DioExceptionType.unknown && error is SocketException;
// }