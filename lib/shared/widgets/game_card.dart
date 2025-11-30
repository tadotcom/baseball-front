import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/game.dart';
import '../../core/theme/app_theme.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const GameCard({
    required this.game,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd HH:mm', 'ja_JP').format(dt.toLocal()); // Use locale if needed
  }

  String _getDisplayStatus() {
    print("[GameCard] Game: ${game.gameId}, Status: ${game.status}, isParticipating: ${game.isParticipating}, hasCheckedIn: ${game.hasCheckedIn}");

    if (game.isParticipating == true) {
      if (game.hasCheckedIn == true) {
        print("[GameCard] Displaying: チェックイン済");
        return 'チェックイン済';
      } else {
        print("[GameCard] Displaying: 参加中");
        return '参加中';
      }
    }
    print("[GameCard] Displaying original status: ${game.status}");
    return game.status;
  }

  Color _getStatusChipBackgroundColor(BuildContext context, String displayStatus) {
    switch (displayStatus) {
      case '参加中':
        return Colors.blue.withOpacity(0.15);
      case 'チェックイン済':
        return Colors.green.withOpacity(0.15);
      case '募集中':
        return AppTheme.primaryColor.withOpacity(0.1);
      case '満員':
        return AppTheme.warningColor.withOpacity(0.15);
      case '開催済み':
      case '中止':
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getStatusTextColor(BuildContext context, String displayStatus) {
    switch (displayStatus) {
      case '参加中':
        return Colors.blue.shade700;
      case 'チェックイン済':
        return Colors.green.shade700;
      case '募集中':
        return AppTheme.primaryColor;
      case '満員':
        return AppTheme.warningColor;
      case '開催済み':
      case '中止':
      default:
        return Colors.black54;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final displayStatus = _getDisplayStatus();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: (theme.cardTheme.shape is RoundedRectangleBorder)
            ? ((theme.cardTheme.shape as RoundedRectangleBorder).borderRadius as BorderRadius?)
            : BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      game.placeName,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(displayStatus),
                    backgroundColor: _getStatusChipBackgroundColor(context, displayStatus),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: _getStatusTextColor(context, displayStatus),
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none, // No border
                  )
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(game.gameDateTime),
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      game.address,
                      style: textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money, size: 18, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        game.fee == 0 ? '無料' : '¥${NumberFormat("#,###",'ja_JP').format(game.fee)}',
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_outlined, size: 18, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${game.participantCount} / ${game.capacity}人',
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}