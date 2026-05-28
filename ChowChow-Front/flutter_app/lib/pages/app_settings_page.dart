import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('앱 설정'),
      ),
      body: ListView(
        children: [
          _section(
            '계정 관리',
            [
              _tile(context, '비밀번호 찾기', '비밀번호를 재설정하세요', Icons.lock_outline, () => context.push('/find-password')),
              _tile(context, '비밀번호 변경', '새로운 비밀번호로 변경하세요', Icons.lock_reset_outlined, () => context.push('/change-password')),
            ],
          ),
          _section(
            '앱',
            [
              _tile(context, '알림 설정', '푸시 알림 및 이메일 알림 관리', Icons.notifications_none, () => context.push('/notification-settings')),
            ],
          ),
          _section(
            '기타',
            [
              _tile(context, '회원 탈퇴', '계정을 영구적으로 삭제합니다', Icons.delete_forever_outlined, () {}, danger: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(title, style: const TextStyle(fontSize: 13, color: ChowColors.gray500)),
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String label,
    String desc,
    IconData icon,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final c = danger ? ChowColors.red500 : ChowColors.gray800;
    return ListTile(
      leading: Icon(icon, color: danger ? ChowColors.red500 : ChowColors.gray600),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
      trailing: const Icon(Icons.chevron_right, color: ChowColors.gray400),
      onTap: onTap,
    );
  }
}