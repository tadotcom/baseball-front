import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/game.dart';
import '../../../core/services/api_client.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GameRepositoryImpl(dio);
});

abstract class GameRepository {
  Future<({List<Game> games, bool hasMore})> fetchGameList({
    int page = 1,
    int perPage = 20, //
    String? prefecture,
    String? dateFrom,
    String? dateTo,
  });

  Future<Game> fetchGameDetail(String gameId);
// TODO: Add methods for admin functions if needed (create, update, delete)
}

class GameRepositoryImpl implements GameRepository {
  final Dio _dio;

  GameRepositoryImpl(this._dio);

  @override
  Future<({List<Game> games, bool hasMore})> fetchGameList({
    int page = 1,
    int perPage = 20,
    String? prefecture,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      print("[GameRepository] Fetching game list page $page. Filters: pref=$prefecture, from=$dateFrom, to=$dateTo");
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (prefecture != null && prefecture.isNotEmpty) {
        queryParameters['prefecture'] = prefecture;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParameters['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParameters['date_to'] = dateTo;
      }

      final response = await _dio.get(
        '/games',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'] as List?;
        final meta = response.data['meta'];

        if (responseData != null && meta != null) {
          final games = responseData
              .map((gameJson) => Game.fromJson(gameJson as Map<String, dynamic>))
              .toList();
          final currentPage = meta['current_page'] as int? ?? 1;
          final lastPage = meta['last_page'] as int? ?? 1;
          final bool hasMore = currentPage < lastPage;

          print("[GameRepository] Fetched ${games.length} games for page $page. HasMore: $hasMore");
          return (games: games, hasMore: hasMore);
        } else {
          print("[GameRepository] Game list API error: Invalid response structure (data or meta missing).");
          throw Exception('試合リストの取得に失敗しました: 無効なレスポンス');
        }
      } else {
        print("[GameRepository] Game list API error: Status code ${response.statusCode}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: "試合リストの取得失敗 ステータス ${response.statusCode}",
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[GameRepository] Game list API DioException: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.data?['error']?['code'] == 'E-400-03') {
        throw Exception('E-400-03: 日付の形式が正しくありません。YYYY-MM-DD形式で指定してください。');
      }
      throw Exception("試合リストの取得に失敗しました: ${e.message ?? 'APIエラー'}");
    } catch (e) {
      print("[GameRepository] Game list unexpected error: $e");
      throw Exception("試合リストの取得中に予期せぬエラーが発生しました。");
    }
  }

  @override
  Future<Game> fetchGameDetail(String gameId) async {
    try {
      print("[GameRepository] Fetching game detail for ID: $gameId");
      final response = await _dio.get('/games/$gameId');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null) {
          final game = Game.fromJson(responseData as Map<String, dynamic>);
          print("[GameRepository] Fetched game detail successfully: ${game.placeName}");
          // TODO: API response should ideally include participants for detail view.
          return game;
        } else {
          print("[GameRepository] Game detail API error: Invalid response structure ('data' missing).");
          throw Exception('試合詳細の取得に失敗しました: 無効なレスポンス');
        }
      } else {
        print("[GameRepository] Game detail API error: Status code ${response.statusCode}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: "試合詳細の取得失敗 ステータス ${response.statusCode}",
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[GameRepository] Game detail API DioException: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.statusCode == 404) {
        throw Exception('E-404-02: 試合が見つかりません'); //
      }
      throw Exception("試合詳細の取得に失敗しました: ${e.message ?? 'APIエラー'}");
    } catch (e) {
      print("[GameRepository] Game detail unexpected error: $e");
      throw Exception("試合詳細の取得中に予期せぬエラーが発生しました。");
    }
  }
}