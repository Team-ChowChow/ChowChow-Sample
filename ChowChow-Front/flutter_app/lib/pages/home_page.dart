import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _slideIndex = 0;
  Timer? _autoTimer;

  List<RecipeModel> _recipes = [];
  bool _loading = true;

  String _tipText = '';
  String _tipDetail = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadRecipes();
    _loadTip();
  }

  Future<void> _loadTip() async {
    try {
      final res = await ApiClient.get('/api/llm/tip') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _tipText = res['tip'] as String? ?? '';
          _tipDetail = res['detail'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecipes() async {
    try {
      final res = await ApiClient.get(
        '/api/v1/recipes/trending',
        query: {'limit': '6'},
        auth: false,
      ) as Map<String, dynamic>;
      final list = (res['data'] as List<dynamic>? ?? [])
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _recipes = list;
        _loading = false;
      });
      if (list.isNotEmpty) {
        _startAutoSlide();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startAutoSlide() {
    _autoTimer?.cancel();
    if (_recipes.length <= 1) return;

    _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _moveSlide(1, fromUser: false);
    });
  }

  void _moveSlide(int direction, {required bool fromUser}) {
    if (!mounted || !_pageController.hasClients || _recipes.isEmpty) return;

    final next = (_slideIndex + direction) % _recipes.length;
    final target = next < 0 ? _recipes.length - 1 : next;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );

    if (fromUser) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChowColors.gray50,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '트렌드 레시피',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ChowColors.gray800,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _recipes.isEmpty
                              ? const Center(child: Text('레시피가 없습니다.'))
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Listener(
                                      onPointerDown: (_) =>
                                          _autoTimer?.cancel(),
                                      onPointerUp: (_) => _startAutoSlide(),
                                      onPointerCancel: (_) => _startAutoSlide(),
                                      child: ScrollConfiguration(
                                        behavior:
                                            const _CarouselScrollBehavior(),
                                        child: PageView.builder(
                                          controller: _pageController,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount: _recipes.length,
                                          onPageChanged: (i) {
                                            setState(() => _slideIndex = i);
                                          },
                                          itemBuilder: (context, i) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              child: _TrendingCard(
                                                recipe: _recipes[i],
                                                onTap: () => context.push(
                                                  '/recipes/${_recipes[i].recipeId}',
                                                  extra: _recipes[i],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_recipes.length > 1) ...[
                                      Positioned(
                                        left: 22,
                                        child: _SlideControlButton(
                                          icon: Icons.chevron_left,
                                          onTap: () => _moveSlide(
                                            -1,
                                            fromUser: true,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 22,
                                        child: _SlideControlButton(
                                          icon: Icons.chevron_right,
                                          onTap: () => _moveSlide(
                                            1,
                                            fromUser: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_recipes.length, (i) {
                        final active = i == _slideIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? ChowCozy.stone500
                                : ChowColors.gray300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _AiChefBanner(
                        onTap: () => context.push('/recipe-generation'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '급여',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ChowColors.gray800,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _FeedingEntryRow(
                            icon: Icons.calculate_outlined,
                            title: '급여량 계산기',
                            subtitle: '먹는 사료를 고르고 오늘의 식단을 기록해보세요',
                            onTap: () => context.push('/feeding-guideline'),
                          ),
                          const SizedBox(height: 10),
                          _FeedingEntryRow(
                            icon: Icons.inventory_2_outlined,
                            title: '사료 정보',
                            subtitle: '사료별 칼로리·영양 성분을 검색해보세요',
                            onTap: () => context.push('/food-info'),
                          ),
                          const SizedBox(height: 10),
                          _FeedingEntryRow(
                            icon: Icons.sync_alt,
                            title: '사료 교체 가이드',
                            subtitle: 'AI가 두 사료의 배합 비율을 단계별로 추천해드려요',
                            onTap: () => context.push('/food-transition-guide'),
                          ),
                          const SizedBox(height: 10),
                          _FeedingEntryRow(
                            icon: Icons.menu_book_outlined,
                            title: '식단 기록',
                            subtitle: '직접 만든 식단과 레시피를 모아보세요',
                            onTap: () => context.push('/diet-log'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '오늘의 팁',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ChowColors.gray800,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [ChowColors.blue500, ChowColors.purple500],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 건강 정보',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tipText.isNotEmpty ? _tipText : '반려동물에게 신선한 물을 매일 충분히 제공하세요.',
                              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                            ),
                            if (_tipDetail.isNotEmpty)
                              TextButton(
                                onPressed: () => context.push('/tip-detail', extra: {'tip': _tipText, 'detail': _tipDetail}),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white.withValues(alpha: 0.9),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('더 알아보기', style: TextStyle(decoration: TextDecoration.underline)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatefulWidget {
  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  List<_HeaderNotice> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await ApiClient.get('/api/notifications') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _notifications = res.map((e) {
          final m = e as Map<String, dynamic>;
          final createdAt = m['createdAt'] as String?;
          String timeStr = '';
          if (createdAt != null) {
            try {
              final dt = DateTime.parse(createdAt).toLocal();
              final diff = DateTime.now().difference(dt);
              if (diff.inMinutes < 60) {
                timeStr = '${diff.inMinutes}분 전';
              } else if (diff.inHours < 24) {
                timeStr = '${diff.inHours}시간 전';
              } else {
                timeStr = '${diff.inDays}일 전';
              }
            } catch (_) {}
          }
          return _HeaderNotice(
            type: m['notificationType'] as String? ?? 'notice',
            title: m['notificationTitle'] as String? ?? m['title'] as String? ?? '알림',
            message: m['notificationContent'] as String? ?? m['message'] as String? ?? '',
            time: timeStr,
            isNew: !(m['isRead'] as bool? ?? false),
          );
        }).toList();
      });
    } catch (_) {}
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ChowColors.gray300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Text(
                          '알림',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: ChowColors.gray500),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_none, size: 48, color: ChowColors.gray300),
                                SizedBox(height: 12),
                                Text('알림이 없어요', style: TextStyle(color: ChowColors.gray500, fontSize: 15)),
                              ],
                            ),
                          )
                        : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (a, b) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return Material(
                          color: item.isNew ? const Color(0xFFFDF7EA) : Colors.white,
                          child: InkWell(
                            onTap: () {
                              if (!item.isNew) return;
                              setModalState(() {
                                _notifications[index] = item.copyWith(isNew: false);
                              });
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _noticeBg(item.type),
                                    child: Icon(_noticeIcon(item.type), color: _noticeFg(item.type), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: ChowColors.gray800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.message,
                                          style: const TextStyle(fontSize: 12, color: ChowColors.gray600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.time,
                                          style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 12,
                                    child: Center(
                                      child: item.isNew
                                          ? Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: ChowCozy.stone500,
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _noticeIcon(String type) {
    switch (type) {
      case 'recipe':
        return Icons.restaurant_menu;
      case 'achievement':
        return Icons.auto_awesome;
      case 'community':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _noticeBg(String type) {
    switch (type) {
      case 'recipe':
        return ChowCozy.stone300;
      case 'achievement':
        return const Color(0xFFFDF2C9);
      case 'community':
        return const Color(0xFFDBEAFE);
      default:
        return ChowColors.gray100;
    }
  }

  Color _noticeFg(String type) {
    switch (type) {
      case 'recipe':
        return ChowCozy.stone500;
      case 'achievement':
        return ChowColors.yellow600;
      case 'community':
        return ChowColors.blue500;
      default:
        return ChowColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Text(
                '멍냥밥상',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ChowCozy.secondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _openNotifications,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, color: ChowColors.gray700, size: 26),
                    if (_notifications.any((e) => e.isNew))
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: ChowCozy.stone500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselScrollBehavior extends MaterialScrollBehavior {
  const _CarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _SlideControlButton extends StatelessWidget {
  const _SlideControlButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.recipe,
    required this.onTap,
  });

  final RecipeModel recipe;
  final VoidCallback onTap;

  static const _placeholder =
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=600&q=80';

  @override
  Widget build(BuildContext context) {
    final tags = [
      if (recipe.petType == 'DOG') '🐶 강아지',
      if (recipe.petType == 'CAT') '🐱 고양이',
      if (recipe.menuCategory != null) recipe.menuCategory!,
    ];
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChowNetworkImage(url: recipe.imageUrl ?? _placeholder),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.recipeTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChefBanner extends StatelessWidget {
  const _AiChefBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ChowCozy.secondary, ChowCozy.primary],
        ),
        boxShadow: const [
          BoxShadow(blurRadius: 12, offset: Offset(0, 4), color: Color(0x33000000)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.chat_bubble_outline, size: 72, color: Colors.white.withValues(alpha: 0.2)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('AI 셰프', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '우리 아이 맞춤 식단을\nAI가 추천해드려요',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
              ),
              const SizedBox(height: 8),
              Text(
                '반려동물의 건강 상태, 알러지, 선호도를 고려한 맞춤 레시피',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ChowCozy.secondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: const StadiumBorder(),
                ),
                child: const Text('AI 레시피 생성'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderNotice {
  const _HeaderNotice({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isNew,
  });

  final String type;
  final String title;
  final String message;
  final String time;
  final bool isNew;

  _HeaderNotice copyWith({
    String? type,
    String? title,
    String? message,
    String? time,
    bool? isNew,
  }) {
    return _HeaderNotice(
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isNew: isNew ?? this.isNew,
    );
  }
}

class _FeedingEntryRow extends StatelessWidget {
  const _FeedingEntryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ChowCozy.stone300),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ChowCozy.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ChowCozy.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ChowColors.gray800,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: ChowColors.gray500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ChowColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
