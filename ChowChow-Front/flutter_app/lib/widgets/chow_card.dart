import 'package:flutter/material.dart';

import '../theme/chow_theme.dart';

/// 급여 관련 페이지들(계산기/사료정보/교체가이드/식단기록)에서 공통으로 쓰는 카드 컨테이너.
class ChowCard extends StatelessWidget {
  const ChowCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChowCozy.stone300),
      ),
      child: child,
    );
  }
}
