import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';
import '../widgets/auth_account_ui.dart';

class FindPasswordPage extends StatefulWidget {
  const FindPasswordPage({super.key});

  @override
  State<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  _FindPwStep _step = _FindPwStep.verify;

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _verificationSent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _code, _newPass, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canReset =>
      _newPass.text.length >= 8 &&
      _confirm.text.isNotEmpty &&
      _newPass.text == _confirm.text;

  bool get _isMismatch =>
      _confirm.text.isNotEmpty && _newPass.text != _confirm.text;

  bool get _isMatch =>
      _confirm.text.isNotEmpty && _newPass.text == _confirm.text;

  void _sendVerification() {
    if (_email.text.isEmpty) return;
    setState(() => _verificationSent = true);
  }

  void _verifyCode() {
    if (_code.text.length == 6) {
      setState(() => _step = _FindPwStep.reset);
    }
  }

  void _resetPassword() {
    if (!_canReset) return;
    setState(() => _step = _FindPwStep.complete);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _FindPwStep.complete) {
      return AuthAccountScaffold(
        title: '비밀번호 찾기',
        body: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: ChowColors.green500, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              '비밀번호 변경 완료',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ChowColors.gray900),
            ),
            const SizedBox(height: 8),
            const Text(
              '비밀번호가 성공적으로 변경되었습니다\n새 비밀번호로 로그인해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ChowColors.gray600, height: 1.5),
            ),
            const SizedBox(height: 32),
            AuthPrimaryButton(
              label: '로그인하기',
              enabled: true,
              onPressed: () => context.push('/login'),
            ),
          ],
        ),
      );
    }

    if (_step == _FindPwStep.reset) {
      return AuthAccountScaffold(
        title: '비밀번호 찾기',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrandIcon(),
            const Text(
              '새 비밀번호 설정',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ChowColors.gray900),
            ),
            const SizedBox(height: 8),
            const Text(
              '안전한 비밀번호로 변경해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ChowColors.gray600),
            ),
            const SizedBox(height: 24),
            const AuthFieldLabel(label: '새 비밀번호'),
            AuthTextField(
              controller: _newPass,
              hintText: '비밀번호를 입력하세요 (8자 이상)',
              obscureText: !_showNew,
              onToggleVisibility: () => setState(() => _showNew = !_showNew),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '영문, 숫자, 특수문자 조합 8자 이상',
                style: TextStyle(fontSize: 12, color: ChowColors.gray500),
              ),
            ),
            const SizedBox(height: 20),
            const AuthFieldLabel(label: '새 비밀번호 확인'),
            AuthTextField(
              controller: _confirm,
              hintText: '비밀번호를 다시 입력하세요',
              obscureText: !_showConfirm,
              onToggleVisibility: () => setState(() => _showConfirm = !_showConfirm),
            ),
            if (_isMismatch)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '비밀번호가 일치하지 않습니다',
                  style: TextStyle(fontSize: 12, color: ChowColors.red500),
                ),
              ),
            if (_isMatch)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: ChowColors.green500),
                    SizedBox(width: 4),
                    Text(
                      '비밀번호가 일치합니다',
                      style: TextStyle(fontSize: 12, color: ChowColors.green500),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            AuthPrimaryButton(
              label: '비밀번호 변경',
              enabled: _canReset,
              onPressed: _resetPassword,
            ),
          ],
        ),
      );
    }

    return AuthAccountScaffold(
      title: '비밀번호 찾기',
      footerLinks: const AuthFooterLinks(
        leftLabel: '아이디 찾기',
        leftRoute: '/find-id',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrandIcon(subtitle: '가입 시 등록한 이메일로 인증번호를 전송합니다'),
          const AuthFieldLabel(label: '이메일 (아이디)'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuthTextField(
                  controller: _email,
                  hintText: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_verificationSent,
                ),
              ),
              const SizedBox(width: 8),
              AuthSideButton(
                label: _verificationSent ? '재전송' : '인증번호',
                enabled: _email.text.isNotEmpty && !_verificationSent,
                onPressed: _sendVerification,
              ),
            ],
          ),
          if (_verificationSent) ...[
            const SizedBox(height: 20),
            const AuthFieldLabel(label: '인증번호'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AuthTextField(
                    controller: _code,
                    hintText: '인증번호 6자리 입력',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
                const SizedBox(width: 8),
                AuthSideButton(
                  label: '확인',
                  enabled: _code.text.length == 6,
                  color: ChowColors.green500,
                  onPressed: _verifyCode,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '⏱️ 인증번호는 5분간 유효합니다',
                style: TextStyle(fontSize: 12, color: ChowColors.gray500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _FindPwStep { verify, reset, complete }
