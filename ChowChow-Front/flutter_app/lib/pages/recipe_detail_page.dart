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
  _RecipeDetailTab _activeTab = _RecipeDetailTab.recipe;
  _RecipeDetailData? _recipe;

  static const _placeholder =
      'https://images.unsplash.com/photo-1588378898429-6950f6b4f72a?auto=format&fit=crop&w=1080&q=80';

  @override
  void initState() {
    super.initState();
    _recipe = _RecipeDetailData.fromRecipeModel(widget.initialRecipe);
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final res = await ApiClient.get('/api/v1/recipes/${widget.recipeId}')
          as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _recipe = _RecipeDetailData.fromJson(res, fallback: _recipe);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipe ??= _RecipeDetailData.sample(widget.recipeId);
        _loading = false;
      });
    }
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
    final recipe = _recipe ?? _RecipeDetailData.sample(widget.recipeId);

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
                  _HeroImage(
                    imageUrl: recipe.imageUrl ?? _placeholder,
                    isSaved: _isSaved,
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
                    _RelatedSection(recipes: _relatedRecipes),
                  ] else
                    _ReviewsSection(recipe: recipe, reviews: _reviews),
                  _ActionSection(
                    isLiked: _isLiked,
                    onToggleLiked: () => setState(() => _isLiked = !_isLiked),
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
  const _HeroImage({
    required this.imageUrl,
    required this.isSaved,
    required this.onToggleSaved,
  });

  final String imageUrl;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ChowNetworkImage(url: imageUrl),
          Positioned(
            top: 14,
            right: 14,
            child: Material(
              color: isSaved ? ChowColors.orange500 : Colors.white,
              shape: const CircleBorder(),
              elevation: 5,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggleSaved,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.white : ChowColors.gray700,
                    size: 22,
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
                backgroundColor: ChowColors.gray100,
                child: Icon(Icons.person, color: ChowColors.gray500),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '멍냥요리사',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ChowColors.gray900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '레시피 24개 · 팔로워 1,234',
                      style: TextStyle(fontSize: 12, color: ChowColors.gray500),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: ChowColors.orange500,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('팔로우'),
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
  });

  final _RecipeDetailData recipe;
  final List<_Review> reviews;

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
                  onPressed: () {},
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

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.isLiked,
    required this.onToggleLiked,
  });

  final bool isLiked;
  final VoidCallback onToggleLiked;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onToggleLiked,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? ChowColors.red500 : ChowColors.gray700,
              ),
              label: Text(isLiked ? '좋아요 취소' : '좋아요'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isLiked ? ChowColors.red500 : ChowColors.gray700,
                side: BorderSide(
                  color: isLiked ? ChowColors.red500 : ChowColors.gray300,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('댓글 쓰기'),
              style: FilledButton.styleFrom(
                backgroundColor: ChowColors.orange500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
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
    this.rating = 4.8,
    this.reviewCount = 234,
    this.likes = 1520,
    this.saves = 892,
    this.cookTime = '30분',
    this.servings = '2회분',
    this.difficulty = '보통',
    this.calories = '165kcal',
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
    if (recipe == null) return _RecipeDetailData.sample(0);
    return _RecipeDetailData(
      id: recipe.recipeId,
      title: recipe.recipeTitle,
      subtitle: recipe.recipePurpose ?? recipe.menuCategory ?? '건강한 맞춤 식단',
      description: recipe.recipeDescription ?? _sampleDescription,
      imageUrl: recipe.imageUrl,
      tags: _buildTags(recipe.petType, recipe.menuCategory, recipe.recipePurpose),
      ingredients: _sampleIngredients,
      steps: _sampleSteps,
      nutrition: _sampleNutrition,
      tips: _sampleTips,
      servings: recipe.feedingAmount ?? '2회분',
    );
  }

  factory _RecipeDetailData.fromJson(
    Map<String, dynamic> json, {
    _RecipeDetailData? fallback,
  }) {
    final base = fallback ?? _RecipeDetailData.sample(json['recipeId'] as int? ?? 0);
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

    return _RecipeDetailData(
      id: json['recipeId'] as int? ?? base.id,
      title: json['recipeTitle'] as String? ?? base.title,
      subtitle: purpose ?? category ?? base.subtitle,
      description:
          json['recipeDescription'] as String? ?? base.description,
      imageUrl: json['imageUrl'] as String? ?? base.imageUrl,
      tags: _buildTags(petType, category, purpose, fallback: base.tags),
      ingredients: ingredients.isEmpty ? base.ingredients : ingredients,
      steps: steps.isEmpty ? base.steps : steps,
      nutrition: base.nutrition,
      tips: _tipsFromWarnings(json['warnings'] as String?) ?? base.tips,
      servings: json['feedingAmount'] as String? ?? base.servings,
    );
  }

  factory _RecipeDetailData.sample(int id) {
    return _RecipeDetailData(
      id: id,
      title: '저지방 닭가슴살 고구마 레시피',
      subtitle: '건강한 다이어트 식단',
      description: _sampleDescription,
      imageUrl: _RecipeDetailPageState._placeholder,
      tags: const ['저지방', '다이어트', '고단백'],
      ingredients: _sampleIngredients,
      steps: _sampleSteps,
      nutrition: _sampleNutrition,
      tips: _sampleTips,
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
}) {
  final tags = <String>[
    if (petType == 'DOG') '강아지',
    if (petType == 'CAT') '고양이',
    if (category != null && category.isNotEmpty) category,
    if (purpose != null && purpose.isNotEmpty) purpose,
  ];
  if (tags.isEmpty) return fallback.isEmpty ? const ['맞춤식'] : fallback;
  return tags.toSet().take(3).toList();
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

const _sampleDescription =
    '반려동물을 위한 건강하고 맛있는 홈메이드 레시피입니다. 알러지와 영양 균형을 고려해 부담 없이 급여할 수 있도록 구성했습니다.';

const _sampleIngredients = [
  _Ingredient(name: '닭가슴살', amount: '200g'),
  _Ingredient(name: '고구마', amount: '150g'),
  _Ingredient(name: '브로콜리', amount: '50g'),
  _Ingredient(name: '당근', amount: '50g'),
  _Ingredient(name: '현미밥', amount: '100g'),
  _Ingredient(name: '올리브 오일', amount: '1 tsp'),
];

const _sampleSteps = [
  _RecipeStep(step: 1, description: '닭가슴살은 깨끗이 씻어 한입 크기로 자른 뒤 완전히 익을 때까지 삶아주세요.'),
  _RecipeStep(step: 2, description: '고구마와 당근은 1cm 크기로 깍둑썰기해 찜기에 쪄주세요.'),
  _RecipeStep(step: 3, description: '브로콜리는 끓는 물에 2-3분간 데쳐 부드럽게 만들어주세요.'),
  _RecipeStep(step: 4, description: '익힌 닭가슴살을 식힌 뒤 올리브 오일을 살짝 더해주세요.'),
  _RecipeStep(step: 5, description: '현미밥과 모든 재료를 골고루 섞어주세요.'),
  _RecipeStep(step: 6, description: '완전히 식힌 후 반려동물에게 급여하세요.'),
];

const _sampleNutrition = [
  _NutritionItem(label: '단백질', value: '28g'),
  _NutritionItem(label: '탄수화물', value: '12g'),
  _NutritionItem(label: '지방', value: '4g'),
  _NutritionItem(label: '식이섬유', value: '3g'),
];

const _sampleTips = [
  '처음 급여할 때는 소량으로 시작해주세요.',
  '냉장 보관은 3일, 냉동 보관은 2주까지 가능합니다.',
  '닭가슴살 대신 연어나 소고기로 대체할 수 있습니다.',
];

const _reviews = [
  _Review(
    author: '복실이맘',
    rating: 5,
    date: '2026.05.28',
    content: '우리 아이가 정말 잘 먹어요. 알러지도 없고 건강하게 잘 지내고 있습니다.',
    likes: 42,
    imageUrl: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=400',
  ),
  _Review(
    author: '골든아빠',
    rating: 5,
    date: '2026.05.26',
    content: '만들기도 쉽고 다이어트 식단으로도 만족스럽습니다.',
    likes: 28,
  ),
  _Review(
    author: '초코엄마',
    rating: 4,
    date: '2026.05.24',
    content: '레시피대로 만들었는데 잘 먹네요. 브로콜리는 조금 더 잘게 썰면 좋을 것 같아요.',
    likes: 15,
  ),
];

const _relatedRecipes = [
  _RelatedRecipe(
    title: '연어 오메가3 영양밥',
    imageUrl: 'https://images.unsplash.com/photo-1580683750935-cecfc7ea57f0?w=400',
    rating: 4.9,
  ),
  _RelatedRecipe(
    title: '소고기 단호박 영양식',
    imageUrl: 'https://images.unsplash.com/photo-1618788856642-8e491177d973?w=400',
    rating: 4.7,
  ),
];
