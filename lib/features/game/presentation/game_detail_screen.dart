import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/game.dart';
import '../../../core/models/user.dart';
import '../../../core/models/participation.dart';
import '../application/game_detail_provider.dart';
import '../../checkin/application/checkin_provider.dart';
import 'participation_screen.dart';
import '../../auth/application/auth_provider.dart';

class GameDetailScreen extends ConsumerWidget {
  final String gameId;
  const GameDetailScreen({required this.gameId, super.key});
  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dt.toLocal());
  }

  Future<void> _launchGoogleMaps(BuildContext context, String address) async {
    final String query = Uri.encodeComponent(address);
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('[GameDetailScreen] Could not launch maps for address: $address');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地図アプリを起動できませんでした')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameDetailAsyncValue = ref.watch(gameDetailProvider(gameId));
    final authState = ref.watch(authProvider);
    final checkinState = ref.watch(checkinStateProvider);

    ref.listen(checkinStateProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().split(': ').last),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (previous is AsyncLoading && next is AsyncData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('チェックインしました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });


    return Scaffold(
      appBar: AppBar(title: const Text('試合詳細')),
      body: gameDetailAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // (エラー表示は変更なし)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text('試合情報の取得に失敗しました。', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  Text(error.toString().split(': ').last, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('リトライ'),
                    onPressed: () => ref.invalidate(gameDetailProvider(gameId)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('一覧に戻る')
                  )
                ],
              ),
            ),
          );
        },
        data: (game) {

          final bool isUserParticipating = game.isParticipating ?? false;
          final bool hasUserCheckedIn = game.hasCheckedIn ?? false;
          bool canParticipate = game.status == '募集中' && !isUserParticipating;
          bool canCheckin = isUserParticipating && !hasUserCheckedIn && (game.status == '募集中' || game.status == '満員');

          String buttonText = '参加登録';
          VoidCallback? buttonAction = () {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => ParticipationScreen(
                  gameId: game.gameId,
                  gameCapacity: game.capacity,
                  participantCount: game.participantCount,
                  placeName: game.placeName,
                  gameDateTime: game.gameDateTime,
                )
            ));
          };
          Color buttonColor = Theme.of(context).colorScheme.primary;
          final isCheckingIn = checkinState is AsyncLoading;

          if (isUserParticipating && !hasUserCheckedIn && canCheckin) {
            buttonText = 'チェックイン';
            buttonAction = isCheckingIn ? null : () { // ★ 6. ローディング中はnull
              print("[GameDetailScreen] Attempting check-in for game ${game.gameId}");
              ref.read(checkinStateProvider.notifier).executeCheckin(game.gameId);
            };
            buttonColor = Colors.orange;
          } else if (hasUserCheckedIn) {
            buttonText = 'チェックイン済み';
            buttonAction = null;
            buttonColor = Colors.grey;
          } else if (isUserParticipating) {
            buttonText = '参加登録済み';
            buttonAction = null;
            buttonColor = Colors.grey;
          } else if (game.status == '満員') {
            buttonText = '満員';
            buttonAction = null;
            buttonColor = Colors.grey;
          } else if (game.status == '開催済み' || game.status == '中止') {
            buttonText = game.status;
            buttonAction = null;
            buttonColor = Colors.grey;
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(gameDetailProvider(gameId)),
            child: ListView(
              children: [
                Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: Icon(Icons.sports_baseball, size: 80, color: Colors.grey[500])),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game.placeName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      _buildInfoRow(context, Icons.calendar_today_outlined, _formatDateTime(game.gameDateTime)),
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () => _launchGoogleMaps(context, game.address),
                        child: _buildInfoRow(context, Icons.location_on_outlined, game.address, isLink: true),
                      ),

                      const SizedBox(height: 8),
                      _buildInfoRow(context, Icons.attach_money_outlined, game.fee == 0 ? '無料' : '参加費: ¥${NumberFormat("#,###").format(game.fee)}'),
                      const SizedBox(height: 8),
                      _buildInfoRow(context, Icons.group_outlined, '募集人数: ${game.participantCount} / ${game.capacity}人'),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: authState.isAuthenticated ? buttonAction : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: authState.isAuthenticated ? buttonColor : Colors.grey,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isCheckingIn
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                            : Text(
                            authState.isAuthenticated ? buttonText : 'ログインして参加',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Divider(),
                      const SizedBox(height: 16),

                      Text('参加者 (${game.participantCount}人)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildParticipantList(context, game),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isLink ? Theme.of(context).colorScheme.secondary : Theme.of(context).textTheme.bodyLarge?.color,
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantList(BuildContext context, Game game) {
    final List<Participation> participants = game.participants ?? [];

    if (participants.isEmpty) {
      return Text('まだ参加者はいません。', style: Theme.of(context).textTheme.bodyMedium);
    }

    final List<Participation> teamA = participants.where((p) => p.teamDivision == 'チームA').toList();
    final List<Participation> teamB = participants.where((p) => p.teamDivision == 'チームB').toList();

    return Column(
      children: [
        ExpansionTile(
          title: Text('▶ チームA (${teamA.length}人)'),
          childrenPadding: EdgeInsets.only(left: 32),
          children: teamA.isEmpty
              ? [ListTile(dense: true, title: Text('（参加者なし）'))]
              : teamA.map((p) => ListTile(
              dense: true,
              title: Text('${p.user?.nickname ?? '不明'} (${p.position ?? 'N/A'})')
          )).toList(),
        ),
        ExpansionTile(
          title: Text('▶ チームB (${teamB.length}人)'),
          childrenPadding: EdgeInsets.only(left: 32),
          children: teamB.isEmpty
              ? [ListTile(dense: true, title: Text('（参加者なし）'))]
              : teamB.map((p) => ListTile(
              dense: true,
              title: Text('${p.user?.nickname ?? '不明'} (${p.position ?? 'N/A'})')
          )).toList(),
        ),
      ],
    );
  }
}






























// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart'; // For date formatting
// import 'package:url_launcher/url_launcher.dart'; // ★ 1. url_launcherをインポート
// import '../../../core/models/game.dart'; // Import Game model
// import '../../../core/models/user.dart'; // Userモデルをインポート
// import '../../../core/models/participation.dart'; // Participationモデルをインポート
// import '../application/game_detail_provider.dart'; // Import detail provider
// // TODO: Import checkin provider
// // import '../../checkin/application/checkin_provider.dart';
// import 'participation_screen.dart'; // 参加登録画面
// import '../../auth/application/auth_provider.dart'; // 認証状態をインポート
//
// // Game Detail Screen
// class GameDetailScreen extends ConsumerWidget {
//   final String gameId;
//   const GameDetailScreen({required this.gameId, super.key});
//
//   // Helper to format date and time
//   String _formatDateTime(DateTime dt) {
//     return DateFormat('yyyy年MM月dd日 HH:mm').format(dt.toLocal());
//   }
//
//   // ★ 2. Googleマップ起動用のヘルパーメソッドを追加 (設計書  準拠)
//   Future<void> _launchGoogleMaps(BuildContext context, String address) async {
//     final String query = Uri.encodeComponent(address);
//     // iOS/Android共通のWeb URLを使用
//     final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
//
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url, mode: LaunchMode.externalApplication);
//     } else {
//       print('[GameDetailScreen] Could not launch maps for address: $address');
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('地図アプリを起動できませんでした')),
//         );
//       }
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // 試合詳細のデータを監視
//     final gameDetailAsyncValue = ref.watch(gameDetailProvider(gameId));
//     // 認証状態を監視
//     final authState = ref.watch(authProvider);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('試合詳細')),
//       body: gameDetailAsyncValue.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) {
//           print("[GameDetailScreen] Error loading detail: $error\n$stack");
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
//                   const SizedBox(height: 16),
//                   Text('試合情報の取得に失敗しました。', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent)),
//                   const SizedBox(height: 8),
//                   Text(error.toString().split(': ').last, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
//                   const SizedBox(height: 24),
//                   ElevatedButton.icon(
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('リトライ'),
//                     onPressed: () => ref.invalidate(gameDetailProvider(gameId)), // Invalidate to retry
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
//                   ),
//                   const SizedBox(height: 16),
//                   TextButton(
//                       onPressed: () => Navigator.maybePop(context), // Go back if possible
//                       child: const Text('一覧に戻る')
//                   )
//                 ],
//               ),
//             ),
//           );
//         },
//         data: (game) {
//
//           final bool isUserParticipating = game.isParticipating ?? false;
//           final bool hasUserCheckedIn = game.hasCheckedIn ?? false;
//
//           // --- Determine Button State ---
//           bool canParticipate = game.status == '募集中' && !isUserParticipating;
//           bool canCheckin = isUserParticipating && !hasUserCheckedIn && (game.status == '募集中' || game.status == '満員');
//
//           String buttonText = '参加登録';
//           VoidCallback? buttonAction = () {
//             print("[GameDetailScreen] Navigate to Participation Screen for game ${game.gameId}");
//             Navigator.push(context, MaterialPageRoute(
//                 builder: (_) => ParticipationScreen(
//                   gameId: game.gameId,
//                   gameCapacity: game.capacity,
//                   participantCount: game.participantCount,
//                   placeName: game.placeName,
//                   gameDateTime: game.gameDateTime,
//                 )
//             ));
//           };
//           Color buttonColor = Theme.of(context).colorScheme.primary;
//
//           if (isUserParticipating && !hasUserCheckedIn && canCheckin) {
//             buttonText = 'チェックイン';
//             buttonAction = () {
//               print("[GameDetailScreen] Attempting check-in for game ${game.gameId}");
//               // TODO: Call check-in provider
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('チェックイン機能 未実装')));
//             };
//             // buttonColor = AppTheme.warningColor;
//           } else if (hasUserCheckedIn) {
//             buttonText = 'チェックイン済み';
//             buttonAction = null;
//             buttonColor = Colors.grey;
//           } else if (isUserParticipating) {
//             buttonText = '参加登録済み';
//             buttonAction = null;
//             buttonColor = Colors.grey;
//           } else if (game.status == '満員') {
//             buttonText = '満員';
//             buttonAction = null;
//             buttonColor = Colors.grey;
//           } else if (game.status == '開催済み' || game.status == '中止') {
//             buttonText = game.status;
//             buttonAction = null;
//             buttonColor = Colors.grey;
//           }
//           // --- End Button State ---
//
//           return RefreshIndicator(
//             onRefresh: () async => ref.invalidate(gameDetailProvider(gameId)),
//             child: ListView(
//               children: [
//                 Container(
//                   height: 200,
//                   color: Colors.grey[300],
//                   child: Center(child: Icon(Icons.sports_baseball, size: 80, color: Colors.grey[500])),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(game.placeName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 16),
//
//                       _buildInfoRow(context, Icons.calendar_today_outlined, _formatDateTime(game.gameDateTime)),
//                       const SizedBox(height: 8),
//
//                       // ★ 3. InkWellのonTapを修正 ★
//                       InkWell(
//                         onTap: () {
//                           print("[GameDetailScreen] Launching maps for address: ${game.address}");
//                           // 作成したヘルパーメソッドを呼び出す
//                           _launchGoogleMaps(context, game.address);
//                         },
//                         child: _buildInfoRow(context, Icons.location_on_outlined, game.address, isLink: true),
//                       ),
//
//                       const SizedBox(height: 8),
//                       _buildInfoRow(context, Icons.attach_money_outlined, game.fee == 0 ? '無料' : '参加費: ¥${NumberFormat("#,###").format(game.fee)}'),
//                       const SizedBox(height: 8),
//                       _buildInfoRow(context, Icons.group_outlined, '募集人数: ${game.participantCount} / ${game.capacity}人'),
//                       const SizedBox(height: 24),
//
//                       ElevatedButton(
//                         onPressed: authState.isAuthenticated ? buttonAction : null,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: authState.isAuthenticated ? buttonColor : Colors.grey,
//                           minimumSize: const Size.fromHeight(48),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         ),
//                         child: Text(
//                             authState.isAuthenticated ? buttonText : 'ログインして参加',
//                             style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//
//                       const Divider(),
//                       const SizedBox(height: 16),
//
//                       Text('参加者 (${game.participantCount}人)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 8),
//                       _buildParticipantList(context, game),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // (Helper _buildInfoRow は変更なし)
//   Widget _buildInfoRow(BuildContext context, IconData icon, String text, {bool isLink = false}) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, size: 20, color: Colors.grey.shade700),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             text,
//             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//               color: isLink ? Theme.of(context).colorScheme.secondary : Theme.of(context).textTheme.bodyLarge?.color,
//               decoration: isLink ? TextDecoration.underline : TextDecoration.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // (Helper _buildParticipantList は変更なし)
//   Widget _buildParticipantList(BuildContext context, Game game) {
//     final List<Participation> participants = game.participants ?? [];
//
//     if (participants.isEmpty) {
//       return Text('まだ参加者はいません。', style: Theme.of(context).textTheme.bodyMedium);
//     }
//
//     final List<Participation> teamA = participants.where((p) => p.teamDivision == 'チームA').toList();
//     final List<Participation> teamB = participants.where((p) => p.teamDivision == 'チームB').toList();
//
//     return Column(
//       children: [
//         ExpansionTile(
//           title: Text('▶ チームA (${teamA.length}人)'),
//           childrenPadding: EdgeInsets.only(left: 32),
//           children: teamA.isEmpty
//               ? [ListTile(dense: true, title: Text('（参加者なし）'))]
//               : teamA.map((p) => ListTile(
//               dense: true,
//               title: Text('${p.user?.nickname ?? '不明'} (${p.position ?? 'N/A'})')
//           )).toList(),
//         ),
//         ExpansionTile(
//           title: Text('▶ チームB (${teamB.length}人)'),
//           childrenPadding: EdgeInsets.only(left: 32),
//           children: teamB.isEmpty
//               ? [ListTile(dense: true, title: Text('（参加者なし）'))]
//               : teamB.map((p) => ListTile(
//               dense: true,
//               title: Text('${p.user?.nickname ?? '不明'} (${p.position ?? 'N/A'})')
//           )).toList(),
//         ),
//       ],
//     );
//   }
//
// }