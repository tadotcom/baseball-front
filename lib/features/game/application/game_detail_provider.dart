import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/game_repository.dart';
import '../../../core/models/game.dart';

final gameDetailProvider = AsyncNotifierProvider.autoDispose.family<GameDetailNotifier, Game, String>(() {
  return GameDetailNotifier();
});

class GameDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Game, String> {

  late GameRepository _repository;

  @override
  Future<Game> build(String gameId) async {
    _repository = ref.watch(gameRepositoryProvider);

    ref.onDispose(() {
      print("[GameDetailNotifier($gameId)] Disposed");
    });

    print("[GameDetailNotifier($gameId)] Initial build fetching details.");
    final game = await _repository.fetchGameDetail(gameId);
    print("[GameDetailNotifier($gameId)] Initial fetch complete: ${game.placeName}");
    // TODO: Fetch participant details if not included in fetchGameDetail response
    return game;
  }

  Future<void> refreshGameDetail() async {
    final gameId = arg;
    print("[GameDetailNotifier($gameId)] Refreshing game details.");
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final game = await _repository.fetchGameDetail(gameId);
      // TODO: Potentially refresh participants as well
      print("[GameDetailNotifier($gameId)] Refresh complete: ${game.placeName}");
      return game;
    });
    if (state.hasError) {
      print("[GameDetailNotifier($gameId)] Error refreshing: ${state.error}");
    }
  }

  void updateParticipationStatus(/* Updated participation data */) {
    final gameId = arg;
    print("[GameDetailNotifier($gameId)] Updating state after participation/check-in.");
    final currentState = state.valueOrNull;
    if (currentState != null) {
      print("[GameDetailNotifier($gameId)] State updated locally (placeholder). Refresh recommended.");
      refreshGameDetail();
    }
  }
}