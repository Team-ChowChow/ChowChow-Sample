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
  final _codeCtrl = TextEditingController();
  String? _birthYear;
  String? _birthMonth;
  String? _birthDay;
  late final List<String> _birthYears;
  final _birthMonths = List.generate(12, (i) => '${i + 1}');
  final _birthDays = List.generate(31, (i) => '${i + 1}');

  bool _showPw = false;
  bool _showPw2 = false;
  bool _isLoading = false;
  String? _errorMessage;

  // 이메일 인증 상태
  bool _emailSent = false;
  bool _emailVerified = false;
  bool _sendingEmail = false;
  bool _verifyingCode = false;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _birthYears = List.generate(currentYear - 1899, (i) => '${currentYear - i}');
    _codeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _nicknameCtrl, _emailCtrl, _pwCtrl, _pw2Ctrl, _codeCtrl]) {
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

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.length != 6) return;
    final email = _emailCtrl.text.trim();
    setState(() { _verifyingCode = true; _errorMessage = null; });
    try {
      await ApiClient.post(
        '/api/auth/verify-signup-code',
        {'email': email, 'code': _codeCtrl.text.trim()},
        auth: false,
      );
      setState(() => _emailVerified = true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '인증번호를 확인할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_emailVerified) {
      setState(() => _errorMessage = '이메일 인증을 먼저 완료해주세요.');
      return;
    }
    if (_birthYear == null || _birthMonth == null || _birthDay == null) {
      setState(() => _errorMessage = '생년월일을 선택해주세요.');
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
          'birthdate':
              '$_birthYear-${_birthMonth!.padLeft(2, '0')}-${_birthDay!.padLeft(2, '0')}',
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
          const Text('생년월일', style: TextStyle(fontSize: 12, color: ChowCozy.stone600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _birthYear,
                  decoration: const InputDecoration(hintText: '년도'),
                  items: _birthYears
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) => setState(() => _birthYear = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _birthMonth,
                  decoration: const InputDecoration(hintText: '월'),
                  items: _birthMonths
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _birthMonth = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _birthDay,
                  decoration: const InputDecoration(hintText: '일'),
                  items: _birthDays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _birthDay = v),
                ),
              ),
            ],
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
                        : ChowCozy.stone500,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(labelText: '인증번호 6자리 입력'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: (_verifyingCode || _codeCtrl.text.length != 6) ? null : _verifyCode,
                    child: _verifyingCode
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('확인', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '⏱️ 인증번호는 5분간 유효합니다',
                style: TextStyle(fontSize: 12, color: ChowColors.gray500),
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
              style: const TextStyle(fontSize: 13, color: ChowCozy.destructive),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ChowCozy.stone500),
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