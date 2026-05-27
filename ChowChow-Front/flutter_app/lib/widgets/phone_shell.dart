import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../constants/phone_size.dart';

/// 390×844 모바일 프레임 (웹·데스크톱 미리보기)
class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key, required this.child});

  final Widget child;

  static bool get shouldWrap => kIsWeb;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: Container(
          width: kPhoneLogicalSize.width,
          height: kPhoneLogicalSize.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD1D5DB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: kPhoneLogicalSize,
              padding: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
