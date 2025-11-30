import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Import Participation model
import '../../../core/models/participation.dart';
// TODO: Import ParticipationRepository
import '../data/participation_repository.dart';
import 'game_detail_provider.dart';
import 'game_list_provider.dart';

final participationActionProvider = AsyncNotifierProvider<ParticipationActionNotifier, Participation?>(() {
  return ParticipationActionNotifier();
});

class ParticipationActionNotifier extends AsyncNotifier<Participation?> {
  late ParticipationRepository _repository;

  @override
  Future<Participation?> build() async {
    _repository = ref.watch(participationRepositoryProvider);
    return null;
  }

  Future<void> register({
    required String gameId,
    required String teamDivision,
    required String position,
  }) async {
    print("[ParticipationNotifier] Attempting participation for game $gameId (Team: $teamDivision, Pos: $position)");
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final participation = await _repository.registerForGame(
        gameId: gameId,
        teamDivision: teamDivision,
        position: position,
      );
      print("[ParticipationNotifier] Participation successful: ID ${participation.participationId}");
      ref.invalidate(gameDetailProvider(gameId));
      print("[ParticipationNotifier] Invalidated gameDetailProvider for $gameId.");
      ref.invalidate(gameListProvider);
      print("[ParticipationNotifier] Invalidated gameListProvider to refresh list with updated participation status.");
      return participation;
    });

    if (state.hasError) {
      print("[ParticipationNotifier] Participation failed: ${state.error}");
    }
  }
}