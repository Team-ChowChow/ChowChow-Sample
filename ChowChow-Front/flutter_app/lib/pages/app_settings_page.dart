import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../theme/chow_theme.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  Future<void> _handleWithdraw(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('계정을 영구적으로 삭제합니다.\n정말 탈퇴하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.delete('/api/users/me');
      await ApiClient.clearToken();
      if (context.mounted) context.go('/login');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 탈퇴에 실패했습니다.')),
        );
      }
    }
  }

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
              _tile(context, '회원 탈퇴', '계정을 영구적으로 삭제합니다', Icons.delete_forever_outlined, () => _handleWithdraw(context), danger: true),
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
