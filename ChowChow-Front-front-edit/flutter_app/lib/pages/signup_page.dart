import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../theme/chow_theme.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _showPw = false;
  bool _showPw2 = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _nicknameCtrl, _emailCtrl, _pwCtrl, _pw2Ctrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_pwCtrl.text != _pw2Ctrl.text) {
      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (_pwCtrl.text.length < 8) {
      setState(() => _errorMessage = '비밀번호는 8자 이상이어야 합니다.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiClient.post(
        '/api/auth/signup',
        {
          'email': _emailCtrl.text.trim(),
          'password': _pwCtrl.text,
          'userName': _nameCtrl.text.trim(),
          'nickname': _nicknameCtrl.text.trim(),
        },
        auth: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 이메일을 확인해 주세요.')),
      );
      context.go('/login');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('회원가입'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '이름'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nicknameCtrl,
            decoration: const InputDecoration(labelText: '닉네임 (2~20자)'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: '이메일'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pwCtrl,
            obscureText: !_showPw,
            decoration: InputDecoration(
              labelText: '비밀번호 (8자 이상)',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPw = !_showPw),
                icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pw2Ctrl,
            obscureText: !_showPw2,
            decoration: InputDecoration(
              labelText: '비밀번호 확인',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPw2 = !_showPw2),
                icon: Icon(_showPw2 ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignup(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ChowColors.orange500),
            onPressed: _isLoading ? null : _handleSignup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('가입하기'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('이미 계정이 있으신가요? 로그인'),
          ),
        ],
      ),
    );
  }
}