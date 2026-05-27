import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../theme/chow_theme.dart';
import '../widgets/auth_account_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _bgCream = Color(0xFFFFFBF5);

  final _id = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  bool _autoLogin = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final c in [_id, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canLogin => _id.text.isNotEmpty && _password.text.isNotEmpty;

  Future<void> _handleLogin() async {
    if (!_canLogin || _isLoading) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await ApiClient.post(
        '/api/auth/login',
        {'email': _id.text.trim(), 'password': _password.text},
        auth: false,
      ) as Map<String, dynamic>;
      final token = res['accessToken'] as String?;
      if (token != null) await ApiClient.saveToken(token);
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.statusCode == 401 ? '아이디 또는 비밀번호가 올바르지 않습니다.' : '로그인에 실패했습니다.');
    } catch (_) {
      setState(() => _errorMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleLogin() => context.go('/');

  void _handleKakaoLogin() => context.go('/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        const _PawLogo(),
                        const SizedBox(height: 20),
                        const Text(
                          '펫푸드 레시피',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF7000),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '우리 아이를 위한 건강한 식단',
                          style: TextStyle(fontSize: 14, color: ChowColors.gray600, height: 1.4),
                        ),
                        const SizedBox(height: 36),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '아이디',
                            style: TextStyle(fontSize: 14, color: ChowColors.gray700, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AuthTextField(controller: _id, hintText: '아이디를 입력하세요'),
                        const SizedBox(height: 18),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '비밀번호',
                            style: TextStyle(fontSize: 14, color: ChowColors.gray700, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AuthTextField(
                          controller: _password,
                          hintText: '비밀번호를 입력하세요',
                          obscureText: !_showPassword,
                          onToggleVisibility: () => setState(() => _showPassword = !_showPassword),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => setState(() => _autoLogin = !_autoLogin),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: _autoLogin,
                                    onChanged: (v) => setState(() => _autoLogin = v ?? false),
                                    activeColor: const Color(0xFFFF7000),
                                    side: const BorderSide(color: ChowColors.gray300, width: 1.5),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('자동 로그인', style: TextStyle(fontSize: 14, color: ChowColors.gray600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _LoginButton(onPressed: (_canLogin && !_isLoading) ? _handleLogin : null, isLoading: _isLoading),
                        const SizedBox(height: 18),
                        AuthFooterLinks(
                          leftLabel: '아이디 찾기',
                          leftRoute: '/find-id',
                          rightLabel: '비밀번호 찾기',
                          rightRoute: '/find-password',
                        ),
                        const SizedBox(height: 28),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: ChowColors.gray300, height: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text('또는', style: TextStyle(fontSize: 14, color: ChowColors.gray500)),
                            ),
                            Expanded(child: Divider(color: ChowColors.gray300, height: 1)),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _SocialButton(
                          onPressed: _handleGoogleLogin,
                          backgroundColor: Colors.white,
                          foregroundColor: ChowColors.gray700,
                          borderColor: ChowColors.gray300,
                          icon: const _GoogleIcon(),
                          label: 'Google로 로그인',
                        ),
                        const SizedBox(height: 12),
                        _SocialButton(
                          onPressed: _handleKakaoLogin,
                          backgroundColor: ChowColors.kakaoYellow,
                          foregroundColor: Colors.black,
                          icon: const _KakaoIcon(),
                          label: '카카오로 로그인',
                        ),
                        const SizedBox(height: 28),
                        Text.rich(
                          TextSpan(
                            text: '아직 회원이 아니신가요? ',
                            style: const TextStyle(fontSize: 14, color: ChowColors.gray600),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => context.push('/signup'),
                                  child: const Text(
                                    '회원가입',
                                    style: TextStyle(
                                      color: Color(0xFFFF7000),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이미지와 동일: 오렌지 원 + 검은 발바닥 2개
class _PawLogo extends StatelessWidget {
  const _PawLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFFF7000),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33FF7000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Center(child: _DoublePawPrints()),
    );
  }
}

class _DoublePawPrints extends StatelessWidget {
  const _DoublePawPrints();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 2, top: 6, child: _singlePaw(0.85)),
          Positioned(right: 2, top: 2, child: Transform.rotate(angle: 0.25, child: _singlePaw(0.9))),
        ],
      ),
    );
  }

  Widget _singlePaw(double scale) {
    return Transform.scale(
      scale: scale,
      child: const Icon(Icons.pets, color: Color(0xFF2D2D2D), size: 26),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFF7000),
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onPressed != null ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    this.borderColor,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget icon;
  final String label;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
            color: backgroundColor,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: foregroundColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleMarkPainter()));
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(w * 0.45, 0, w * 0.55, h * 0.45), p);
    p.color = const Color(0xFF34A853);
    canvas.drawRect(Rect.fromLTWH(w * 0.45, h * 0.55, w * 0.55, h * 0.45), p);
    p.color = const Color(0xFFFBBC05);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.45, w * 0.45, h * 0.2), p);
    p.color = const Color(0xFFEA4335);
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.45, h * 0.55), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KakaoIcon extends StatelessWidget {
  const _KakaoIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _KakaoBubblePainter()),
    );
  }
}

class _KakaoBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.08, size.width * 0.95, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.82, size.width * 0.5, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.05, size.height * 0.82, size.width * 0.05, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.05, size.height * 0.08, size.width * 0.5, size.height * 0.08)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.72), size.width * 0.06, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
