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

  // 이메일 인증 상태
  bool _emailSent = false;
  bool _emailVerified = false;
  bool _sendingEmail = false;
  bool _checkingVerify = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _nicknameCtrl, _emailCtrl, _pwCtrl, _pw2Ctrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendVerifyEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = '올바른 이메일을 입력해주세요.');
      return;
    }
    setState(() { _sendingEmail = true; _errorMessage = null; });
    try {
      await ApiClient.post('/api/auth/send-email-verify', {'email': email}, auth: false);
      setState(() { _emailSent = true; _emailVerified = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 이메일을 발송했습니다. 메일함을 확인해주세요.')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  Future<void> _checkVerified() async {
    final email = _emailCtrl.text.trim();
    setState(() { _checkingVerify = true; _errorMessage = null; });
    try {
      final res = await ApiClient.get(
        '/api/auth/check-pre-verified',
        auth: false,
        query: {'email': email},
      ) as Map<String, dynamic>;
      final verified = res['verified'] as bool? ?? false;
      setState(() => _emailVerified = verified);
      if (!verified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아직 인증이 완료되지 않았습니다. 메일함을 확인해주세요.')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '인증 상태를 확인할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _checkingVerify = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_emailVerified) {
      setState(() => _errorMessage = '이메일 인증을 먼저 완료해주세요.');
      return;
    }
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
        const SnackBar(content: Text('회원가입이 완료되었습니다.')),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    suffixIcon: _emailVerified
                        ? const Icon(Icons.check_circle, color: Color(0xFF22C55E))
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_emailVerified,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _emailVerified
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: (_sendingEmail || _emailVerified) ? null : _sendVerifyEmail,
                  child: _sendingEmail
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_emailVerified ? '인증완료' : '인증요청', style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          if (_emailSent && !_emailVerified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '📧 인증 메일을 발송했습니다.\n메일함의 링크를 클릭한 후 아래 버튼을 눌러주세요.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _checkingVerify ? null : _checkVerified,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF97316)),
                      foregroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _checkingVerify
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('인증 완료 확인', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
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