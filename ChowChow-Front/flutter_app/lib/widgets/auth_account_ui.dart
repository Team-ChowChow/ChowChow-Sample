import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';

/// 아이디 찾기 · 비밀번호 찾기 · 비밀번호 변경 공통 레이아웃
class AuthAccountScaffold extends StatelessWidget {
  const AuthAccountScaffold({
    super.key,
    required this.title,
    required this.body,
    this.footerLinks,
  });

  final String title;
  final Widget body;
  final Widget? footerLinks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ChowColors.orange50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthPageHeader(title: title),
                body,
                if (footerLinks != null) ...[
                  const SizedBox(height: 24),
                  footerLinks!,
                ],
                const SizedBox(height: 32),
                const AuthCopyright(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: ChowColors.gray700),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ChowColors.gray900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class AuthBrandIcon extends StatelessWidget {
  const AuthBrandIcon({
    super.key,
    this.subtitle,
    this.child,
  });

  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ChowColors.orange400, ChowColors.orange500],
            ),
            boxShadow: [
              BoxShadow(
                color: ChowColors.orange500.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child ??
              const Icon(Icons.pets, color: Colors.white, size: 32),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: ChowColors.gray600),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class AuthLockIcon extends StatelessWidget {
  const AuthLockIcon({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AuthBrandIcon(
      subtitle: subtitle,
      child: const Center(
        child: Text('🔒', style: TextStyle(fontSize: 28)),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.label, this.required = true});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: ChowColors.gray700),
          children: [
            TextSpan(text: label),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: ChowColors.orange500),
              ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.onToggleVisibility,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final VoidCallback? onToggleVisibility;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: ChowColors.gray900),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: ChowColors.gray400),
        filled: true,
        fillColor: enabled ? Colors.white : ChowColors.gray100,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChowColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChowColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChowColors.orange500, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChowColors.gray200),
        ),
        suffixIcon: onToggleVisibility != null
            ? IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: ChowColors.gray400,
                  size: 22,
                ),
              )
            : null,
      ),
    );
  }
}

class AuthDropdownField extends StatelessWidget {
  const AuthDropdownField({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint, style: const TextStyle(color: ChowColors.gray400, fontSize: 15)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChowColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChowColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChowColors.orange500, width: 2),
        ),
      ),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: ChowColors.gray500),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 15))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: enabled
            ? const LinearGradient(colors: [ChowColors.orange400, ChowColors.orange500])
            : null,
        color: enabled ? null : ChowColors.gray300,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: ChowColors.orange500.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSideButton extends StatelessWidget {
  const AuthSideButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (enabled ? ChowColors.orange500 : ChowColors.gray300);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class AuthInfoBox extends StatelessWidget {
  const AuthInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 안전한 비밀번호 만들기:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 8),
          ...[
            '8자 이상 입력해주세요',
            '영문 대소문자, 숫자, 특수문자를 조합해주세요',
            '개인정보(이름, 생년월일 등)는 사용하지 마세요',
          ].map(
            (t) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12)),
                  Expanded(
                    child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFooterLinks extends StatelessWidget {
  const AuthFooterLinks({
    super.key,
    this.leftLabel = '비밀번호 찾기',
    this.leftRoute = '/find-password',
    this.rightLabel = '회원가입',
    this.rightRoute = '/signup',
  });

  final String leftLabel;
  final String leftRoute;
  final String rightLabel;
  final String rightRoute;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.push(leftRoute),
          child: Text(leftLabel, style: const TextStyle(color: ChowColors.gray600, fontSize: 14)),
        ),
        const Text('|', style: TextStyle(color: ChowColors.gray300)),
        TextButton(
          onPressed: () => context.push(rightRoute),
          child: Text(rightLabel, style: const TextStyle(color: ChowColors.gray600, fontSize: 14)),
        ),
      ],
    );
  }
}

class AuthCopyright extends StatelessWidget {
  const AuthCopyright({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '© 2026 펫푸드 레시피. All rights reserved.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: ChowColors.gray400),
    );
  }
}
