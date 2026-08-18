import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class FoodInfoPage extends StatefulWidget {
  const FoodInfoPage({super.key});

  @override
  State<FoodInfoPage> createState() => _FoodInfoPageState();
}

enum _PetTypeFilter { all, dog, cat }

class _FoodInfoPageState extends State<FoodInfoPage> {
  final _searchController = TextEditingController();
  List<CommercialFoodModel> _results = [];
  bool _searching = false;
  bool _searched = false;
  _PetTypeFilter _filter = _PetTypeFilter.all;

  List<String> _brands = [];
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _loadBrands();
    _search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _petTypeParam => switch (_filter) {
        _PetTypeFilter.all => null,
        _PetTypeFilter.dog => 'DOG',
        _PetTypeFilter.cat => 'CAT',
      };

  Future<void> _loadBrands() async {
    try {
      final res = await ApiClient.get('/api/v1/foods/brands', query: {
        if (_petTypeParam != null) 'petType': _petTypeParam!,
      }) as List<dynamic>;
      if (!mounted) return;
      setState(() => _brands = res.cast<String>());
    } catch (_) {}
  }

  void _onPetTypeSelected(_PetTypeFilter filter) {
    setState(() {
      _filter = filter;
      _selectedBrand = null;
    });
    _loadBrands();
    _search();
  }

  void _onBrandSelected(String? brand) {
    setState(() => _selectedBrand = brand);
    _search();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    setState(() => _searching = true);
    try {
      final res = await ApiClient.get('/api/v1/foods/search', query: {
        'query': query,
        if (_petTypeParam != null) 'petType': _petTypeParam!,
        if (_selectedBrand != null) 'brand': _selectedBrand!,
      }) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _results = res.map((e) => CommercialFoodModel.fromJson(e as Map<String, dynamic>)).toList();
        _searching = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사료 정보')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '브랜드명 또는 제품명으로 검색',
                      prefixIcon: Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('1. 반려동물 종류', style: TextStyle(fontSize: 12, color: ChowColors.gray500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              children: [
                _PetTypeChip(
                  label: '전체',
                  selected: _filter == _PetTypeFilter.all,
                  onTap: () => _onPetTypeSelected(_PetTypeFilter.all),
                ),
                const SizedBox(width: 8),
                _PetTypeChip(
                  label: '🐶 강아지',
                  selected: _filter == _PetTypeFilter.dog,
                  onTap: () => _onPetTypeSelected(_PetTypeFilter.dog),
                ),
                const SizedBox(width: 8),
                _PetTypeChip(
                  label: '🐱 고양이',
                  selected: _filter == _PetTypeFilter.cat,
                  onTap: () => _onPetTypeSelected(_PetTypeFilter.cat),
                ),
              ],
            ),
            if (_brands.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('2. 브랜드', style: TextStyle(fontSize: 12, color: ChowColors.gray500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                key: ValueKey(_filter),
                initialValue: _selectedBrand,
                isExpanded: true,
                hint: const Text('전체 브랜드'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('전체 브랜드')),
                  ..._brands.map((b) => DropdownMenuItem<String?>(value: b, child: Text(b))),
                ],
                onChanged: (b) => _onBrandSelected(b),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: !_searched
                  ? const _FoodInfoEmptyState()
                  : _results.isEmpty
                      ? const Center(
                          child: Text('검색 결과가 없어요', style: TextStyle(color: ChowColors.gray500)),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _FoodCard(food: _results[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetTypeChip extends StatelessWidget {
  const _PetTypeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _FoodInfoEmptyState extends StatelessWidget {
  const _FoodInfoEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '사료 브랜드나 제품명을 검색해보세요',
        style: TextStyle(color: ChowColors.gray500),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.food});
  final CommercialFoodModel food;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChowCozy.stone300),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (food.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: ChowNetworkImage(url: food.imageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.brandName,
                  style: const TextStyle(fontSize: 12, color: ChowColors.gray500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  food.productName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (food.features != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    food.features!,
                    style: const TextStyle(fontSize: 13, color: ChowCozy.stone700, height: 1.4),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _NutrientChip(label: '칼로리', value: food.caloriesPer100g, unit: 'kcal'),
                    _NutrientChip(label: '단백질', value: food.proteinG, unit: 'g'),
                    _NutrientChip(label: '지방', value: food.fatG, unit: 'g'),
                    _NutrientChip(label: '탄수화물', value: food.carbohydrateG, unit: 'g'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({required this.label, required this.value, required this.unit});
  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ChowCozy.stone100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${value!.toStringAsFixed(1)}$unit/100g',
        style: const TextStyle(fontSize: 12, color: ChowCozy.stone700, fontWeight: FontWeight.w500),
      ),
    );
  }
}
