import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    this.initialRecipe,
  });

  final int recipeId;
  final RecipeModel? initialRecipe;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  bool _loading = true;
  bool _isSaved = false;
  bool _isLiked = false;
  int _likeCount = 0;
  _RecipeDetailTab _activeTab = _RecipeDetailTab.recipe;
  _RecipeDetailData? _recipe;
  List<_RelatedRecipe> _similarRecipes = const [];
  List<_Review> _reviews = [];

  static const _placeholder =
      'https://images.unsplash.com/photo-1588378898429-6950f6b4f72a?auto=format&fit=crop&w=1080&q=80';

  @override
  void initState() {
    super.initState();
    _recipe = _RecipeDetailData.fromRecipeModel(widget.initialRecipe);
    _likeCount = widget.initialRecipe?.likeCount ?? 0;
    _loadRecipe();
    _loadReviews();
  }

  Future<void> _toggleLike() async {
    final newLiked = !_isLiked;
    setState(() => _isLiked = newLiked);
    try {
      final res = await ApiClient.post(
        '/api/v1/recipes/${widget.recipeId}/like', {},
      ) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _isLiked = res['liked'] as bool? ?? newLiked;
        _likeCount = (res['likeCount'] as num?)?.toInt() ?? _likeCount;
      });
    } catch (_) {
      if (mounted) setState(() => _isLiked = !newLiked);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await ApiClient.get('/api/v1/recipes/${widget.recipeId}/reviews') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _reviews = res.map((e) {
          final m = e as Map<String, dynamic>;
          final createdAt = m['createdAt'] as String?;
          final date = createdAt != null ? createdAt.substring(0, 10).replaceAll('-', '.') : '';
          final rawRating = (m['rating'] ?? m['starRating'] as dynamic);
          return _Review(
            author: m['userNickname'] as String? ?? '사용자',
            rating: (rawRating as num?)?.toInt() ?? 5,
            date: date,
            content: m['reviewContent'] as String? ?? '',
            likes: 0,
          );
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _submitReview(int rating, String content) async {
    try {
      await ApiClient.post('/api/v1/recipes/${widget.recipeId}/reviews', {
        'rating': rating.toDouble(),
        'reviewContent': content,
      });
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 등록되었습니다.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 등록에 실패했습니다.')),
        );
      }
    }
  }

  void _openWriteReview() {
    int selectedRating = 5;
    final contentCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: ChowColors.gray300, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 16),
              const Text('리뷰 작성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSheet(() => selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: ChowColors.yellow500,
                      size: 36,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '레시피에 대한 솔직한 리뷰를 남겨주세요...',
                  hintStyle: const TextStyle(color: ChowColors.gray400, fontSize: 14),
                  filled: true,
                  fillColor: ChowColors.gray50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ChowColors.orange500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final text = contentCtrl.text.trim();
                    Navigator.of(ctx).pop();
                    _submitReview(selectedRating, text);
                  },
                  child: const Text('등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadRecipe() async {
    try {
      final res = await ApiClient.get('/api/v1/recipes/${widget.recipeId}')
          as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _recipe = _RecipeDetailData.fromJson(res, fallback: _recipe);
        _likeCount = (res['likeCount'] as num?)?.toInt() ?? _likeCount;
        _isLiked = res['likedByMe'] as bool? ?? _isLiked;
        _loading = false;
      });
      _loadSimilarRecipes();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipe ??= _RecipeDetailData._empty(widget.recipeId);
        _loading = false;
      });
    }
  }

  Future<void> _loadSimilarRecipes() async {
    try {
      final res = await ApiClient.get(
        '/api/v1/recipes/${widget.recipeId}/similar',
        auth: false,
      ) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _similarRecipes = res.map((e) {
          final m = e as Map<String, dynamic>;
          return _RelatedRecipe(
            title: m['recipeTitle'] as String? ?? '',
            imageUrl: m['imageUrl'] as String? ?? _placeholder,
            rating: (m['averageRating'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      });
    } catch (_) {}
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe ?? _RecipeDetailData._empty(widget.recipeId);

    return Scaffold(
      backgroundColor: ChowColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailHeader(onBack: _goBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  _HeroImage(imageUrl: recipe.imageUrl ?? _placeholder),
                  _InstagramActionBar(
                    isLiked: _isLiked,
                    likeCount: _likeCount,
                    isSaved: _isSaved,
                    onToggleLiked: _toggleLike,
                    onToggleSaved: () => setState(() => _isSaved = !_isSaved),
                  ),
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  _TitleSection(recipe: recipe),
                  _StatsSection(recipe: recipe),
                  _InfoSection(recipe: recipe),
                  _DescriptionSection(description: recipe.description),
                  _Tabs(
                    activeTab: _activeTab,
                    reviewCount: recipe.reviewCount,
                    onChanged: (tab) => setState(() => _activeTab = tab),
                  ),
                  if (_activeTab == _RecipeDetailTab.recipe) ...[
                    _IngredientsSection(ingredients: recipe.ingredients),
                    _InstructionsSection(steps: recipe.steps),
                    _NutritionSection(items: recipe.nutrition),
                    _TipsSection(tips: recipe.tips),
                    if (_similarRecipes.isNotEmpty)
                      _RelatedSection(recipes: _similarRecipes),
                    _CookingCompleteButton(
                      recipeTitle: recipe.title,
                      recipeId: widget.recipeId,
                    ),
                  ] else
                    _ReviewsSection(
                      recipe: recipe,
                      reviews: _reviews,
                      onWriteReview: _openWriteReview,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RecipeDetailTab { recipe, reviews }

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: ChowColors.gray700),
            ),
            const Expanded(
              child: Text(
                '레시피',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChowColors.gray900,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.ios_share, color: ChowColors.gray700),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ChowNetworkImage(url: imageUrl),
    );
  }
}

class _InstagramActionBar extends StatelessWidget {
  const _InstagramActionBar({
    required this.isLiked,
    required this.likeCount,
    required this.isSaved,
    required this.onToggleLiked,
    required this.onToggleSaved,
  });

  final bool isLiked;
  final int likeCount;
  final bool isSaved;
  final VoidCallback onToggleLiked;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onToggleLiked,
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isLiked ? ChowColors.red500 : ChowColors.gray800,
                  size: 28,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleSaved,
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? ChowColors.orange500 : ChowColors.gray800,
                  size: 28,
                ),
              ),
            ],
          ),
          if (likeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                '좋아요 $likeCount개',
                style: const TextStyle(
                  color: ChowColors.gray900,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.recipe});

  final _RecipeDetailData recipe;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.title,
            style: const TextStyle(
              color: ChowColors.gray900,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recipe.subtitle,
            style: const TextStyle(color: ChowColors.gray600, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.tags
                .map(
                  (tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: ChowColors.orange50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: ChowColors.orange600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: ChowColors.gray100),
          const SizedBox(height: 14),
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: ChowColors.orange50,
                child: Icon(Icons.pets, color: ChowColors.orange400),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관리자',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ChowColors.gray900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '공식 레시피',
                      style: TextStyle(fontSize: 12, color: ChowColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.recipe});

  final _RecipeDetailData recipe;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      topMargin: 0,
      child: Row(
        children: [
          _StatCell(
            icon: Icons.star,
            value: recipe.rating.toStringAsFixed(1),
            label: '평점',
            iconColor: ChowColors.yellow500,
          ),
          _StatCell(value: '${recipe.reviewCount}', label: '리뷰'),
          _StatCell(value: '${recipe.likes}', label: '좋아요'),
          _StatCell(value: '${recipe.saves}', label: '저장'),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.recipe});

  final _RecipeDetailData recipe;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      topMargin: 0,
      child: Row(
        children: [
          _InfoCell(icon: Icons.schedule, label: '조리시간', value: recipe.cookTime),
          _InfoCell(icon: Icons.group_outlined, label: '분량', value: recipe.servings),
          _InfoCell(icon: Icons.restaurant, label: '난이도', value: recipe.difficulty),
          _InfoCell(icon: Icons.local_fire_department, label: '칼로리', value: recipe.calories),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('레시피 소개'),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: ChowColors.gray700,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.activeTab,
    required this.reviewCount,
    required this.onChanged,
  });

  final _RecipeDetailTab activeTab;
  final int reviewCount;
  final ValueChanged<_RecipeDetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          _TabButton(
            label: '조리법',
            selected: activeTab == _RecipeDetailTab.recipe,
            onTap: () => onChanged(_RecipeDetailTab.recipe),
          ),
          const SizedBox(width: 24),
          _TabButton(
            label: '리뷰 ($reviewCount)',
            selected: activeTab == _RecipeDetailTab.reviews,
            onTap: () => onChanged(_RecipeDetailTab.reviews),
          ),
        ],
      ),
    );
  }
}

class _IngredientsSection extends StatelessWidget {
  const _IngredientsSection({required this.ingredients});

  final List<_Ingredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      topMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('재료 (${ingredients.length}가지)'),
          const SizedBox(height: 12),
          ...ingredients.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ChowColors.gray100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: ChowColors.gray800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    item.amount,
                    style: const TextStyle(
                      color: ChowColors.gray600,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionsSection extends StatelessWidget {
  const _InstructionsSection({required this.steps});

  final List<_RecipeStep> steps;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('조리 방법'),
          const SizedBox(height: 16),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [ChowColors.orange400, ChowColors.orange500],
                      ),
                    ),
                    child: Text(
                      '${step.step}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.description,
                      style: const TextStyle(
                        color: ChowColors.gray700,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  const _NutritionSection({required this.items});

  final List<_NutritionItem> items;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('영양 정보'),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ChowColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: ChowColors.gray600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: ChowColors.gray900,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TipsSection extends StatelessWidget {
  const _TipsSection({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChowColors.orange50,
        border: Border.all(color: ChowColors.orange100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: ChowColors.orange500, size: 18),
              SizedBox(width: 6),
              _SectionTitle('조리 팁'),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(color: ChowColors.orange500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: ChowColors.gray700,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({required this.recipes});

  final List<_RelatedRecipe> recipes;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('비슷한 레시피'),
          const SizedBox(height: 14),
          Row(
            children: recipes
                .map(
                  (recipe) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _RelatedCard(recipe: recipe),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.recipe,
    required this.reviews,
    required this.onWriteReview,
  });

  final _RecipeDetailData recipe;
  final List<_Review> reviews;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      topMargin: 0,
      horizontalPadding: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: ChowColors.gray900,
                      ),
                    ),
                    _StarRow(rating: recipe.rating, size: 16),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.reviewCount}개의 리뷰',
                      style: const TextStyle(
                        color: ChowColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onWriteReview,
                  style: FilledButton.styleFrom(
                    backgroundColor: ChowColors.orange500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('리뷰 작성'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ChowColors.gray100),
          ...reviews.map((review) => _ReviewTile(review: review)),
        ],
      ),
    );
  }
}


class _WhiteSection extends StatelessWidget {
  const _WhiteSection({
    required this.child,
    this.topMargin = 12,
    this.horizontalPadding = 20,
  });

  final Widget child;
  final double topMargin;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: topMargin),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 18),
      child: child,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: const TextStyle(
                  color: ChowColors.gray900,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: ChowColors.gray600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: ChowColors.orange500, size: 21),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: ChowColors.gray600, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ChowColors.gray900, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? ChowColors.orange500 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? ChowColors.orange500 : ChowColors.gray600,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ChowColors.gray900,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.recipe});

  final _RelatedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: ChowNetworkImage(url: recipe.imageUrl),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipe.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ChowColors.gray900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: ChowColors.yellow500, size: 13),
              const SizedBox(width: 3),
              Text(
                recipe.rating.toStringAsFixed(1),
                style: const TextStyle(color: ChowColors.gray600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final _Review review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: ChowColors.gray100,
                child: Icon(Icons.person, color: ChowColors.gray500, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.author,
                            style: const TextStyle(
                              color: ChowColors.gray900,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          review.date,
                          style: const TextStyle(
                            color: ChowColors.gray500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _StarRow(rating: review.rating.toDouble(), size: 13),
                  ],
                ),
              ),
            ],
          ),
          if (review.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 86,
                height: 86,
                child: ChowNetworkImage(url: review.imageUrl!),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            review.content,
            style: const TextStyle(
              color: ChowColors.gray700,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined,
                  color: ChowColors.gray500, size: 15),
              const SizedBox(width: 5),
              Text(
                '도움돼요 ${review.likes}',
                style: const TextStyle(
                  color: ChowColors.gray500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ChowColors.gray100),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.size});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating.floor();
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: filled ? ChowColors.yellow500 : ChowColors.gray300,
          size: size,
        );
      }),
    );
  }
}

class _RecipeDetailData {
  const _RecipeDetailData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    required this.tips,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.likes = 0,
    this.saves = 0,
    this.cookTime = '30분',
    this.servings = '2회분',
    this.difficulty = '보통',
    this.calories = '-',
  });

  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final int likes;
  final int saves;
  final String cookTime;
  final String servings;
  final String difficulty;
  final String calories;
  final List<String> tags;
  final List<_Ingredient> ingredients;
  final List<_RecipeStep> steps;
  final List<_NutritionItem> nutrition;
  final List<String> tips;

  factory _RecipeDetailData.fromRecipeModel(RecipeModel? recipe) {
    if (recipe == null) return _RecipeDetailData._empty(0);
    return _RecipeDetailData(
      id: recipe.recipeId,
      title: recipe.recipeTitle,
      subtitle: recipe.recipePurpose ?? recipe.menuCategory ?? '건강한 맞춤 식단',
      description: recipe.recipeDescription ?? '',
      imageUrl: recipe.imageUrl,
      tags: _buildTags(recipe.petType, recipe.menuCategory, recipe.recipePurpose, isAiGenerated: recipe.isAiGenerated),
      ingredients: const [],
      steps: const [],
      nutrition: const [],
      tips: const [],
      servings: recipe.feedingAmount ?? '-',
    );
  }

  factory _RecipeDetailData.fromJson(
    Map<String, dynamic> json, {
    _RecipeDetailData? fallback,
  }) {
    final base = fallback ?? _RecipeDetailData._empty(json['recipeId'] as int? ?? 0);
    final ingredients = (json['ingredients'] as List<dynamic>?)
            ?.map((item) => _Ingredient.fromJson(item as Map<String, dynamic>))
            .where((item) => item.name.isNotEmpty)
            .toList() ??
        const <_Ingredient>[];
    final steps = (json['steps'] as List<dynamic>?)
            ?.map((item) => _RecipeStep.fromJson(item as Map<String, dynamic>))
            .where((item) => item.description.isNotEmpty)
            .toList() ??
        const <_RecipeStep>[];

    final petType = json['petType'] as String?;
    final category = json['menuCategory'] as String?;
    final purpose = json['recipePurpose'] as String?;

    // 영양정보 파싱
    final nutritionJson = json['nutrition'] as Map<String, dynamic>?;
    final nutritionItems = <_NutritionItem>[];
    if (nutritionJson != null) {
      if (nutritionJson['proteinG'] != null) nutritionItems.add(_NutritionItem(label: '단백질', value: '${(nutritionJson['proteinG'] as num).toStringAsFixed(1)}g'));
      if (nutritionJson['fatG'] != null) nutritionItems.add(_NutritionItem(label: '지방', value: '${(nutritionJson['fatG'] as num).toStringAsFixed(1)}g'));
      if (nutritionJson['carbohydrateG'] != null) nutritionItems.add(_NutritionItem(label: '탄수화물', value: '${(nutritionJson['carbohydrateG'] as num).toStringAsFixed(1)}g'));
      if (nutritionJson['sodiumMg'] != null) nutritionItems.add(_NutritionItem(label: '나트륨', value: '${(nutritionJson['sodiumMg'] as num).toStringAsFixed(0)}mg'));
    }

    // 태그 파싱 (API가 tagNames 리스트 반환 시 우선 사용)
    final apiTags = (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    final builtTags = _buildTags(petType, category, purpose, fallback: base.tags, isAiGenerated: json['isAiGenerated'] as bool? ?? false);

    return _RecipeDetailData(
      id: json['recipeId'] as int? ?? base.id,
      title: json['recipeTitle'] as String? ?? base.title,
      subtitle: purpose ?? category ?? base.subtitle,
      description: json['recipeDescription'] as String? ?? base.description,
      imageUrl: json['imageUrl'] as String? ?? base.imageUrl,
      tags: (apiTags != null && apiTags.isNotEmpty) ? apiTags : builtTags,
      ingredients: ingredients,
      steps: steps,
      nutrition: nutritionItems,
      tips: _tipsFromWarnings(json['warnings'] as String?) ?? const [],
      servings: json['feedingAmount'] as String? ?? base.servings,
      cookTime: json['cookTime'] as String? ?? base.cookTime,
      difficulty: json['difficulty'] as String? ?? base.difficulty,
      calories: json['calories'] as String? ?? base.calories,
      rating: (json['averageRating'] as num?)?.toDouble() ?? base.rating,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? base.reviewCount,
      likes: (json['likeCount'] as num?)?.toInt() ?? base.likes,
    );
  }

  factory _RecipeDetailData._empty(int id) {
    return _RecipeDetailData(
      id: id,
      title: '',
      subtitle: '',
      description: '',
      tags: const [],
      ingredients: const [],
      steps: const [],
      nutrition: const [],
      tips: const [],
    );
  }
}

class _Ingredient {
  const _Ingredient({required this.name, required this.amount});

  final String name;
  final String amount;

  factory _Ingredient.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    final unit = json['unit'] as String?;
    final note = json['note'] as String?;
    return _Ingredient(
      name: json['ingredientName'] as String? ?? note ?? '재료',
      amount: [
        if (amount != null) amount.toString(),
        if (unit != null) unit,
      ].join(),
    );
  }
}

class _RecipeStep {
  const _RecipeStep({required this.step, required this.description});

  final int step;
  final String description;

  factory _RecipeStep.fromJson(Map<String, dynamic> json) {
    return _RecipeStep(
      step: json['stepNumber'] as int? ?? 1,
      description: json['stepDescription'] as String? ?? '',
    );
  }
}

class _NutritionItem {
  const _NutritionItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _Review {
  const _Review({
    required this.author,
    required this.rating,
    required this.date,
    required this.content,
    required this.likes,
    this.imageUrl,
  });

  final String author;
  final int rating;
  final String date;
  final String content;
  final int likes;
  final String? imageUrl;
}

class _RelatedRecipe {
  const _RelatedRecipe({
    required this.title,
    required this.imageUrl,
    required this.rating,
  });

  final String title;
  final String imageUrl;
  final double rating;
}

List<String> _buildTags(
  String? petType,
  String? category,
  String? purpose, {
  List<String> fallback = const [],
  bool isAiGenerated = false,
}) {
  final tags = <String>[];

  if (petType == 'DOG') tags.add('강아지');
  if (petType == 'CAT') tags.add('고양이');
  if (isAiGenerated) tags.add('AI생성');

  // 카테고리 태그 (6자 이하로 축약)
  if (category != null && category.isNotEmpty) {
    tags.add(category.length > 6 ? category.substring(0, 6) : category);
  }

  // purpose 키워드 기반 태그 추출
  if (purpose != null && purpose.isNotEmpty) {
    const keywordMap = {
      '다이어트': ['다이어트', '체중 관리', '비만', '감량', '저칼로리'],
      '고단백': ['단백질', '고단백', '근육'],
      '소화': ['소화', '위장', '장', '소화기'],
      '관절': ['관절', '뼈', '연골'],
      '피부모질': ['피부', '모질', '털', '피모'],
      '노령': ['노령', '시니어', '노견', '노묘', '고령'],
      '저지방': ['저지방', '지방 감소'],
      '면역': ['면역', '항산화'],
      '알레르기': ['알레르기', '알러지', '저알레르기'],
    };
    for (final entry in keywordMap.entries) {
      if (entry.value.any((kw) => purpose.contains(kw))) {
        if (!tags.contains(entry.key)) tags.add(entry.key);
      }
    }
    // 키워드 매핑이 없으면 purpose 자체를 짧게 추가
    if (tags.length < 2) {
      final short = purpose.length > 5 ? purpose.substring(0, 5) : purpose;
      if (!tags.contains(short)) tags.add(short);
    }
  }

  if (tags.isEmpty) return fallback.isEmpty ? const ['맞춤식'] : fallback;
  return tags.toSet().take(5).toList();
}

List<String>? _tipsFromWarnings(String? warnings) {
  if (warnings == null || warnings.trim().isEmpty) return null;
  return warnings
      .split(RegExp(r'[\n,]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(3)
      .toList();
}

class _CookingCompleteButton extends StatefulWidget {
  const _CookingCompleteButton({
    required this.recipeTitle,
    required this.recipeId,
  });
  final String recipeTitle;
  final int recipeId;

  @override
  State<_CookingCompleteButton> createState() => _CookingCompleteButtonState();
}

class _CookingCompleteButtonState extends State<_CookingCompleteButton> {
  bool _done = false;
  bool _loading = false;

  Future<void> _confirmAndComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: ChowColors.orange500),
            SizedBox(width: 8),
            Text('조리 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          '"${widget.recipeTitle}" 레시피로 조리를 완료했나요?\n완료 기록이 저장됩니다.',
          style: const TextStyle(fontSize: 14, color: ChowColors.gray700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: ChowColors.gray500)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ChowColors.orange500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('완료했어요'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ApiClient.post('/api/meal-records', {
        'mealTitle': widget.recipeTitle,
        'mealDate': DateTime.now().toIso8601String().substring(0, 10),
        'mealNote': '레시피 #${widget.recipeId} 조리 완료',
      });
      if (!mounted) return;
      setState(() { _done = true; _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('조리 완료 기록이 저장됐어요!'),
          backgroundColor: ChowColors.orange500,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: SizedBox(
        width: double.infinity,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: ChowColors.orange500))
            : _done
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: ChowColors.orange50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ChowColors.orange500),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: ChowColors.orange500, size: 20),
                        SizedBox(width: 8),
                        Text('조리 완료 기록됨', style: TextStyle(color: ChowColors.orange500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _confirmAndComplete,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('조리 완료', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: ChowColors.orange500,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
      ),
    );
  }
}



