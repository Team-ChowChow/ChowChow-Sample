import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

enum _DietLogTab { recipe, food }

class DietLogPage extends StatefulWidget {
  const DietLogPage({super.key});

  @override
  State<DietLogPage> createState() => _DietLogPageState();
}

class _DietLogPageState extends State<DietLogPage> {
  bool _loadingPets = true;
  List<PetModel> _pets = [];
  PetModel? _selectedPet;

  _DietLogTab _tab = _DietLogTab.recipe;

  bool _loadingRecipes = false;
  List<RecipeModel> _recipes = [];
  String? _recipeError;

  bool _loadingMeals = false;
  List<MealRecordModel> _foodMeals = [];
  String? _mealError;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final res = await ApiClient.get('/api/pets') as List<dynamic>;
      if (!mounted) return;
      final pets = res.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _pets = pets;
        _selectedPet = pets.isNotEmpty ? pets.first : null;
        _loadingPets = false;
      });
      if (_selectedPet != null) _loadForTab();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPets = false);
    }
  }

  void _loadForTab() {
    if (_selectedPet == null) return;
    if (_tab == _DietLogTab.recipe) {
      _loadRecipes(_selectedPet!.petId);
    } else {
      _loadFoodMeals(_selectedPet!.petId);
    }
  }

  Future<void> _loadRecipes(int petId) async {
    setState(() { _loadingRecipes = true; _recipeError = null; });
    try {
      final res = await ApiClient.get('/api/v1/recipes/by-pet/$petId') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _recipes = res.map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList();
        _loadingRecipes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _recipeError = '식단 기록을 불러오지 못했어요.'; _loadingRecipes = false; });
    }
  }

  Future<void> _loadFoodMeals(int petId) async {
    setState(() { _loadingMeals = true; _mealError = null; });
    try {
      final res = await ApiClient.get('/api/meal-records', query: {'petId': '$petId'}) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _foodMeals = res
            .map((e) => MealRecordModel.fromJson(e as Map<String, dynamic>))
            .where((m) => m.commercialFoodId != null || m.userFoodId != null)
            .toList();
        _loadingMeals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _mealError = '사료 기록을 불러오지 못했어요.'; _loadingMeals = false; });
    }
  }

  Future<void> _addFoodEntry() async {
    if (_selectedPet == null) return;
    final food = await context.push<CommercialFoodModel>('/food-info', extra: {'selectMode': true});
    if (food == null || !mounted) return;
    final amount = await _askFeedingAmount();
    if (amount == null) return;
    try {
      await ApiClient.post('/api/meal-records', {
        'petId': _selectedPet!.petId,
        'mealTitle': '${food.brandName} · ${food.productName}',
        'mealDate': DateTime.now().toIso8601String().substring(0, 10),
        'feedingAmountG': double.parse(amount),
        if (!food.isUserFood) 'commercialFoodId': food.foodId,
        if (food.isUserFood) 'userFoodId': food.foodId,
      });
      if (!mounted) return;
      _loadFoodMeals(_selectedPet!.petId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사료 기록에 실패했어요.')),
      );
    }
  }

  Future<String?> _askFeedingAmount() {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('급여량 기록', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '급여량 (g)', hintText: '예: 80'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ChowCozy.stone500),
              onPressed: () {
                final v = double.tryParse(controller.text.trim());
                Navigator.of(ctx).pop(v != null ? controller.text.trim() : null);
              },
              child: const Text('기록하기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: ChowColors.gray50,
        centerTitle: true,
        title: const Text('식단 기록'),
      ),
      floatingActionButton: _selectedPet == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _tab == _DietLogTab.recipe
                  ? () async {
                      final saved = await context.push<bool>(
                        '/diet-log/new-recipe',
                        extra: {'petId': _selectedPet!.petId, 'petType': _selectedPet!.petType},
                      );
                      if (saved == true) _loadRecipes(_selectedPet!.petId);
                    }
                  : _addFoodEntry,
              icon: const Icon(Icons.add),
              label: Text(_tab == _DietLogTab.recipe ? '내 레시피 추가' : '사료 기록 추가'),
            ),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? const Center(
                  child: Text('등록된 반려동물이 없어요', style: TextStyle(color: ChowColors.gray500)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: DropdownButtonFormField<PetModel>(
                        initialValue: _selectedPet,
                        items: _pets
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.petName)))
                            .toList(),
                        onChanged: (p) {
                          if (p == null) return;
                          setState(() => _selectedPet = p);
                          _loadForTab();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabChip(
                              label: '레시피',
                              selected: _tab == _DietLogTab.recipe,
                              onTap: () {
                                setState(() => _tab = _DietLogTab.recipe);
                                _loadForTab();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TabChip(
                              label: '사료',
                              selected: _tab == _DietLogTab.food,
                              onTap: () {
                                setState(() => _tab = _DietLogTab.food);
                                _loadForTab();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _tab == _DietLogTab.recipe ? _buildRecipeList() : _buildFoodList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRecipeList() {
    if (_loadingRecipes) return const Center(child: CircularProgressIndicator());
    if (_recipeError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_recipeError!, style: const TextStyle(color: ChowColors.red500)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _loadRecipes(_selectedPet!.petId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (_recipes.isEmpty) {
      return const Center(
        child: Text(
          '아직 만든 식단이 없어요.\nAI 셰프에게 맞춤 레시피를 받아보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(color: ChowColors.gray500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final recipe = _recipes[i];
        return _DietLogCard(
          recipe: recipe,
          onTap: () => context.push('/recipes/${recipe.recipeId}', extra: recipe),
        );
      },
    );
  }

  Widget _buildFoodList() {
    if (_loadingMeals) return const Center(child: CircularProgressIndicator());
    if (_mealError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_mealError!, style: const TextStyle(color: ChowColors.red500)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _loadFoodMeals(_selectedPet!.petId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (_foodMeals.isEmpty) {
      return const Center(
        child: Text(
          '아직 기록된 사료 급여가 없어요.\n오른쪽 아래 버튼으로 사료 급여를 기록해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(color: ChowColors.gray500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _foodMeals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _FoodLogCard(meal: _foodMeals[i]),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ChowCozy.stone500 : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? ChowCozy.stone500 : ChowCozy.stone300),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : ChowCozy.stone700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DietLogCard extends StatelessWidget {
  const _DietLogCard({required this.recipe, required this.onTap});
  final RecipeModel recipe;
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ChowCozy.stone300),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: recipe.imageUrl != null
                      ? ChowNetworkImage(url: recipe.imageUrl!, fit: BoxFit.cover)
                      : Container(color: ChowCozy.stone100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.recipeTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe.recipeDescription != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        recipe.recipeDescription!,
                        style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

class _FoodLogCard extends StatelessWidget {
  const _FoodLogCard({required this.meal});
  final MealRecordModel meal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChowCozy.stone300),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: meal.foodImageUrl != null
                  ? ChowNetworkImage(url: meal.foodImageUrl!, fit: BoxFit.cover)
                  : Container(color: ChowCozy.stone100, child: const Icon(Icons.set_meal, color: ChowCozy.stone500)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodProductName ?? meal.mealTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (meal.foodBrandName != null) meal.foodBrandName!,
                    if (meal.feedingAmountG != null) '${meal.feedingAmountG!.toStringAsFixed(0)}g',
                    if (meal.mealDate != null) meal.mealDate!,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
