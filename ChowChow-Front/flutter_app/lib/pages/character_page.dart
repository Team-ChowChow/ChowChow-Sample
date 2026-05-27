import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/chow_theme.dart';

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> with TickerProviderStateMixin {
  int level = 12;
  int exp = 750;
  int maxExp = 1000;
  int health = 85;
  int happiness = 92;
  int hunger = 45;

  bool _isInteracting = false;
  final List<_Particle> _particles = [];
  final _random = Random();

  late final AnimationController _idleCtrl;
  late final AnimationController _interactCtrl;
  late final Animation<double> _idleScale;
  late final Animation<double> _idleRotate;

  _InteractAnim _interactAnim = _InteractAnim.bounce;

  static const _activities = [
    _ActivityData(Icons.restaurant, '밥주기', 0, ChowColors.orange500, '🍖'),
    _ActivityData(Icons.favorite, '쓰다듬기', 0, ChowColors.pink500, '💕'),
    _ActivityData(Icons.fitness_center, '운동하기', 50, Color(0xFF3B82F6), '💪'),
    _ActivityData(Icons.auto_awesome, '목욕시키기', 100, ChowColors.purple500, '✨'),
  ];

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _idleScale = Tween<double>(begin: 1, end: 1.05).animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));
    _idleRotate = Tween<double>(begin: -0.035, end: 0.035).animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));
    _interactCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _interactCtrl.dispose();
    super.dispose();
  }

  double get _expFrac => exp / maxExp;

  ({double dy, double scale, double rotate}) _interactTransform(double t) {
    switch (_interactAnim) {
      case _InteractAnim.bounce:
        final y = t < 0.5 ? -40 * sin(t * pi) : -10 * (1 - t);
        return (dy: y, scale: 1 + 0.1 * sin(t * pi), rotate: 0.17 * sin(t * pi * 2));
      case _InteractAnim.shake:
        return (dy: 0, scale: 1, rotate: 0,);
      case _InteractAnim.scale:
        return (dy: 0, scale: 1 + 0.15 * sin(t * pi), rotate: 0);
      case _InteractAnim.wiggle:
        return (dy: -8 * sin(t * pi * 4), scale: 1, rotate: 0.12 * sin(t * pi * 4));
    }
  }

  Future<void> _runInteract(_InteractAnim anim, {Duration? duration, VoidCallback? onDone}) async {
    if (_isInteracting) return;
    setState(() => _isInteracting = true);
    _idleCtrl.stop();
    _interactAnim = anim;
    _interactCtrl.duration = duration ?? const Duration(milliseconds: 600);
    await _interactCtrl.forward(from: 0);
    onDone?.call();
    if (mounted) {
      setState(() => _isInteracting = false);
      _idleCtrl.repeat(reverse: true);
    }
  }

  Future<void> _handlePetClick() async {
    await _runInteract(_InteractAnim.bounce, onDone: () {
      _spawnParticles(['💕', '❤️', '💖', '✨'], count: 6);
      happiness = (happiness + 5).clamp(0, 100);
    });
    setState(() {});
  }

  Future<void> _handleActivity(_ActivityData activity) async {
    switch (activity.label) {
      case '밥주기':
        await _runInteract(_InteractAnim.wiggle, duration: const Duration(milliseconds: 500), onDone: () {
          hunger = (hunger - 20).clamp(0, 100);
          health = (health + 5).clamp(0, 100);
        });
      case '쓰다듬기':
        await _runInteract(_InteractAnim.scale, duration: const Duration(milliseconds: 400), onDone: () {
          happiness = (happiness + 10).clamp(0, 100);
        });
      case '운동하기':
        await _runInteract(_InteractAnim.shake, duration: const Duration(milliseconds: 1000), onDone: () {
          health = (health + 10).clamp(0, 100);
          hunger = (hunger + 10).clamp(0, 100);
        });
      case '목욕시키기':
        await _runInteract(_InteractAnim.wiggle, duration: const Duration(milliseconds: 800), onDone: () {
          happiness = (happiness + 15).clamp(0, 100);
        });
    }
    _spawnParticles([activity.emoji], count: 8);
    setState(() {});
  }

  void _spawnParticles(List<String> emojis, {required int count}) {
    final batch = List<_Particle>.generate(count, (i) {
      return _Particle(
        id: DateTime.now().millisecondsSinceEpoch + i,
        emoji: emojis[_random.nextInt(emojis.length)],
        dx: _random.nextDouble() * 200 - 100,
        dy: _random.nextDouble() * 200 - 100,
      );
    });
    setState(() => _particles.addAll(batch));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _particles.removeWhere((p) => batch.any((b) => b.id == p.id)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEDD5), Color(0xFFFFF7ED)],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: ChowColors.gray200)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('캐릭터 키우기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ChowColors.gray800)),
                    SizedBox(height: 4),
                    Text('우리 아이와 함께 성장해요', style: TextStyle(fontSize: 13, color: ChowColors.gray500)),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WhiteCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: ChowColors.orange50, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 16, color: ChowColors.orange500),
                            const SizedBox(width: 6),
                            Text('레벨 $level', style: const TextStyle(fontSize: 13, color: ChowColors.orange600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 192,
                        height: 192,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedBuilder(
                              animation: Listenable.merge([_idleCtrl, _interactCtrl]),
                              builder: (context, child) {
                                final t = _interactCtrl.value;
                                final usingInteract = _isInteracting || t > 0;
                                final tr = usingInteract ? _interactTransform(t) : (dy: 0.0, scale: _idleScale.value, rotate: _idleRotate.value);
                                var dx = 0.0;
                                if (usingInteract && _interactAnim == _InteractAnim.shake) {
                                  dx = 20 * sin(t * pi * 8);
                                }
                                return Transform.translate(
                                  offset: Offset(dx, tr.dy),
                                  child: Transform.rotate(
                                    angle: tr.rotate,
                                    child: Transform.scale(scale: tr.scale, child: child),
                                  ),
                                );
                              },
                              child: GestureDetector(
                                onTap: _handlePetClick,
                                child: Container(
                                  width: 192,
                                  height: 192,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFFED7AA), Color(0xFFFDBA74)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('🐶', style: TextStyle(fontSize: 72)),
                                ),
                              ),
                            ),
                            ..._particles.map(_ParticleWidget.new),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('초코', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                      const Text('건강한 골든 리트리버', style: TextStyle(fontSize: 13, color: ChowColors.gray500)),
                      const SizedBox(height: 8),
                      const Text('👆 클릭해서 쓰다듬어 주세요!', style: TextStyle(fontSize: 12, color: ChowColors.orange500)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('경험치', style: TextStyle(fontSize: 13, color: ChowColors.gray600)),
                          Text('$exp / $maxExp', style: const TextStyle(fontSize: 13, color: ChowColors.gray800, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 12,
                          child: Stack(
                            children: [
                              Container(color: ChowColors.gray200),
                              FractionallySizedBox(
                                widthFactor: _expFrac.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [ChowColors.orange400, ChowColors.orange500]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatRow(icon: Icons.favorite, iconBg: Color(0xFFFEE2E2), iconColor: ChowColors.red500, label: '건강', value: health, barColor: ChowColors.red500),
                      const SizedBox(height: 10),
                      _StatRow(icon: Icons.auto_awesome, iconBg: Color(0xFFFEF9C3), iconColor: ChowColors.yellow500, label: '행복', value: happiness, barColor: ChowColors.yellow500),
                      const SizedBox(height: 10),
                      _StatRow(icon: Icons.restaurant, iconBg: ChowColors.orange100, iconColor: ChowColors.orange500, label: '배고픔', value: hunger, barColor: ChowColors.orange500),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('활동', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.15,
                        children: _activities.map((a) => _ActivityTile(activity: a, onTap: () => _handleActivity(a))).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 업적', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                      SizedBox(height: 12),
                      _AchievementRow(emoji: '🏆', title: '첫 식단 완료', date: '2026.03.20', bg: ChowColors.orange50, circle: ChowColors.orange500),
                      SizedBox(height: 10),
                      _AchievementRow(emoji: '⭐', title: '7일 연속 접속', date: '2026.03.18', bg: Color(0xFFEFF6FF), circle: Color(0xFF3B82F6)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

enum _InteractAnim { bounce, shake, scale, wiggle }

class _ActivityData {
  const _ActivityData(this.icon, this.label, this.cost, this.color, this.emoji);
  final IconData icon;
  final String label;
  final int cost;
  final Color color;
  final String emoji;
}

class _Particle {
  _Particle({required this.id, required this.emoji, required this.dx, required this.dy});
  final int id;
  final String emoji;
  final double dx;
  final double dy;
}

class _ParticleWidget extends StatefulWidget {
  const _ParticleWidget(this.particle);
  final _Particle particle;

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_ctrl.value);
        final scale = t < 0.5 ? t * 3 : (1 - t) * 3;
        return Positioned(
          left: 96 + widget.particle.dx * t,
          top: 96 + widget.particle.dy * t,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(scale: scale.clamp(0.0, 1.5), child: child),
          ),
        );
      },
      child: Text(widget.particle.emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(blurRadius: 10, offset: Offset(0, 3), color: Color(0x14000000))],
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.barColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final int value;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 40, child: Text(label, style: const TextStyle(fontSize: 13, color: ChowColors.gray700))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: ChowColors.gray200),
                  FractionallySizedBox(widthFactor: (value / 100).clamp(0.0, 1.0), child: Container(color: barColor)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text('$value%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: ChowColors.gray700)),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.onTap});
  final _ActivityData activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChowColors.gray50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: activity.color, borderRadius: BorderRadius.circular(12)),
                child: Icon(activity.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 8),
              Text(activity.label, style: const TextStyle(fontSize: 13, color: ChowColors.gray800, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                activity.cost > 0 ? '🪙 ${activity.cost}' : '무료',
                style: TextStyle(fontSize: 11, color: activity.cost > 0 ? ChowColors.orange600 : ChowColors.green500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.emoji,
    required this.title,
    required this.date,
    required this.bg,
    required this.circle,
  });

  final String emoji;
  final String title;
  final String date;
  final Color bg;
  final Color circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: ChowColors.gray800, fontWeight: FontWeight.w500)),
                Text(date, style: const TextStyle(fontSize: 11, color: ChowColors.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
