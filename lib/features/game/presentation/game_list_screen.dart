import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/game_list_provider.dart';
import '../../../core/models/game.dart';
import '../../../shared/widgets/game_card.dart';
import '../../settings/presentation/settings_screen.dart';
import 'game_detail_screen.dart';
import '../../auth/application/auth_provider.dart';

class GameListScreen extends ConsumerStatefulWidget {
  const GameListScreen({super.key});

  @override
  ConsumerState<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends ConsumerState<GameListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(gameListProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showFilterDialog() async {
    print("[GameListScreen] Filter button pressed. Dialog TBD.");
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => FilterDialog(),
    );

    if (result != null) {
      print("[GameListScreen] Applying filters: $result");
      ref.read(gameListProvider.notifier).applyFilter(
        prefecture: result['prefecture'],
        dateFrom: result['dateFrom'],
        dateTo: result['dateTo'],
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    print("[GameListScreen] Logout button pressed.");

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ログアウト'),
          content: const Text('本当にログアウトしますか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('ログアウト'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      print("[GameListScreen] Logout confirmed. Executing...");
      ref.read(authProvider.notifier).logout();
    } else {
      print("[GameListScreen] Logout cancelled.");
    }
  }


  @override
  Widget build(BuildContext context) {
    final gameListAsyncValue = ref.watch(gameListProvider);
    ref.listen<AsyncValue<GameListState>>(gameListProvider, (_, next) {
      if (next is AsyncError && !next.isLoading) {
        final currentState = next.valueOrNull;
        if (currentState != null && currentState.games.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('リストの更新に失敗しました: ${next.error.toString().split(': ').last}'),
              backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
            ),
          );
        }
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text('試合一覧'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'フィルター',
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings),
            onPressed: () {
              print("[GameListScreen] Settings button pressed.");
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          IconButton(
            tooltip: 'ログアウト',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: gameListAsyncValue.when(
              data: (gameListState) {
                final games = gameListState.games;
                final isLoadingNextPage = gameListState.isLoadingNextPage;

                if (games.isEmpty && !isLoadingNextPage) {
                  return RefreshIndicator(
                    onRefresh: _refreshList,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          const Center(child: Text('開催予定の試合はありません。'))
                        ]
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshList,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: games.length + (isLoadingNextPage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == games.length && isLoadingNextPage) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (index >= games.length) return const SizedBox.shrink();

                      final game = games[index];
                      return GameCard(
                          game: game,
                          onTap: () {
                            print("[GameListScreen] Tapped on game: ${game.gameId} - ${game.placeName}");
                            Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailScreen(gameId: game.gameId)));
                          }
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                print("[GameListScreen] Error loading games: $error\n$stackTrace");
                return _buildErrorWidget(context, error, _refreshList);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshList() async {
    print("[GameListScreen] Pull to refresh triggered.");
    ref.refresh(gameListProvider);
  }

  Widget _buildErrorWidget(BuildContext context, Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              '試合情報の取得に失敗しました。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().split(': ').last,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('リトライ'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Implement actual Filter Dialog
class FilterDialog extends StatefulWidget {
  @override
  State<FilterDialog> createState() => _FilterDialogState();
}
class _FilterDialogState extends State<FilterDialog> {
  String? selectedPrefecture;
  // TODO: Add state for date pickers (dateFrom, dateTo)

  @override
  Widget build(BuildContext context) {
    final List<String> prefectures = ['北海道', '青森県', '岩手県', /* ... all 47 ... */ '沖縄県'];

    return AlertDialog(
      title: Text('フィルター'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('都道府県:', style: Theme.of(context).textTheme.labelMedium),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedPrefecture,
              hint: Text('すべて'),
              items: [
                DropdownMenuItem(value: null, child: Text('すべて')),
                ...prefectures.map((p) => DropdownMenuItem(value: p, child: Text(p))),
              ],
              onChanged: (value) => setState(() => selectedPrefecture = value),
            ),
            SizedBox(height: 16),
            Text('開催日:', style: Theme.of(context).textTheme.labelMedium),
            // TODO: Add Date Range Picker or two Date Pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: (){/* TODO: Show Date Picker for dateFrom */}, child: Text('開始日選択')),
                TextButton(onPressed: (){/* TODO: Show Date Picker for dateTo */}, child: Text('終了日選択')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('キャンセル')),
        ElevatedButton( // Use ElevatedButton for Apply
          onPressed: () {
            Navigator.pop(context, {
              'prefecture': selectedPrefecture,
              // TODO: Pass selected dateFrom/dateTo as YYYY-MM-DD strings
              'dateFrom': null,
              'dateTo': null,
            });
          },
          child: Text('適用'),
        ),
      ],
    );
  }
}