import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_card.dart';
import '../widgets/chow_network_image.dart';

class FoodInfoPage extends StatefulWidget {
  const FoodInfoPage({
    super.key,
    this.selectMode = false,
    this.allowUserFoods = true,
    this.lockedPetType,
  });

  /// true면 카드를 눌렀을 때 화면을 열람만 하지 않고 선택한 사료를 pop으로 반환한다.
  final bool selectMode;

  /// 사료 교체 가이드처럼 두 공식 제품을 정확히 비교해야 하는 화면에서는
  /// 사용자가 직접 입력한(영양 정보가 부정확할 수 있는) 사료를 고르지 못하게 숨긴다.
  final bool allowUserFoods;

  /// 'DOG' 또는 'CAT'을 넘기면 종 필터를 그 값으로 고정하고 전환 UI를 숨긴다.
  /// (예: 강아지를 급여 중인데 실수로 고양이 사료를 골라 위험한 조합이 되는 것을 방지)
  final String? lockedPetType;

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

  bool _showMyFoods = false;
  bool _loadingMyFoods = false;
  List<CommercialFoodModel> _myFoods = [];

  @override
  void initState() {
    super.initState();
    _filter = switch (widget.lockedPetType) {
      'DOG' => _PetTypeFilter.dog,
      'CAT' => _PetTypeFilter.cat,
      _ => _PetTypeFilter.all,
    };
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
      setState(() {
        _brands = res.cast<String>();
        // 새 종에 없는 브랜드라면만 선택 해제 — 두 조건은 서로 독립적으로 유지
        if (_selectedBrand != null && !_brands.contains(_selectedBrand)) {
          _selectedBrand = null;
        }
      });
    } catch (_) {}
  }

  void _onPetTypeSelected(_PetTypeFilter filter) {
    setState(() => _filter = filter);
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

  Future<void> _loadMyFoods() async {
    setState(() => _loadingMyFoods = true);
    try {
      final res = await ApiClient.get('/api/v1/user-foods') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _myFoods = res.map((e) => CommercialFoodModel.fromUserFoodJson(e as Map<String, dynamic>)).toList();
        _loadingMyFoods = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMyFoods = false);
    }
  }

  void _toggleMyFoods(bool showMine) {
    setState(() => _showMyFoods = showMine);
    if (showMine && _myFoods.isEmpty) _loadMyFoods();
  }

  Future<void> _addUserFood() async {
    final brandCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final carbCtrl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('사료 직접 등록', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('여기서 등록하면 급여량 계산기·식단 기록 등에서 바로 다시 골라 쓸 수 있어요.',
                  style: TextStyle(color: ChowColors.gray500, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: '브랜드 (선택)')),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '제품명 *')),
              const SizedBox(height: 10),
              TextField(
                controller: kcalCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '100g당 칼로리 (kcal)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '단백질 (g, 선택)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '지방 (g, 선택)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carbCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '탄수화물 (g, 선택)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ChowColors.orange500),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    await ApiClient.post('/api/v1/user-foods', {
                      if (brandCtrl.text.trim().isNotEmpty) 'brandName': brandCtrl.text.trim(),
                      'productName': nameCtrl.text.trim(),
                      if (_petTypeParam != null) 'petType': _petTypeParam!,
                      if (double.tryParse(kcalCtrl.text.trim()) != null) 'caloriesPer100g': double.parse(kcalCtrl.text.trim()),
                      if (double.tryParse(proteinCtrl.text.trim()) != null) 'proteinG': double.parse(proteinCtrl.text.trim()),
                      if (double.tryParse(fatCtrl.text.trim()) != null) 'fatG': double.parse(fatCtrl.text.trim()),
                      if (double.tryParse(carbCtrl.text.trim()) != null) 'carbohydrateG': double.parse(carbCtrl.text.trim()),
                    });
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  } catch (_) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('등록에 실패했어요. 제품명을 확인해주세요.')),
                      );
                    }
                  }
                },
                child: const Text('등록하기'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) _loadMyFoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: ChowColors.gray50,
        centerTitle: true,
        title: Text(widget.selectMode ? '사료 선택' : '사료 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.allowUserFoods) ...[
              Row(
                children: [
                  Expanded(
                    child: _SourceTabChip(
                      label: '공식 사료',
                      selected: !_showMyFoods,
                      onTap: () => _toggleMyFoods(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SourceTabChip(
                      label: '내가 등록한 사료',
                      selected: _showMyFoods,
                      onTap: () => _toggleMyFoods(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (_showMyFoods) ...[
              OutlinedButton.icon(
                onPressed: _addUserFood,
                icon: const Icon(Icons.add),
                label: const Text('사료 직접 등록하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: ChowColors.orange500),
                  foregroundColor: ChowColors.orange500,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loadingMyFoods
                    ? const Center(child: CircularProgressIndicator())
                    : _myFoods.isEmpty
                        ? const Center(
                            child: Text('아직 직접 등록한 사료가 없어요', style: TextStyle(color: ChowColors.gray500)),
                          )
                        : ListView.separated(
                            itemCount: _myFoods.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _FoodCard(
                              food: _myFoods[i],
                              onTap: widget.selectMode
                                  ? () => Navigator.of(context).pop(_myFoods[i])
                                  : null,
                            ),
                          ),
              ),
            ] else ...[
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
              if (widget.lockedPetType != null) ...[
                Row(
                  children: [
                    Icon(
                      widget.lockedPetType == 'CAT' ? Icons.pets : Icons.pets_outlined,
                      size: 16,
                      color: ChowColors.gray500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.lockedPetType == 'CAT' ? '고양이 사료만 표시 중이에요' : '강아지 사료만 표시 중이에요',
                      style: const TextStyle(fontSize: 12, color: ChowColors.gray500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ] else ...[
                const Text('반려동물 종류', style: TextStyle(fontSize: 12, color: ChowColors.gray500, fontWeight: FontWeight.w500)),
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
              ],
              if (_brands.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('브랜드', style: TextStyle(fontSize: 12, color: ChowColors.gray500, fontWeight: FontWeight.w500)),
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
                            itemBuilder: (_, i) => _FoodCard(
                              food: _results[i],
                              onTap: widget.selectMode
                                  ? () => Navigator.of(context).pop(_results[i])
                                  : null,
                            ),
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceTabChip extends StatelessWidget {
  const _SourceTabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ChowColors.orange500 : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? ChowColors.orange500 : ChowCozy.stone300),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : ChowCozy.stone700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
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
  const _FoodCard({required this.food, this.onTap});
  final CommercialFoodModel food;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ChowCard(
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
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: card);
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
