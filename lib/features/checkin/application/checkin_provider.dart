import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import CheckinRepository
import '../data/checkin_repository.dart';
// ★ 1. 試合詳細Providerのインポートを有効化
import '../../game/application/game_detail_provider.dart';

// Check-in Action Provider
// Manages the state of the check-in *action* (idle, loading, error)
final checkinStateProvider = AsyncNotifierProvider<CheckinNotifier, void>(() {
  return CheckinNotifier();
});

// Notifier to handle the check-in logic/state
class CheckinNotifier extends AsyncNotifier<void> {
  late CheckinRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.watch(checkinRepositoryProvider); // Watch repository
    ref.onDispose(() {
      print("[CheckinNotifier] Disposed");
    });
    return; // Needs to return Future<void>
  }

  /// Executes the check-in process for a given game ID.
  /// Called from the UI (e.g., GameDetailScreen button).
  Future<void> executeCheckin(String gameId) async {
    // Prevent execution if already loading
    if (state is AsyncLoading) {
      print("[CheckinNotifier] Check-in already in progress for game ID: $gameId");
      return;
    }

    print("[CheckinNotifier] Attempting check-in for game ID: $gameId");
    // Set loading state
    state = const AsyncValue.loading();
    // Use AsyncValue.guard to automatically handle success/error states
    state = await AsyncValue.guard(() async {
      // Delegate the actual logic (location fetching + API call) to the repository
      await _repository.performCheckin(gameId);
      print("[CheckinNotifier] Check-in successful for game ID: $gameId");

      // --- IMPORTANT ---
      // After successful check-in, update the GameDetail screen's state
      // Invalidate the detail provider to force a refresh.
      ref.invalidate(gameDetailProvider(gameId)); // ★ 2. 正しいProviderをInvalidate
      print("[CheckinNotifier] Invalidated gameDetailProvider for $gameId after check-in.");
    });

    // Error handling (state is automatically set to AsyncError by guard)
    if (state.hasError) {
      print("[CheckinNotifier] Check-in failed for game ID: $gameId. Error: ${state.error}");
      // The UI (GameDetailScreen) should listen to this provider's state
      // and display the error message appropriately (e.g., using a SnackBar).
    }
  }

  // Optional: Method to reset the state back to idle if needed after error display
  void resetState() {
    state = const AsyncValue.data(null);
  }
}

// ★ 3. ファイル末尾の不要なプレースホルダー定義を削除
//
// class Game {} // Placeholder
// final gameDetailProvider = AsyncNotifierProvider.autoDispose.family<GameDetailNotifier, Game, String>(() {
//   return GameDetailNotifier(); // Replace with actual notifier
// });
// class GameDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Game, String> {
//   @override
//   Future<Game> build(String arg) async { /* Placeholder */ throw UnimplementedError(); }
//   Future<void> refreshGameDetail() async { /* Placeholder */}
// }






























// import 'package:flutter_riverpod/flutter_riverpod.dart';
// // Import CheckinRepository
// import '../data/checkin_repository.dart';
// // TODO: Import GameDetailProvider to invalidate/update after check-in
// // import '../../game/application/game_detail_provider.dart';
//
// // Check-in Action Provider
// // Manages the state of the check-in *action* (idle, loading, error)
// // Using AsyncNotifier for action state management. No data needed on success (void).
// final checkinStateProvider = AsyncNotifierProvider<CheckinNotifier, void>(() {
//   return CheckinNotifier();
// });
//
// // Notifier to handle the check-in logic/state
// class CheckinNotifier extends AsyncNotifier<void> {
//   late CheckinRepository _repository;
//
//   @override
//   Future<void> build() async {
//     _repository = ref.watch(checkinRepositoryProvider); // Watch repository
//     // Initial state is idle, AsyncData(null) effectively.
//     // No initial action needed.
//     ref.onDispose(() {
//       print("[CheckinNotifier] Disposed");
//     });
//     return; // Needs to return Future<void>
//   }
//
//   /// Executes the check-in process for a given game ID.
//   /// Called from the UI (e.g., GameDetailScreen button).
//   Future<void> executeCheckin(String gameId) async {
//     // Prevent execution if already loading
//     if (state is AsyncLoading) {
//       print("[CheckinNotifier] Check-in already in progress for game ID: $gameId");
//       return;
//     }
//
//     print("[CheckinNotifier] Attempting check-in for game ID: $gameId");
//     // Set loading state
//     state = const AsyncValue.loading();
//     // Use AsyncValue.guard to automatically handle success/error states
//     state = await AsyncValue.guard(() async {
//       // Delegate the actual logic (location fetching + API call) to the repository
//       await _repository.performCheckin(gameId);
//       print("[CheckinNotifier] Check-in successful for game ID: $gameId");
//
//       // --- IMPORTANT ---
//       // After successful check-in, update the GameDetail screen's state
//       // to reflect the 'checked-in' status.
//       // Invalidate the detail provider to force a refresh.
//       ref.invalidate(gameDetailProvider(gameId)); // Assumes gameDetailProvider exists
//       print("[CheckinNotifier] Invalidated gameDetailProvider for $gameId after check-in.");
//
//       // Note: AsyncValue.guard automatically sets state to AsyncData(null) on success here
//     });
//
//     // Error handling (state is automatically set to AsyncError by guard)
//     if (state.hasError) {
//       print("[CheckinNotifier] Check-in failed for game ID: $gameId. Error: ${state.error}");
//       // The UI (GameDetailScreen) should listen to this provider's state
//       // and display the error message appropriately (e.g., using a SnackBar).
//     }
//   }
//
//   // Optional: Method to reset the state back to idle if needed after error display
//   void resetState() {
//     state = const AsyncValue.data(null);
//   }
// }
//
// // --- Placeholder/Stub for GameDetailProvider ---
// // TODO: Ensure GameDetailProvider exists and can be invalidated
// class Game {} // Placeholder
// final gameDetailProvider = AsyncNotifierProvider.autoDispose.family<GameDetailNotifier, Game, String>(() {
//   return GameDetailNotifier(); // Replace with actual notifier
// });
// class GameDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Game, String> {
//   @override
//   Future<Game> build(String arg) async { /* Placeholder */ throw UnimplementedError(); }
//   Future<void> refreshGameDetail() async { /* Placeholder */}
// }