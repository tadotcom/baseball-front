import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_provider.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).requestPasswordReset(_emailController.text.trim());
      print("[PasswordResetScreen] Password reset link request successful.");

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

    } catch (e) {
      print("[PasswordResetScreen] Password reset request error: $e");
      if(mounted) {
        setState(() => _isLoading = false);
        // 3. エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Exception ? e.toString().split(': ').last : 'メール送信に失敗しました。'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('パスワードリセット')), //
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'パスワードリセット',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _emailSent
                    ? '入力されたメールアドレスにパスワードリセット用のリンクを送信しました。メールをご確認ください。'
                    : '登録済みのメールアドレスを入力してください。パスワードリセット用のリンクを送信します。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              if (!_emailSent) // Hide form after sending
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス *',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'user@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return '有効なメールアドレスを入力してください'; //
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _sendResetLink(),
                ),
              const SizedBox(height: 24),

              // Send Button
              if (!_emailSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                      : const Text('リセットリンクを送信'),
                ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: Text(_emailSent ? 'ログイン画面に戻る' : 'キャンセル'),
              ),

              // TODO: Add logic for F-USR-004 Part 2 (Password Reset Execution)
            ],
          ),
        ),
      ),
    );
  }
}































// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// // TODO: Import AuthRepository or a specific provider for password reset
// import '../application/auth_provider.dart'; // Can add reset methods here or separate provider
//
// // Password Reset Screen
// class PasswordResetScreen extends ConsumerStatefulWidget {
//   const PasswordResetScreen({super.key});
//
//   @override
//   ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
// }
//
// class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   bool _isLoading = false;
//   bool _emailSent = false; // State to show confirmation message
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }
//
//   // Function to handle password reset request (F-USR-004 Part 1)
//   Future<void> _sendResetLink() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//     setState(() => _isLoading = true);
//
//     try {
//       // TODO: Implement password reset request logic in AuthRepository/Provider
//       // await ref.read(authProvider.notifier).requestPasswordReset(_emailController.text.trim());
//       print("[PasswordResetScreen] Simulating sending reset link to ${_emailController.text.trim()}...");
//       await Future.delayed(Duration(seconds: 1)); // Simulate API call
//
//       setState(() {
//         _emailSent = true; // Show confirmation message
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('パスワードリセット用のメールを送信しました。')),
//       );
//
//     } catch (e) {
//       print("[PasswordResetScreen] Password reset request error: $e");
//       if(mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(e is Exception ? e.toString().split(': ').last : 'メール送信に失敗しました。'),
//             backgroundColor: Theme.of(context).colorScheme.error,
//           ),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('パスワードリセット')), //
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text(
//                 'パスワードリセット',
//                 style: Theme.of(context).textTheme.headlineSmall,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 _emailSent
//                     ? '入力されたメールアドレスにパスワードリセット用のリンクを送信しました。メールをご確認ください。'
//                     : '登録済みのメールアドレスを入力してください。パスワードリセット用のリンクを送信します。',
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//               const SizedBox(height: 32),
//
//               // Email Field
//               if (!_emailSent) // Hide form after sending
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: InputDecoration(
//                     labelText: 'メールアドレス *',
//                     prefixIcon: Icon(Icons.email_outlined),
//                     hintText: 'user@example.com',
//                     // border: OutlineInputBorder(), // Use theme
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty || !value.contains('@')) {
//                       return '有効なメールアドレスを入力してください'; //
//                     }
//                     return null;
//                   },
//                   textInputAction: TextInputAction.done,
//                   onFieldSubmitted: (_) => _isLoading ? null : _sendResetLink(),
//                 ),
//               const SizedBox(height: 24),
//
//               // Send Button
//               if (!_emailSent)
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _sendResetLink,
//                   // style: AppTheme.lightTheme.elevatedButtonTheme.style,
//                   child: _isLoading
//                       ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
//                       : const Text('リセットリンクを送信'),
//                 ),
//
//               // Back to Login Button (always visible?)
//               const SizedBox(height: 16),
//               TextButton(
//                 onPressed: _isLoading ? null : () {
//                   if (Navigator.canPop(context)) {
//                     Navigator.pop(context); // Go back to the previous screen (likely Login)
//                   }
//                 },
//                 child: Text(_emailSent ? 'ログイン画面に戻る' : 'キャンセル'),
//               ),
//
//               // TODO: Add logic for F-USR-004 Part 2 (Password Reset Execution)
//               // This usually involves handling a deep link with a token,
//               // showing new password + confirmation fields, and calling PUT /api/v1/auth/password/update
//               // This might be a separate screen or conditional UI here based on deep link data.
//
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }