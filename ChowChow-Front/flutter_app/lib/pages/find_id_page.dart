import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
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

  String? _year;
  String? _month;
  String? _day;

  bool _loading = false;
  String? _errorMessage;
  List<String> _foundEmails = [];

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
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canFindId =>
      _name.text.isNotEmpty && _year != null && _month != null && _day != null && !_loading;

  Future<void> _findId() async {
    if (!_canFindId) return;
    setState(() { _loading = true; _errorMessage = null; });
    final birthdate =
        '$_year-${_month!.padLeft(2, '0')}-${_day!.padLeft(2, '0')}';
    try {
      final res = await ApiClient.post(
        '/api/auth/find-id',
        {'userName': _name.text.trim(), 'birthdate': birthdate},
        auth: false,
      ) as Map<String, dynamic>;
      setState(() {
        _foundEmails = (res['emails'] as List<dynamic>).cast<String>();
        _step = _FindIdStep.result;
      });
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _FindIdStep.result) {
      return _ResultView(
        foundEmails: _foundEmails,
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
          const AuthBrandIcon(subtitle: '가입 시 등록한 이름과 생년월일을 입력해주세요'),
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
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: ChowColors.red500),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          AuthPrimaryButton(
            label: _loading ? '조회 중...' : '아이디 찾기',
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
    required this.foundEmails,
    required this.onLogin,
    required this.onFindPassword,
  });

  final List<String> foundEmails;
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ChowColors.gray900),
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
              color: ChowCozy.stone100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ChowCozy.stone300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('가입된 이메일 (아이디)', style: TextStyle(fontSize: 14, color: ChowColors.gray600)),
                const SizedBox(height: 8),
                for (final email in foundEmails)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      email,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ChowColors.gray900),
                    ),
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
