import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DeviceTokenRepositoryImpl(dio);
});

abstract class DeviceTokenRepository {
  Future<void> registerToken({required String token, required String deviceType});
}

class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  final Dio _dio;

  DeviceTokenRepositoryImpl(this._dio);

  @override
  Future<void> registerToken({required String token, required String deviceType}) async {
    try {
      print("[DeviceTokenRepository] Registering device token to backend...");
      final response = await _dio.post(
        '/device-tokens',
        data: {
          'token': token,
          'device_type': deviceType,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("[DeviceTokenRepository] Device token registration successful.");
        return;
      } else {
        print("[DeviceTokenRepository] Device token API returned unexpected status: ${response.statusCode}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: "Device token registration failed with status ${response.statusCode}",
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[DeviceTokenRepository] Device token API DioException: ${e.response?.statusCode} - ${e.message}");
      print("[DeviceTokenRepository] Error details: ${e.response?.data}");
    } catch (e) {
      print("[DeviceTokenRepository] Device token registration unexpected error: $e");
    }
  }
}





























// import 'package:dio/dio.dart'; // For API client and exceptions
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../core/services/api_client.dart'; // Import Dio provider
//
// // Device Token Repository Provider
// final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
//   final dio = ref.watch(dioProvider); // Get Dio instance
//   return DeviceTokenRepositoryImpl(dio);
// });
//
// // Device Token Repository Interface
// abstract class DeviceTokenRepository {
//   /// Registers the device token with the backend server.
//   /// Called by FcmService.
//   Future<void> registerToken({required String token, required String deviceType});
// }
//
// // Implementation using Dio
// class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
//   final Dio _dio;
//
//   DeviceTokenRepositoryImpl(this._dio);
//
//   @override
//   Future<void> registerToken({required String token, required String deviceType}) async {
//     try {
//       print("[DeviceTokenRepository] Registering device token to backend...");
//       final response = await _dio.post(
//         '/device-tokens', // API Endpoint
//         data: {
//           'token': token,
//           'device_type': deviceType, // 'ios' or 'android'
//         },
//       );
//
//       // Expect 200 or 201 for successful registration/update
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print("[DeviceTokenRepository] Device token registration successful.");
//         // No specific data needed from response based on API design
//         return;
//       } else {
//         // Should be caught by DioException, but handle unexpected success codes
//         print("[DeviceTokenRepository] Device token API returned unexpected status: ${response.statusCode}");
//         throw DioException(
//           requestOptions: response.requestOptions,
//           response: response,
//           error: "Device token registration failed with status ${response.statusCode}",
//           type: DioExceptionType.badResponse,
//         );
//       }
//     } on DioException catch (e) {
//       // Log the error but typically don't throw an exception that stops app flow,
//       // as failing to register the token usually just means notifications won't work.
//       print("[DeviceTokenRepository] Device token API DioException: ${e.response?.statusCode} - ${e.message}");
//       print("[DeviceTokenRepository] Error details: ${e.response?.data}");
//       // Optionally log to a monitoring service
//     } catch (e) {
//       print("[DeviceTokenRepository] Device token registration unexpected error: $e");
//       // Log the error
//     }
//   }
// }