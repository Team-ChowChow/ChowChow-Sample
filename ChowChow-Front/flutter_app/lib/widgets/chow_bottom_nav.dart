import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';

/// 5칸 그리드 + 가운데 떠 있는 캐릭터 버튼 (hover:scale-105 → 탭 시 스케일 애니메이션)
class ChowBottomNav extends StatefulWidget {
  const ChowBottomNav({super.key, required this.currentPath});

  final String currentPath;

  @override
  State<ChowBottomNav> createState() => _ChowBottomNavState();
}

class _ChowBottomNavState extends State<ChowBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _fabScale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  bool _active(String path) => widget.currentPath == path;

  Future<void> _pulseFab() async {
    await _fabCtrl.forward();
    await _fabCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    const protrusion = 28.0;
    final barHeight = 60 + bottom;

    return SizedBox(
      height: protrusion + barHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: protrusion,
            left: 0,
            right: 0,
            height: barHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: ChowCozy.card,
                border: Border(top: BorderSide(color: ChowCozy.border)),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 6,
                    bottom: bottom + 6,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _NavItem(
                          active: _active('/'),
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: '홈',
                          onTap: () => context.go('/'),
                          align: CrossAxisAlignment.center,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          active: _active('/search'),
                          icon: Icons.search,
                          activeIcon: Icons.search,
                          label: '검색',
                          filled: true,
                          onTap: () => context.go('/search'),
                          align: CrossAxisAlignment.center,
                        ),
                      ),

                      // 가운데 발바닥 버튼 자리
                      const Expanded(child: SizedBox()),

                      Expanded(
                        child: _NavItem(
                          active: _active('/community'),
                          icon: Icons.groups_outlined,
                          activeIcon: Icons.groups,
                          label: '커뮤니티',
                          filled: true,
                          onTap: () => context.go('/community'),
                          align: CrossAxisAlignment.center,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          active: _active('/profile'),
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: '프로필',
                          onTap: () => context.go('/profile'),
                          align: CrossAxisAlignment.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: ScaleTransition(
              scale: _fabScale,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      color: Color(0x33000000),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      await _pulseFab();
                      if (context.mounted) context.go('/character');
                    },
                    child: Ink(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/images/pet_home_icon.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.active,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    required this.align,
    this.filled = false,
  });

  final bool active;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final CrossAxisAlignment align;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = active ? ChowCozy.primary : ChowCozy.mutedForeground;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            active ? activeIcon : icon,
            size: 26,
            color: color,
            fill: filled && active ? 1.0 : null,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, height: 1),
          ),
        ],
      ),
    );
  }
}
