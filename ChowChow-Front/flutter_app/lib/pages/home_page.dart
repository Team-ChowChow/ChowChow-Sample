import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final res = await ApiClient.get(
        '/api/v1/recipes',
        query: {'size': '8', 'page': '0', 'sort': 'recipeId,desc'},
      ) as Map<String, dynamic>;
      final list = (res['data'] as List<dynamic>? ?? [])
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() { _recipes = list; _loading = false; });
      if (list.isNotEmpty) {
        _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          if (!mounted || !_pageController.hasClients || _recipes.isEmpty) return;
          final next = (_slideIndex + 1) % _recipes.length;
          _pageController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
                    const SizedBox(height: 24),
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
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: _recipes.length,
                                  onPageChanged: (i) => setState(() => _slideIndex = i),
                                  itemBuilder: (context, i) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: _TrendingCard(recipe: _recipes[i]),
                                    );
                                  },
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
                                ? ChowColors.orange500
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
                        onTap: () => context.push('/recipe-generation?quickStart=true'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '나의 식단 기록',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ChowColors.gray800,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              '전체보기',
                              style: TextStyle(
                                color: ChowColors.orange500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _recipes.take(4).length,
                        itemBuilder: (context, i) => _RecipeCard(recipe: _recipes[i]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(96),
                          side: const BorderSide(color: ChowColors.gray300, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: ChowColors.gray600,
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 32, color: ChowColors.gray400),
                            SizedBox(height: 8),
                            Text('식단 사진 추가하기', style: TextStyle(fontSize: 14)),
                          ],
                        ),
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
                            const Text(
                              '반려견에게 양파, 마늘, 포도는 절대 급여하지 마세요. 중독 증상을 유발할 수 있습니다.',
                              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                            ),
                            TextButton(
                              onPressed: () {},
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
  final List<_HeaderNotice> _notifications = [
    const _HeaderNotice(
      type: 'recipe',
      title: '새로운 레시피가 등록되었어요!',
      message: '초코가 좋아할 만한 닭가슴살 요리',
      time: '5분 전',
      isNew: true,
    ),
    const _HeaderNotice(
      type: 'achievement',
      title: '축하합니다! 🎉',
      message: '7일 연속 접속 달성',
      time: '1시간 전',
      isNew: true,
    ),
    const _HeaderNotice(
      type: 'community',
      title: '멍멍이엄마님이 댓글을 남겼어요',
      message: '"정말 유용한 레시피네요!"',
      time: '2시간 전',
      isNew: false,
    ),
    const _HeaderNotice(
      type: 'system',
      title: '식단 기록 알림',
      message: '오늘 초코의 식단을 기록해주세요',
      time: '어제',
      isNew: false,
    ),
  ];

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
                    child: ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
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
                                                color: ChowColors.orange500,
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
        return ChowColors.orange100;
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
        return ChowColors.orange500;
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
                '펫푸드 레시피',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ChowColors.orange500,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {},
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [ChowColors.yellow400, ChowColors.yellow500],
                      ),
                      boxShadow: const [
                        BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x22000000)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Text('C', style: TextStyle(fontSize: 11, color: ChowColors.yellow600, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 8),
                        Text('1,250', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                            color: ChowColors.orange500,
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

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.recipe});

  final RecipeModel recipe;

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
          colors: [ChowColors.orange400, ChowColors.orange500],
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
                  foregroundColor: ChowColors.orange500,
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

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipeModel recipe;

  static const _placeholder =
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=600&q=80';

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ChowNetworkImage(url: recipe.imageUrl ?? _placeholder),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.favorite_border, size: 18, color: ChowColors.gray600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.recipeTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: ChowColors.gray800, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.menuCategory ?? recipe.recipePurpose ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: ChowColors.gray500),
                ),
              ],
            ),
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
