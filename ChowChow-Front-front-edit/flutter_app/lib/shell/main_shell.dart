import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/chow_bottom_nav.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: ChowBottomNav(currentPath: path),
    );
  }
}
