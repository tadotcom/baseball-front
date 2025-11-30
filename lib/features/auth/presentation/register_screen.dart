import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_provider.dart';
import '../../game/presentation/game_list_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  Map<String, String> _apiErrors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _apiErrors = {});

    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).register(
        _emailController.text.trim(),
        _passwordController.text,
        _nicknameController.text.trim(),
      );

      print("[RegisterScreen] Registration successful.");

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GameListScreen()),
              (route) => false,
        );
      }

    } catch (e) {
      print("[RegisterScreen] Registration error: $e");
      String errorMessage = '登録に失敗しました。';
      Map<String, String> fieldErrors = {};
      if (e.toString().contains('E-409-01')) {
        errorMessage = 'このメールアドレスは既に登録されています';
        fieldErrors['email'] = errorMessage;
      } else if (e.toString().contains('E-409-02')) {
        errorMessage = 'このニックネームは既に使用されています';
        fieldErrors['nickname'] = errorMessage;
      } else if (e.toString().contains(': ')) {
        errorMessage = e.toString().split(': ').last;
        if (errorMessage.contains('メールアドレス')) fieldErrors['email'] = errorMessage;
        if (errorMessage.contains('ニックネーム')) fieldErrors['nickname'] = errorMessage;
        if (errorMessage.contains('パスワード確認')) fieldErrors['password_confirm'] = errorMessage;
        else if (errorMessage.contains('パスワード')) fieldErrors['password'] = errorMessage;
      }

      if (mounted) {
        setState(() {
          _apiErrors = fieldErrors;
          _isLoading = false;
        });
        _formKey.currentState?.validate();
        if (fieldErrors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
    finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('アカウント登録')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'メールアドレス *',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'user@example.com',
                  errorText: _apiErrors['email'],
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (_apiErrors.containsKey('email')) return null; // Let API error show
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return '有効なメールアドレスを入力してください'; //
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'パスワード *',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: '8文字以上、英数字・記号を2種以上',
                  errorText: _apiErrors['password'],
                  // TODO: Add suffix icon for visibility toggle
                ),
                obscureText: true,
                validator: (value) {
                  if (_apiErrors.containsKey('password')) return null;
                  if (value == null || value.isEmpty) {
                    return 'パスワードを入力してください';
                  }
                  if (value.length < 8 || value.length > 72) { // Length check
                    return 'パスワードは8文字以上72文字以下で入力してください';
                  }
                  bool hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
                  bool hasNumber = value.contains(RegExp(r'[0-9]'));
                  int types = (value.contains(RegExp(r'[a-z]')) ? 1 : 0) +
                      (value.contains(RegExp(r'[A-Z]')) ? 1 : 0) +
                      (value.contains(RegExp(r'[0-9]')) ? 1 : 0);

                  if (types < 2) {
                    return '英大文字・小文字・数字のうち2種類以上を含めてください';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordConfirmController,
                decoration: InputDecoration(
                  labelText: 'パスワード確認 *',
                  prefixIcon: Icon(Icons.lock_outline),
                  errorText: _apiErrors['password_confirm'],
                ),
                obscureText: true,
                validator: (value) {
                  if (_apiErrors.containsKey('password_confirm')) return null;
                  if (value == null || value.isEmpty) {
                    return 'パスワードを再入力してください';
                  }
                  if (value != _passwordController.text) {
                    return 'パスワードが一致しません'; //
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'ニックネーム *',
                  prefixIcon: Icon(Icons.account_circle_outlined),
                  helperText: '4文字固定 (全角・半角問わず)',
                  counterText: "",
                  errorText: _apiErrors['nickname'],
                ),
                maxLength: 4, // Enforce max length visually
                validator: (value) {
                  if (_apiErrors.containsKey('nickname')) return null;
                  if (value == null || value.isEmpty) {
                    return 'ニックネームを入力してください';
                  }
                  if (value.characters.length != 4) {
                    return 'ニックネームは4文字で入力してください'; //
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _register(),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : const Text('登録する'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('既にアカウントをお持ちですか?'),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      // Navigate back to Login Screen
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                      }
                    },
                    child: Text('ログイン'),
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