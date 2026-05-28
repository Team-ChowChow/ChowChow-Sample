import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'constants/phone_size.dart';
import 'router/app_router.dart';
import 'services/api_client.dart';
import 'theme/chow_theme.dart';
import 'widgets/phone_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await ApiClient.isLoggedIn();
  runApp(ChowChowApp(initialLocation: loggedIn ? '/' : '/login'));
}

class ChowChowApp extends StatelessWidget {
  const ChowChowApp({super.key, required this.initialLocation});

  final String initialLocation;

  static bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(initialLocation: initialLocation);
    return MaterialApp.router(
      title: '펫푸드 레시피',
      debugShowCheckedModeBanner: false,
      theme: buildChowTheme(),
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();

        if (PhoneShell.shouldWrap) {
          return PhoneShell(child: content);
        }

        if (_isWindowsDesktop) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              size: kPhoneLogicalSize,
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.1),
            ),
            child: content,
          );
        }

        return content;
      },
    );
  }
}
