import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/api_client.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CheckinRepositoryImpl(dio);
});

abstract class CheckinRepository {
  Future<void> performCheckin(String gameId);
}

class CheckinRepositoryImpl implements CheckinRepository {
  final Dio _dio;

  CheckinRepositoryImpl(this._dio);

  @override
  Future<void> performCheckin(String gameId) async {
    print("[CheckinRepository] Starting check-in process for game: $gameId");
    Position currentPosition;
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("[CheckinRepository] Location service disabled.");
        throw Exception('E-GPS-DISABLED: 位置情報サービス（GPS）がオフになっています。オンにしてください。');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print("[CheckinRepository] Location permission denied. Requesting...");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("[CheckinRepository] Location permission denied after request.");
          throw Exception('E-PERM-DENIED: 位置情報の利用が許可されていません。'); // Custom error message
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("[CheckinRepository] Location permission denied forever.");
        throw Exception('E-PERM-DENIED-FOREVER: 位置情報が永続的に拒否されています。設定アプリから許可してください。');
      }

      print("[CheckinRepository] Getting current position (High Accuracy)...");
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      print("[CheckinRepository] Position obtained: ${currentPosition.latitude}, ${currentPosition.longitude}");

    } on TimeoutException catch (e) {
      print("[CheckinRepository] Location timeout: $e");
      throw Exception('E-LOC-TIMEOUT: 位置情報の取得にタイムアウトしました。電波の良い場所で再度お試しください。');
    } catch (e) {
      print("[CheckinRepository] Error getting location: $e");
      throw Exception('位置情報の取得に失敗しました: ${e.toString()}');
    }

    try {
      print("[CheckinRepository] Calling check-in API for game $gameId");
      final response = await _dio.post(
        '/games/$gameId/checkin',
        data: {
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
        },
      );

      if (response.statusCode == 200) {
        print("[CheckinRepository] Check-in API call successful.");
        return;
      } else {
        print("[CheckinRepository] Check-in API returned unexpected status: ${response.statusCode}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: "Check-in failed with status ${response.statusCode}",
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[CheckinRepository] Check-in API DioException: ${e.response?.statusCode} - ${e.message}");
      final errorMessage = e.response?.data?['error']?['message'] ?? 'チェックイン処理に失敗しました。';
      final errorCode = e.response?.data?['error']?['code'] ?? 'Unknown API Error';
      print("[CheckinRepository] API Error Code: $errorCode, Message: $errorMessage");
      throw Exception("$errorCode: $errorMessage");
    } catch (e) {
      print("[CheckinRepository] Check-in unexpected error during API call: $e");
      throw Exception("チェックイン中に予期せぬエラーが発生しました。");
    }
  }
}