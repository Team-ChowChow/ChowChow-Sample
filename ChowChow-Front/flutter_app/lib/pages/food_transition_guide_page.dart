import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_card.dart';

class FoodTransitionGuidePage extends StatefulWidget {
  const FoodTransitionGuidePage({super.key});

  @override
  State<FoodTransitionGuidePage> createState() => _FoodTransitionGuidePageState();
}

class _FoodTransitionGuidePageState extends State<FoodTransitionGuidePage> {
  bool _loadingPets = true;
  List<PetModel> _pets = [];
  PetModel? _selectedPet;

  CommercialFoodModel? _currentFood;
  CommercialFoodModel? _targetFood;

  bool _generating = false;
  String? _error;
  FoodTransitionModel? _result;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final res = await ApiClient.get('/api/pets') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _pets = res.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
        _selectedPet = _pets.isNotEmpty ? _pets.first : null;
        _loadingPets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPets = false);
    }
  }

  Future<void> _generate() async {
    if (_currentFood == null || _targetFood == null) return;
    setState(() {
      _generating = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ApiClient.post(
        '/api/ai/food-transition/recommend',
        {
          if (_selectedPet != null) 'petId': _selectedPet!.petId,
          if (!_currentFood!.isUserFood) 'currentFoodId': _currentFood!.foodId,
          if (_currentFood!.isUserFood) 'currentUserFoodId': _currentFood!.foodId,
          if (!_targetFood!.isUserFood) 'targetFoodId': _targetFood!.foodId,
          if (_targetFood!.isUserFood) 'targetUserFoodId': _targetFood!.foodId,
        },
        timeout: const Duration(seconds: 90),
      ) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _result = FoodTransitionModel.fromJson(res);
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException && e.statusCode == 400
            ? e.message
            : '가이드를 생성하지 못했어요. 잠시 후 다시 시도해주세요.';
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: ChowColors.gray50,
        centerTitle: false,
        title: const Text('사료 교체 가이드'),
      ),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '지금 먹이고 있는 사료와 새로 바꿀 사료를 알려주시면,\nAI가 배탈 없이 적응할 수 있는 배합 비율을 단계별로 추천해드려요.',
                  style: TextStyle(color: ChowColors.gray600, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                if (_pets.isNotEmpty) ...[
                  const Text('반려동물', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PetModel>(
                    initialValue: _selectedPet,
                    items: _pets
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.petName)))
                        .toList(),
                    onChanged: (p) => setState(() => _selectedPet = p),
                  ),
                  const SizedBox(height: 20),
                ],
                _FoodPickerField(
                  label: '현재 급여 중인 사료',
                  selected: _currentFood,
                  petType: _selectedPet?.petType,
                  onSelected: (f) => setState(() => _currentFood = f),
                  onClear: () => setState(() => _currentFood = null),
                ),
                const SizedBox(height: 20),
                _FoodPickerField(
                  label: '바꿀 사료',
                  selected: _targetFood,
                  petType: _selectedPet?.petType,
                  onSelected: (f) => setState(() => _targetFood = f),
                  onClear: () => setState(() => _targetFood = null),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_currentFood != null && _targetFood != null && !_generating)
                        ? _generate
                        : null,
                    child: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('교체 가이드 생성'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: ChowColors.red500)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  _FoodTransitionResultView(result: _result!),
                ],
              ],
            ),
    );
  }
}

class _FoodPickerField extends StatelessWidget {
  const _FoodPickerField({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.onClear,
    this.petType,
  });

  final String label;
  final CommercialFoodModel? selected;
  final ValueChanged<CommercialFoodModel> onSelected;
  final VoidCallback onClear;
  final String? petType;

  Future<void> _pick(BuildContext context) async {
    final picked = await context.push<CommercialFoodModel>(
      '/food-info',
      extra: {'selectMode': true, 'allowUserFoods': true, 'lockedPetType': petType},
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (selected != null)
          ChowCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${selected!.brandName} · ${selected!.productName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.search),
            label: const Text('사료 목록에서 선택'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: ChowCozy.stone300),
              foregroundColor: ChowCozy.stone700,
            ),
          ),
      ],
    );
  }
}

class _FoodTransitionResultView extends StatelessWidget {
  const _FoodTransitionResultView({required this.result});
  final FoodTransitionModel result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ChowCozy.stone100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            result.summary,
            style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        for (final step in result.schedule) ...[
          _TransitionStepCard(step: step),
          const SizedBox(height: 10),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('주의사항', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          for (final w in result.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: ChowColors.red500)),
                  Expanded(child: Text(w, style: const TextStyle(color: ChowColors.gray700))),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
        const Text(
          '이 가이드는 일반적인 사료 전환 권장 관행을 참고한 근사치예요. 반려동물의 건강 상태에 따라 다를 수 있으니, '
          '소화기가 예민하거나 지병이 있다면 수의사와 상담 후 진행해주세요.',
          style: TextStyle(fontSize: 12, color: ChowColors.gray500, height: 1.4),
        ),
      ],
    );
  }
}

class _TransitionStepCard extends StatelessWidget {
  const _TransitionStepCard({required this.step});
  final FoodTransitionStepModel step;

  @override
  Widget build(BuildContext context) {
    return ChowCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(step.dayRange, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    Container(color: ChowCozy.stone300),
                    FractionallySizedBox(
                      widthFactor: (step.newFoodPercent / 100).clamp(0.0, 1.0),
                      child: Container(color: ChowCozy.stone700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${step.currentFoodPercent}:${step.newFoodPercent}',
            style: const TextStyle(fontSize: 12, color: ChowColors.gray600),
          ),
        ],
      ),
    );
  }
}
