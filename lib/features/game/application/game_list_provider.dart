import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Implement actual GameRepository and import it
import '../data/game_repository.dart';
// TODO: Implement actual Game model and import it
import '../../../core/models/game.dart';

class GameListState {
  final List<Game> games;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingNextPage;
  final String? prefectureFilter;
  final String? dateFromFilter;
  final String? dateToFilter;


  GameListState({
    this.games = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingNextPage = false,
    this.prefectureFilter,
    this.dateFromFilter,
    this.dateToFilter,
  });

  GameListState copyWith({
    List<Game>? games,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingNextPage,
    Object? prefectureFilter = const Object(),
    Object? dateFromFilter = const Object(),
    Object? dateToFilter = const Object(),
  }) {
    return GameListState(
      games: games ?? this.games,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      prefectureFilter: prefectureFilter == const Object() ? this.prefectureFilter : prefectureFilter as String?,
      dateFromFilter: dateFromFilter == const Object() ? this.dateFromFilter : dateFromFilter as String?,
      dateToFilter: dateToFilter == const Object() ? this.dateToFilter : dateToFilter as String?,
    );
  }
}

final gameListProvider = AsyncNotifierProvider.autoDispose<GameListNotifier, GameListState>(() {
  return GameListNotifier();
});

class GameListNotifier extends AutoDisposeAsyncNotifier<GameListState> {
  late GameRepository _repository;
  Timer? _debounce;
  bool _isFetchingNextPage = false;

  @override
  Future<GameListState> build() async {
    _repository = ref.watch(gameRepositoryProvider);
    ref.onDispose(() {
      print("[GameListNotifier] Disposed, canceling debounce timer.");
      _debounce?.cancel();
    });

    print("[GameListNotifier] Initial build fetching page 1.");
    final initialData = await _fetchGames(page: 1);
    print("[GameListNotifier] Initial load complete. Found ${initialData.games.length} games.");
    return GameListState(
        games: initialData.games,
        currentPage: 1,
        hasReachedMax: !initialData.hasMore
    );
  }

  Future<({List<Game> games, bool hasMore})> _fetchGames({required int page}) {
    final currentFilters = state.valueOrNull;
    return _repository.fetchGameList(
        page: page,
        prefecture: currentFilters?.prefectureFilter,
        dateFrom: currentFilters?.dateFromFilter,
        dateTo: currentFilters?.dateToFilter,
        perPage: 20
    );
  }

  Future<void> fetchNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.hasReachedMax || _isFetchingNextPage || state.hasError) {
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final debouncedState = state.valueOrNull;
      if (debouncedState == null || debouncedState.hasReachedMax || _isFetchingNextPage || state.hasError) {
        print("[GameListNotifier] Skipping debounced fetchNextPage.");
        return;
      }

      print("[GameListNotifier] Debounced fetchNextPage triggered for page ${debouncedState.currentPage + 1}.");
      _isFetchingNextPage = true;
      state = AsyncData(debouncedState.copyWith(isLoadingNextPage: true));

      try {
        final nextPage = debouncedState.currentPage + 1;
        print("[GameListNotifier] Fetching page $nextPage");
        final newData = await _fetchGames(page: nextPage);
        final newGames = newData.games;
        final hasMore = newData.hasMore;
        print("[GameListNotifier] Page $nextPage loaded. Found ${newGames.length} new games. HasMore: $hasMore");

        final latestState = state.valueOrNull;
        if (latestState != null) {
          state = AsyncData(latestState.copyWith(
            games: [...latestState.games, ...newGames],
            currentPage: nextPage,
            hasReachedMax: !hasMore,
            isLoadingNextPage: false,
          ));
          print("[GameListNotifier] State updated. Total games: ${state.value?.games.length}. HasReachedMax: ${state.value?.hasReachedMax}");
        } else {
          print("[GameListNotifier] State became null during fetchNextPage, discarding results.");
        }

      } catch (e, stack) {
        print("[GameListNotifier] Error fetching next page: $e");
        final errorState = state.valueOrNull;
        if (errorState != null) {
          state = AsyncData(errorState.copyWith(isLoadingNextPage: false));
        } else {
          state = AsyncValue.error(e, stack);
        }
      } finally {
        _isFetchingNextPage = false;
      }
    });
  }

  Future<void> applyFilter({String? prefecture, String? dateFrom, String? dateTo}) async {
    print("[GameListNotifier] Applying filter - Prefecture: $prefecture, DateFrom: $dateFrom, DateTo: $dateTo");
    _debounce?.cancel();
    _isFetchingNextPage = false;
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final filterState = GameListState(
        prefectureFilter: prefecture,
        dateFromFilter: dateFrom,
        dateToFilter: dateTo,
      );
      final newData = await _fetchGames(page: 1);
      final games = newData.games;
      final hasMore = newData.hasMore;
      print("[GameListNotifier] Filter applied. Loaded ${games.length} games for page 1. HasMore: $hasMore");
      return filterState.copyWith(
        games: games,
        currentPage: 1,
        hasReachedMax: !hasMore,
      );
    });
    if (state.hasError) {
      print("[GameListNotifier] Error applying filter: ${state.error}");
    }
  }
}