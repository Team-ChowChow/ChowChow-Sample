import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';
import '../widgets/auth_account_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _newPass, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _current.text.isNotEmpty &&
        _newPass.text.length >= 8 &&
        _confirm.text.isNotEmpty &&
        _newPass.text == _confirm.text;
  }

  bool get _isMismatch =>
      _confirm.text.isNotEmpty && _newPass.text != _confirm.text;

  bool get _isMatch =>
      _confirm.text.isNotEmpty && _newPass.text == _confirm.text;

  void _submit() {
    if (!_isValid) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
    );
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    return AuthAccountScaffold(
      title: '비밀번호 변경',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthLockIcon(subtitle: '안전한 비밀번호로 변경해주세요'),
          const AuthFieldLabel(label: '현재 비밀번호'),
          AuthTextField(
            controller: _current,
            hintText: '현재 비밀번호를 입력하세요',
            obscureText: !_showCurrent,
            onToggleVisibility: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel(label: '새 비밀번호'),
          AuthTextField(
            controller: _newPass,
            hintText: '새 비밀번호를 입력하세요 (8자 이상)',
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
            hintText: '새 비밀번호를 다시 입력하세요',
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
          const SizedBox(height: 20),
          const AuthInfoBox(),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: '비밀번호 변경',
            enabled: _isValid,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
