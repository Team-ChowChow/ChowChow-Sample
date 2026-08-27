import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';

enum _DietType { recipe, feed }

const _feedingTimeOptions = ['아침', '점심', '저녁'];

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

  int _step = 0;

  _DietType _dietType = _DietType.recipe;
  RecipeModel? _selectedRecipe;
  final _kcalController = TextEditingController();
  CommercialFoodModel? _selectedFood;

  final Set<String> _feedingTimes = {};

  bool _calculating = false;
  String? _calcError;
  FeedingGuidelineModel? _result;
  bool _recording = false;
  bool _recorded = false;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void dispose() {
    _kcalController.dispose();
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

  Future<void> _refreshSelectedPet() async {
    final pet = _selectedPet;
    if (pet == null) return;
    try {
      final res = await ApiClient.get('/api/pets/${pet.petId}') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _selectedPet = PetModel.fromJson(res);
        final idx = _pets.indexWhere((p) => p.petId == pet.petId);
        if (idx != -1) _pets[idx] = _selectedPet!;
      });
    } catch (_) {}
  }

  Future<void> _pickFood() async {
    final picked = await context.push<CommercialFoodModel>('/food-info', extra: {'selectMode': true});
    if (picked != null) {
      setState(() {
        _selectedFood = picked;
        _kcalController.clear();
      });
    }
  }

  Future<void> _enterFoodManually() async {
    final nameController = TextEditingController();
    final kcalController = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
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
            const Text('사료 정보 직접 입력', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('찾는 사료가 목록에 없나요? 여기서 등록하면 식단 기록 등 다른 화면에서도 바로 다시 골라 쓸 수 있어요.',
                style: TextStyle(color: ChowColors.gray500, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '사료 이름', hintText: '예: OO 사료'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: kcalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '100g당 칼로리 (kcal)', hintText: '예: 380'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ChowColors.orange500),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('등록하고 선택하기'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final name = nameController.text.trim();
    final kcal = double.tryParse(kcalController.text.trim());
    if (name.isEmpty) return;
    try {
      final res = await ApiClient.post('/api/v1/user-foods', {
        'productName': name,
        if (kcal != null) 'caloriesPer100g': kcal,
      }) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _selectedFood = CommercialFoodModel.fromUserFoodJson(res));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사료 등록에 실패했어요.')),
      );
    }
  }

  bool get _dietSelectionValid {
    if (_dietType == _DietType.recipe) return _selectedRecipe != null;
    return _selectedFood != null || double.tryParse(_kcalController.text.trim()) != null;
  }

  Future<void> _calculate() async {
    final pet = _selectedPet;
    if (pet == null) return;

    setState(() {
      _calculating = true;
      _calcError = null;
      _result = null;
      _recorded = false;
    });

    try {
      final kcal = double.tryParse(_kcalController.text.trim());
      final query = <String, String>{
        if (_dietType == _DietType.recipe) 'recipeId': '${_selectedRecipe!.recipeId}',
        // 직접 등록한 사료는 별도 테이블이라 계산 API가 모르므로, 저장해둔 칼로리 값을 그대로 넘긴다.
        if (_dietType == _DietType.feed && _selectedFood != null && !_selectedFood!.isUserFood)
          'commercialFoodId': '${_selectedFood!.foodId}',
        if (_dietType == _DietType.feed && _selectedFood != null && _selectedFood!.isUserFood)
          'kcalPer100g': '${_selectedFood!.caloriesPer100g}',
        if (_dietType == _DietType.feed && _selectedFood == null) 'kcalPer100g': '$kcal',
      };
      final res = await ApiClient.get(
        '/api/pets/${pet.petId}/feeding-guideline',
        query: query,
      ) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _result = FeedingGuidelineModel.fromJson(res);
        _calculating = false;
        _step = 3;
      });
    } catch (e) {
      setState(() {
        _calcError = '계산에 실패했어요. 반려동물의 체중 정보가 등록되어 있는지 확인해주세요.';
        _calculating = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImagePath = image.path;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImagePath = null;
    });
  }

  Future<void> _recordMeal() async {
    final pet = _selectedPet;
    final result = _result;
    if (pet == null || result == null || result.recommendedGrams == null) return;

    final title = _dietType == _DietType.recipe
        ? (_selectedRecipe?.recipeTitle ?? '레시피 급여')
        : (_selectedFood?.productName ?? '사료 급여');

    setState(() => _recording = true);
    try {
      String? imageUrl;
      if (_selectedImagePath != null) {
        imageUrl = await ApiClient.uploadImage(File(_selectedImagePath!), type: 'meal');
      }
      await ApiClient.post('/api/meal-records', {
        'petId': pet.petId,
        'mealTitle': title,
        'mealNote': _feedingTimes.isNotEmpty ? '${_feedingTimes.join(', ')} 급여' : null,
        'imageUrl': imageUrl,
        'mealDate': DateTime.now().toIso8601String().split('T').first,
        'feedingAmountG': result.recommendedGrams,
        if (_dietType == _DietType.recipe && _selectedRecipe != null) 'recipeId': _selectedRecipe!.recipeId,
        if (_dietType == _DietType.feed && _selectedFood != null && !_selectedFood!.isUserFood)
          'commercialFoodId': _selectedFood!.foodId,
        if (_dietType == _DietType.feed && _selectedFood != null && _selectedFood!.isUserFood)
          'userFoodId': _selectedFood!.foodId,
      });
      if (!mounted) return;
      setState(() {
        _recording = false;
        _recorded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식단 기록에 실패했어요.')),
      );
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

  void _goBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      context.pop();
    }
  }

  Future<void> _editWeight() async {
    final pet = _selectedPet;
    if (pet == null) return;
    final controller = TextEditingController(text: pet.petWeight?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('현재 체중 수정'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('저장')),
        ],
      ),
    );
    if (saved != true) return;
    final weight = double.tryParse(controller.text.trim());
    if (weight == null) return;
    try {
      await ApiClient.patch('/api/pets/${pet.petId}', {
        'petName': pet.petName,
        'petType': pet.petType,
        'petWeight': weight,
      });
      await _refreshSelectedPet();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('체중 저장에 실패했어요.')));
    }
  }

  Future<void> _editBcs() async {
    final pet = _selectedPet;
    if (pet == null) return;
    int bcs = pet.petBodyConditionScore ?? 5;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('체형 점수(BCS) 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('BCS $bcs / 9', style: const TextStyle(fontWeight: FontWeight.w500)),
              Slider(
                value: bcs.toDouble(),
                min: 1,
                max: 9,
                divisions: 8,
                label: '$bcs',
                onChanged: (v) => setDialog(() => bcs = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('저장')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    try {
      await ApiClient.patch('/api/pets/${pet.petId}', {
        'petName': pet.petName,
        'petType': pet.petType,
        'petBodyConditionScore': bcs,
      });
      await _refreshSelectedPet();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('체형 점수 저장에 실패했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_loadingPets && _loadError == null && _pets.isNotEmpty;
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: ChowColors.gray50,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
        title: const Text('급여량 계산기', style: TextStyle(fontWeight: FontWeight.w500)),
        centerTitle: true,
      ),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _ErrorState(message: _loadError!, onRetry: _loadPets)
              : _pets.isEmpty
                  ? const Center(child: Text('등록된 반려동물이 없어요.'))
                  : Column(
                      children: [
                        if (_step < 3) _buildProgressDots(),
                        Expanded(child: _buildStep()),
                      ],
                    ),
      bottomNavigationBar: ready ? _buildBottomCta() : null,
    );
  }

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: active ? ChowColors.orange500 : ChowColors.gray200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildDietStep();
      case 1:
        return _buildFeedingTimesStep();
      case 2:
        return _buildPetInfoStep();
      default:
        return _buildResultStep();
    }
  }

  Widget? _buildBottomCta() {
    switch (_step) {
      case 0:
        return _ctaButton(
          label: '다음',
          enabled: _dietSelectionValid,
          onPressed: () => setState(() => _step = 1),
        );
      case 1:
        return _ctaButton(
          label: '다음',
          enabled: _feedingTimes.isNotEmpty,
          onPressed: () => setState(() => _step = 2),
        );
      case 2:
        return _ctaButton(
          label: '권장 급여량 보기',
          enabled: !_calculating && _selectedPet?.petWeight != null,
          loading: _calculating,
          onPressed: _calculate,
        );
      default:
        if (_result?.recommendedGrams == null) return null;
        if (_recorded) {
          return _ctaButton(label: '완료', enabled: true, onPressed: () => context.pop());
        }
        return _ctaButton(
          label: '이 급여량으로 식단 기록하기',
          enabled: !_recording,
          loading: _recording,
          onPressed: _recordMeal,
        );
    }
  }

  Widget _ctaButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled && !loading ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChowColors.orange500,
              disabledBackgroundColor: ChowColors.gray300,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _buildDietStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          '${_selectedPet?.petName ?? ''}이(가)\n먹는 건 뭔가요?',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: ChowColors.gray900, height: 1.3),
        ),
        const SizedBox(height: 24),
        if (_pets.length > 1) ...[
          const Text('반려동물 선택', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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
        ],
        const Text('급여 방식', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _dietTypeChip('직접 만든 식단', '🍚', _DietType.recipe)),
            const SizedBox(width: 10),
            Expanded(child: _dietTypeChip('사료', '🥫', _DietType.feed)),
          ],
        ),
        const SizedBox(height: 24),
        if (_dietType == _DietType.recipe) ...[
          const Text('레시피 선택', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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
          const Text('사료 선택', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          const SizedBox(height: 8),
          if (_selectedFood != null)
            _card(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedFood!.brandName} · ${_selectedFood!.productName} (100g당 ${_selectedFood!.caloriesPer100g?.toStringAsFixed(0) ?? '-'}kcal)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _selectedFood = null),
                  ),
                ],
              ),
            )
          else if (_kcalController.text.trim().isNotEmpty)
            _card(
              child: Row(
                children: [
                  Expanded(
                    child: Text('직접 입력한 칼로리: 100g당 ${_kcalController.text.trim()}kcal'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _kcalController.clear()),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFood,
                    icon: const Icon(Icons.search),
                    label: const Text('사료 목록에서 선택'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: ChowColors.orange500),
                      foregroundColor: ChowColors.orange500,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _enterFoodManually,
              child: const Text('찾는 사료가 없나요? 직접 입력하기'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeedingTimesStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          '하루 몇 번\n급여하나요?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: ChowColors.gray900, height: 1.3),
        ),
        const Text(
          '최소 한 번 이상 선택해주세요',
          style: TextStyle(fontSize: 14, color: ChowColors.gray500),
        ),
        const SizedBox(height: 24),
        ..._feedingTimeOptionsWidgets(),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: ChowColors.gray100, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: ChowColors.gray500),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '권장 급여 횟수\n우리 아이의 나이와 컨디션에 맞춰 하루에 나눠 급여하는 것을 권장해요.',
                  style: TextStyle(fontSize: 13, color: ChowColors.gray600, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _feedingTimeEmoji = {'아침': '🌅', '점심': '☀️', '저녁': '🌙'};

  List<Widget> _feedingTimeOptionsWidgets() {
    return _feedingTimeOptions.expand((time) {
      final selected = _feedingTimes.contains(time);
      return [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            if (selected) {
              _feedingTimes.remove(time);
            } else {
              _feedingTimes.add(time);
            }
          }),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? ChowColors.orange50 : Colors.white,
              border: Border.all(color: selected ? ChowColors.orange500 : ChowColors.gray200, width: selected ? 2 : 1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? null
                  : const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Text(_feedingTimeEmoji[time] ?? '', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w500,
                      color: selected ? ChowColors.orange600 : ChowColors.gray700,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 22,
                  color: selected ? ChowColors.orange500 : ChowColors.gray300,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ];
    }).toList();
  }

  Widget _buildPetInfoStep() {
    final pet = _selectedPet;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          '${pet?.petName ?? ''}의 정보를\n확인해요',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: ChowColors.gray900, height: 1.3),
        ),
        const SizedBox(height: 24),
        _infoRow(
          icon: Icons.monitor_weight_outlined,
          label: '현재 체중',
          value: pet?.petWeight != null ? '${pet!.petWeight}kg' : '미등록',
          onEdit: _editWeight,
        ),
        const SizedBox(height: 12),
        _infoRow(
          icon: Icons.favorite_border,
          label: '체형 점수',
          value: pet?.petBodyConditionScore != null ? 'BCS ${pet!.petBodyConditionScore}' : '미등록',
          onEdit: _editBcs,
        ),
        if (_calcError != null) ...[
          const SizedBox(height: 16),
          Text(_calcError!, style: const TextStyle(color: ChowColors.red500)),
        ],
      ],
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value, required VoidCallback onEdit}) {
    return _card(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: ChowColors.green500.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: ChowColors.green500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: ChowColors.gray500)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ChowColors.green500)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: ChowColors.gray700,
              side: const BorderSide(color: ChowColors.gray300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    final perMeal = (result.recommendedGrams != null && _feedingTimes.isNotEmpty)
        ? result.recommendedGrams! / _feedingTimes.length
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text(
          '권장 급여량이에요',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ChowColors.gray900),
        ),
        const SizedBox(height: 16),
        _ResultCard(result: result, statusColor: result.status != null ? _statusColor(result.status!) : ChowColors.gray500),
        if (perMeal != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ChowColors.gray200)),
            child: Text(
              '${_feedingTimes.join(', ')} · 1회당 약 ${perMeal.toStringAsFixed(0)}g',
              style: const TextStyle(fontSize: 14, color: ChowColors.gray700),
            ),
          ),
        ],
        if (!_recorded) ...[
          const SizedBox(height: 16),
          const Text('급여 사진 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ChowColors.gray700)),
          const SizedBox(height: 8),
          _selectedImageBytes != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ChowColors.gray200),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: ChowColors.gray500),
                        SizedBox(height: 6),
                        Text('사진 추가하기', style: TextStyle(fontSize: 13, color: ChowColors.gray500)),
                      ],
                    ),
                  ),
                ),
        ],
        if (_recorded) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ChowColors.orange50, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: ChowColors.orange500, size: 20),
                SizedBox(width: 8),
                Text('오늘의 식단 기록에 저장했어요', style: TextStyle(color: ChowColors.orange600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dietTypeChip(String label, String emoji, _DietType type) {
    final selected = _dietType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() {
        _dietType = type;
        _result = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ChowColors.orange50 : Colors.white,
          border: Border.all(color: selected ? ChowColors.orange500 : ChowColors.gray200, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? null
              : const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? ChowColors.orange600 : ChowColors.gray600,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w500,
              ),
            ),
          ],
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
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
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
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))],
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
                  child: Text(result.status!, style: TextStyle(color: statusColor, fontWeight: FontWeight.w500, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('하루 권장 섭취 칼로리', style: const TextStyle(color: ChowColors.gray600, fontSize: 13)),
          Text('${result.dailyEnergyKcal.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: ChowColors.gray900)),
          if (result.recommendedGrams != null) ...[
            const SizedBox(height: 12),
            Text('하루 권장 급여량', style: const TextStyle(color: ChowColors.gray600, fontSize: 13)),
            Text('${result.recommendedGrams!.toStringAsFixed(0)} g', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: ChowColors.orange600)),
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
