import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/application/auth_provider.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アプリを開けませんでした: $urlString')),
      );
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _logout(BuildContext context, WidgetRef ref) async {
    final authNotifier = ref.read(authProvider.notifier);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await authNotifier.logout();
    print("[SettingsScreen] Logout complete.");
  }

  void _deleteAccount(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('本当に退会しますか？'),
        content: const Text('この操作は取り消せません。あなたのアカウントに関連する全てのデータ（参加履歴など）が削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退会する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(authProvider.notifier).deleteAccount();

      if (context.mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      // 失敗時
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アカウントの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    const String domain = 'https://api.ai-next-answer.jp/api/v1';

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _launchURL(context, '$domain/terms');
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _launchURL(context, '$domain/privacy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('アプリのバージョン'),
            subtitle: packageInfo.when(
              data: (info) => Text('Version ${info.version} (Build ${info.buildNumber})'),
              loading: () => const Text('読み込み中...'),
              error: (e, s) => const Text('取得失敗'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('アカウントを削除 (退会)', style: TextStyle(color: Colors.red)),
            onTap: () => _deleteAccount(context, ref), // F-USR-009 (新規)
          ),
        ],
      ),
    );
  }
}