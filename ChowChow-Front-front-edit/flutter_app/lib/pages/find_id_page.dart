import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';
import '../widgets/auth_account_ui.dart';

class FindIdPage extends StatefulWidget {
  const FindIdPage({super.key});

  @override
  State<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  _FindIdStep _step = _FindIdStep.input;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  String? _year;
  String? _month;
  String? _day;

  bool _verificationSent = false;
  bool _isVerified = false;
  String _foundEmail = '';

  late final List<String> _years;
  late final List<String> _months;
  late final List<String> _days;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _years = List.generate(currentYear - 1949, (i) => '${currentYear - i}');
    _months = List.generate(12, (i) => '${i + 1}');
    _days = List.generate(31, (i) => '${i + 1}');
    for (final c in [_name, _phone, _code]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _canFindId =>
      _name.text.isNotEmpty &&
      _year != null &&
      _month != null &&
      _day != null &&
      _isVerified;

  void _sendVerification() {
    if (_phone.text.length < 10) return;
    setState(() => _verificationSent = true);
  }

  void _verifyCode() {
    if (_code.text.length == 6) {
      setState(() => _isVerified = true);
    }
  }

  void _findId() {
    const mockEmail = 'petlover1234@gmail.com';
    final parts = mockEmail.split('@');
    final local = parts[0];
    final blurred = '${local.substring(0, 3)}${'*' * (local.length - 3)}@${parts[1]}';
    setState(() {
      _foundEmail = blurred;
      _step = _FindIdStep.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _FindIdStep.result) {
      return _ResultView(
        foundEmail: _foundEmail,
        onLogin: () => context.push('/login'),
        onFindPassword: () => context.push('/find-password'),
      );
    }

    return AuthAccountScaffold(
      title: '아이디 찾기',
      footerLinks: const AuthFooterLinks(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrandIcon(subtitle: '가입 시 등록한 정보를 입력해주세요'),
          const AuthFieldLabel(label: '이름'),
          AuthTextField(
            controller: _name,
            hintText: '이름을 입력하세요',
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel(label: '생년월일'),
          Row(
            children: [
              Expanded(
                child: AuthDropdownField(
                  hint: '년도',
                  value: _year,
                  items: _years,
                  onChanged: (v) => setState(() => _year = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AuthDropdownField(
                  hint: '월',
                  value: _month,
                  items: _months,
                  onChanged: (v) => setState(() => _month = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AuthDropdownField(
                  hint: '일',
                  value: _day,
                  items: _days,
                  onChanged: (v) => setState(() => _day = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel(label: '전화번호'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuthTextField(
                  controller: _phone,
                  hintText: '010-0000-0000',
                  keyboardType: TextInputType.phone,
                  enabled: !_isVerified,
                  maxLength: 11,
                ),
              ),
              const SizedBox(width: 8),
              AuthSideButton(
                label: _verificationSent ? '재전송' : '인증번호',
                enabled: _phone.text.length >= 10 && !_isVerified,
                onPressed: _sendVerification,
              ),
            ],
          ),
          if (_verificationSent && !_isVerified) ...[
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
          if (_isVerified)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: ChowColors.green500, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '전화번호 인증이 완료되었습니다',
                    style: TextStyle(fontSize: 14, color: ChowColors.green500),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          AuthPrimaryButton(
            label: '아이디 찾기',
            enabled: _canFindId,
            onPressed: _findId,
          ),
        ],
      ),
    );
  }
}

enum _FindIdStep { input, result }

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.foundEmail,
    required this.onLogin,
    required this.onFindPassword,
  });

  final String foundEmail;
  final VoidCallback onLogin;
  final VoidCallback onFindPassword;

  @override
  Widget build(BuildContext context) {
    return AuthAccountScaffold(
      title: '아이디 찾기',
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
            '아이디를 찾았습니다',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ChowColors.gray900),
          ),
          const SizedBox(height: 8),
          const Text(
            '회원님의 정보와 일치하는 아이디입니다',
            style: TextStyle(fontSize: 14, color: ChowColors.gray600),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ChowColors.orange50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ChowColors.orange100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('가입된 이메일 (아이디)', style: TextStyle(fontSize: 14, color: ChowColors.gray600)),
                const SizedBox(height: 8),
                Text(
                  foundEmail,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ChowColors.gray900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(label: '로그인하기', enabled: true, onPressed: onLogin),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onFindPassword,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: ChowColors.gray300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('비밀번호 찾기', style: TextStyle(color: ChowColors.gray700, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
