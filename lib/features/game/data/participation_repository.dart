import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/participation.dart'; // TODO: Create Participation model
import '../../../core/services/api_client.dart';

final participationRepositoryProvider = Provider<ParticipationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ParticipationRepositoryImpl(dio);
});

abstract class ParticipationRepository {
  Future<Participation> registerForGame({
    required String gameId,
    required String teamDivision,
    required String position,
  });

// TODO: Add methods to get participations for a game or user if needed
}

class ParticipationRepositoryImpl implements ParticipationRepository {
  final Dio _dio;

  ParticipationRepositoryImpl(this._dio);

  @override
  Future<Participation> registerForGame({
    required String gameId,
    required String teamDivision,
    required String position,
  }) async {
    try {
      print("[ParticipationRepository] Registering participation for game $gameId");
      final response = await _dio.post(
        '/games/$gameId/participations',
        data: {
          'team_division': teamDivision,
          'position': position,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null) {
          // TODO: Implement Participation.fromJson
          final participation = Participation.fromJson(responseData as Map<String, dynamic>);
          print("[ParticipationRepository] Participation successful: ID ${participation.participationId}");
          return participation;
        } else {
          print("[ParticipationRepository] Participation API error: Invalid response structure ('data' missing).");
          throw Exception('参加登録に失敗しました: 無効なレスポンス');
        }
      } else {
        print("[ParticipationRepository] Participation API error: Status code ${response.statusCode}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: "参加登録失敗 ステータス ${response.statusCode}",
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[ParticipationRepository] Participation API DioException: ${e.response?.statusCode} - ${e.message}");
      final errorMessage = e.response?.data?['error']?['message'] ?? '参加登録処理に失敗しました。';
      final errorCode = e.response?.data?['error']?['code'] ?? 'Unknown';
      print("[ParticipationRepository] API Error Code: $errorCode, Message: $errorMessage");
      throw Exception("$errorCode: $errorMessage"); // Throw specific error message
    } catch (e) {
      print("[ParticipationRepository] Participation unexpected error: $e");
      throw Exception("参加登録中に予期せぬエラーが発生しました。");
    }
  }
}