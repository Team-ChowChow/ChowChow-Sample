import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class CompletedRecipesPage extends StatefulWidget {
  const CompletedRecipesPage({super.key});

  @override
  State<CompletedRecipesPage> createState() => _CompletedRecipesPageState();
}

class _CompletedRecipesPageState extends State<CompletedRecipesPage> {
  List<_CompletedRecipeItem> _recipes = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCompletedRecipes();
  }

  Future<void> _loadCompletedRecipes() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final response = await ApiClient.get('/api/meal-records') as List<dynamic>;
      final records = response
          .map((item) => MealRecordModel.fromJson(item as Map<String, dynamic>))
          .where((record) => record.isCompletedRecipe);

      final uniqueRecipes = <int, MealRecordModel>{};
      for (final record in records) {
        uniqueRecipes.putIfAbsent(record.recipeId!, () => record);
      }

      final recipes = await Future.wait(
        uniqueRecipes.values.map(_loadRecipeImage),
      );

      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<_CompletedRecipeItem> _loadRecipeImage(
    MealRecordModel record,
  ) async {
    var imageUrl = record.imageUrl;
    try {
      final recipe = await ApiClient.get('/api/v1/recipes/${record.recipeId}')
          as Map<String, dynamic>;
      final recipeImageUrl = recipe['imageUrl'] as String?;
      if (recipeImageUrl != null && recipeImageUrl.isNotEmpty) {
        imageUrl = recipeImageUrl;
      }
    } catch (_) {}

    return _CompletedRecipeItem(record: record, imageUrl: imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '조리 완료한 레시피',
          style: ChowPageStyles.title,
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF111827),
            size: 20,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ChowCozy.stone500),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: ChowColors.gray400),
            const SizedBox(height: 12),
            const Text(
              '조리 완료 레시피를 불러오지 못했습니다.',
              style: TextStyle(color: ChowColors.gray500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCompletedRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChowCozy.stone500,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_recipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: ChowColors.gray300,
            ),
            SizedBox(height: 12),
            Text(
              '조리 완료한 레시피가 없습니다.',
              style: TextStyle(color: ChowColors.gray500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompletedRecipes,
      color: ChowCozy.stone500,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _recipes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return _CompletedRecipeCard(
            recipe: recipe,
            onTap: () async {
              await context.push('/recipes/${recipe.record.recipeId}');
              if (!mounted) return;
              await _loadCompletedRecipes();
            },
          );
        },
      ),
    );
  }
}

class _CompletedRecipeCard extends StatelessWidget {
  const _CompletedRecipeCard({required this.recipe, required this.onTap});

  final _CompletedRecipeItem recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _RecipeThumbnail(imageUrl: recipe.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.record.mealTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: ChowCozy.stone500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.record.mealDate ?? '조리 완료',
                          style: const TextStyle(
                            color: ChowColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

class _RecipeThumbnail extends StatelessWidget {
  const _RecipeThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 72,
        height: 72,
        child: ChowNetworkImage(
          url: url,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return const _RecipePlaceholder();
  }
}

class _CompletedRecipeItem {
  const _CompletedRecipeItem({required this.record, this.imageUrl});

  final MealRecordModel record;
  final String? imageUrl;
}

class _RecipePlaceholder extends StatelessWidget {
  const _RecipePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: ChowCozy.stone100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.restaurant,
        color: ChowCozy.stone300,
        size: 32,
      ),
    );
  }
}
