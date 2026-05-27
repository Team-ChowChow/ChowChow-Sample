import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  List<PetModel> _pets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/api/users/me'),
        ApiClient.get('/api/pets'),
      ]);
      if (!mounted) return;
      setState(() {
        _user = UserModel.fromJson(results[0] as Map<String, dynamic>);
        _pets = (results[1] as List<dynamic>)
            .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLogout() async {
    try { await ApiClient.post('/api/auth/logout', {}, auth: true); } catch (_) {}
    await ApiClient.clearToken();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final userName = _user?.displayName ?? '사용자';
    final userEmail = _user?.authEmail ?? '';

    return ColoredBox(
      color: ChowColors.gray50,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ChowColors.orange500, ChowColors.orange400],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 36),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: const Text('👤', style: TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text(userEmail, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.push('/app-settings'),
                              icon: const Icon(Icons.settings_outlined, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(child: _StatTile(icon: Icons.favorite_border, value: '-', label: '저장한 레시피')),
                            SizedBox(width: 10),
                            Expanded(child: _StatTile(icon: Icons.emoji_events_outlined, value: '-', label: '조리 완료')),
                            SizedBox(width: 10),
                            Expanded(child: _StatTile(icon: Icons.menu_book_outlined, value: '-', label: '작성한 리뷰')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -22),
                    child: Material(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      elevation: 1,
                      shadowColor: Colors.black12,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('우리 아이들', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: ChowColors.gray800)),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('+ 추가하기', style: TextStyle(color: ChowColors.orange500, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_pets.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text('등록된 반려동물이 없습니다.', style: TextStyle(color: ChowColors.gray500))),
                              )
                            else
                              ..._pets.map((pet) => _PetRow(pet: pet)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          SliverToBoxAdapter(child: _MenuSection(title: '계정', items: [
            _MenuItem(label: '알림 설정', icon: Icons.notifications_none, badge: '3', onTap: () {}),
            _MenuItem(label: '개인정보 보호', icon: Icons.shield_outlined, onTap: () {}),
            _MenuItem(
              label: '앱 설정',
              icon: Icons.settings_outlined,
              onTap: () => context.push('/app-settings'),
            ),
          ])),
          SliverToBoxAdapter(
            child: _MenuSection(
              title: '지원',
              items: [
                _MenuItem(
                  label: 'AI 셰프 상담',
                  icon: Icons.chat_bubble_outline,
                  onTap: () => context.push('/ai-chat'),
                ),
                _MenuItem(label: '도움말 & FAQ', icon: Icons.help_outline, onTap: () {}),
                _MenuItem(label: '고객 지원', icon: Icons.support_agent_outlined, onTap: () {}),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('펫푸드 레시피 v1.0.0', style: TextStyle(fontSize: 13, color: ChowColors.gray500)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('이용약관', style: TextStyle(fontSize: 13, color: ChowColors.gray500))),
                      const Text('|', style: TextStyle(color: ChowColors.gray300)),
                      TextButton(onPressed: () {}, child: const Text('개인정보처리방침', style: TextStyle(fontSize: 13, color: ChowColors.gray500))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ChowColors.red500,
                  side: BorderSide.none,
                  backgroundColor: Colors.transparent,
                ),
                icon: const Icon(Icons.logout, color: ChowColors.red500),
                label: const Text('로그아웃'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
        ],
      ),
    );
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({required this.pet});

  final PetModel pet;

  static const _placeholder =
      'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=400&q=80';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ChowColors.gray50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ChowNetworkImage(url: pet.petProfileImg ?? _placeholder),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pet.petName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                                Text(
                                  '${pet.breedName ?? pet.displayType}${pet.petBirthdate != null ? ' • ${pet.petBirthdate!.substring(0, 4)}년생' : ''}',
                                  style: const TextStyle(fontSize: 13, color: ChowColors.gray500),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: ChowColors.gray400),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (pet.petWeight != null)
                        Text('체중: ${pet.petWeight!.toStringAsFixed(1)}kg', style: const TextStyle(fontSize: 11, color: ChowColors.gray600)),
                      Text(pet.displayType, style: const TextStyle(fontSize: 11, color: ChowColors.orange600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: ChowColors.gray500)),
          const SizedBox(height: 6),
          ...items,
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ChowColors.gray600),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: ChowColors.gray800))),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: ChowColors.orange500, borderRadius: BorderRadius.circular(999)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            const Icon(Icons.chevron_right, color: ChowColors.gray400),
          ],
        ),
      ),
    );
  }
}
