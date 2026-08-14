import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';

enum _DietType { recipe, feed }

class FeedingGuidelinePage extends StatefulWidget {
  const FeedingGuidelinePage({super.key});

  @override
  State<FeedingGuidelinePage> createState() => _FeedingGuidelinePageState();
}

class _FeedingGuidelinePageState extends State<FeedingGuidelinePage> {
  bool _loadingPets = true;
  String? _loadError;
  List<PetModel> _pets = [];
  List<RecipeModel> _recipes = [];
  PetModel? _selectedPet;

  _DietType _dietType = _DietType.recipe;
  RecipeModel? _selectedRecipe;
  final _kcalController = TextEditingController();
  final _currentAmountController = TextEditingController();

  bool _calculating = false;
  String? _calcError;
  FeedingGuidelineModel? _result;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void dispose() {
    _kcalController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() {
      _loadingPets = true;
      _loadError = null;
    });
    try {
      final petsRes = await ApiClient.get('/api/pets') as List<dynamic>;
      setState(() {
        _pets = petsRes.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
        _selectedPet = _pets.isNotEmpty ? _pets.first : null;
        _loadingPets = false;
      });
      if (_selectedPet != null) await _loadRecipesForPet(_selectedPet!.petId);
    } catch (e) {
      setState(() {
        _loadError = '반려동물 정보를 불러오지 못했어요.';
        _loadingPets = false;
      });
    }
  }

  Future<void> _loadRecipesForPet(int petId) async {
    setState(() {
      _recipes = [];
      _selectedRecipe = null;
    });
    try {
      final recipesRes = await ApiClient.get('/api/v1/recipes/by-pet/$petId') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _recipes = recipesRes.map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList();
      });
    } catch (_) {}
  }

  Future<void> _calculate() async {
    final pet = _selectedPet;
    if (pet == null) return;
    if (_dietType == _DietType.recipe && _selectedRecipe == null) {
      setState(() => _calcError = '레시피를 선택해주세요.');
      return;
    }
    final kcal = double.tryParse(_kcalController.text.trim());
    if (_dietType == _DietType.feed && kcal == null) {
      setState(() => _calcError = '사료의 100g당 칼로리를 입력해주세요.');
      return;
    }

    setState(() {
      _calculating = true;
      _calcError = null;
      _result = null;
    });

    try {
      final query = <String, String>{
        if (_dietType == _DietType.recipe) 'recipeId': '${_selectedRecipe!.recipeId}',
        if (_dietType == _DietType.feed) 'kcalPer100g': '$kcal',
        if (_currentAmountController.text.trim().isNotEmpty)
          'currentFeedingAmountG': _currentAmountController.text.trim(),
      };
      final res = await ApiClient.get(
        '/api/pets/${pet.petId}/feeding-guideline',
        query: query,
      ) as Map<String, dynamic>;
      setState(() {
        _result = FeedingGuidelineModel.fromJson(res);
        _calculating = false;
      });
    } catch (e) {
      setState(() {
        _calcError = '계산에 실패했어요. 반려동물의 체중 정보가 등록되어 있는지 확인해주세요.';
        _calculating = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case '과다':
        return ChowColors.red500;
      case '부족':
        return ChowColors.yellow600;
      default:
        return ChowColors.green500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('급여량 계산기'),
      ),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _ErrorState(message: _loadError!, onRetry: _loadPets)
              : _pets.isEmpty
                  ? const Center(child: Text('등록된 반려동물이 없어요.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('반려동물 선택', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 8),
                        _card(
                          child: DropdownButtonFormField<PetModel>(
                            initialValue: _selectedPet,
                            isExpanded: true,
                            decoration: const InputDecoration(border: InputBorder.none),
                            items: _pets
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.petWeight != null ? '${p.petName} (${p.petWeight}kg)' : '${p.petName} (체중 미등록)'),
                                    ))
                                .toList(),
                            onChanged: (p) {
                              setState(() {
                                _selectedPet = p;
                                _result = null;
                              });
                              if (p != null) _loadRecipesForPet(p.petId);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('급여 방식', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _dietTypeChip('직접 만든 식단', _DietType.recipe),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _dietTypeChip('사료', _DietType.feed),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_dietType == _DietType.recipe) ...[
                          const Text('레시피 선택', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 8),
                          _card(
                            child: _recipes.isEmpty
                                ? const Text('이 아이를 위해 생성된 AI 레시피가 없어요. AI 레시피를 먼저 생성해보세요.', style: TextStyle(color: ChowColors.gray500))
                                : DropdownButtonFormField<RecipeModel>(
                                    initialValue: _selectedRecipe,
                                    isExpanded: true,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    items: _recipes
                                        .map((r) => DropdownMenuItem(value: r, child: Text(r.recipeTitle, overflow: TextOverflow.ellipsis)))
                                        .toList(),
                                    onChanged: (r) => setState(() => _selectedRecipe = r),
                                  ),
                          ),
                        ] else ...[
                          const Text('사료 100g당 칼로리 (kcal)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 8),
                          _card(
                            child: TextField(
                              controller: _kcalController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(border: InputBorder.none, hintText: '사료 포장지에 표기된 값을 입력하세요'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text('현재 하루 급여량 (g, 선택)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 8),
                        _card(
                          child: TextField(
                            controller: _currentAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(border: InputBorder.none, hintText: '입력하면 적정성을 판단해드려요'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_calcError != null) ...[
                          Text(_calcError!, style: const TextStyle(color: ChowColors.red500)),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _calculating ? null : _calculate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ChowColors.orange500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _calculating
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('급여량 계산하기'),
                          ),
                        ),
                        if (_result != null) ...[
                          const SizedBox(height: 24),
                          _ResultCard(result: _result!, statusColor: _result!.status != null ? _statusColor(_result!.status!) : ChowColors.gray500),
                        ],
                      ],
                    ),
    );
  }

  Widget _dietTypeChip(String label, _DietType type) {
    final selected = _dietType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() {
        _dietType = type;
        _result = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ChowColors.orange50 : Colors.white,
          border: Border.all(color: selected ? ChowColors.orange500 : ChowColors.gray200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? ChowColors.orange600 : ChowColors.gray600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChowColors.gray200),
      ),
      child: child,
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.statusColor});

  final FeedingGuidelineModel result;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChowColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${result.ageCategory} · 체중 ${result.petWeightKg}kg', style: const TextStyle(color: ChowColors.gray500, fontSize: 13)),
              const Spacer(),
              if (result.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text(result.status!, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('하루 권장 섭취 칼로리', style: const TextStyle(color: ChowColors.gray600, fontSize: 13)),
          Text('${result.dailyEnergyKcal.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ChowColors.gray900)),
          if (result.recommendedGrams != null) ...[
            const SizedBox(height: 12),
            Text('하루 권장 급여량', style: const TextStyle(color: ChowColors.gray600, fontSize: 13)),
            Text('${result.recommendedGrams!.toStringAsFixed(0)} g', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ChowColors.orange600)),
          ],
          if (result.message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ChowColors.gray50, borderRadius: BorderRadius.circular(10)),
              child: Text(result.message!, style: const TextStyle(color: ChowColors.gray700, fontSize: 13, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: ChowColors.gray500)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
