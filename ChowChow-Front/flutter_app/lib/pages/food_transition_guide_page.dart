import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';

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
          'currentFoodId': _currentFood!.foodId,
          'targetFoodId': _targetFood!.foodId,
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
        _error = 'AI 가이드를 생성하지 못했어요. 잠시 후 다시 시도해주세요.';
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사료 교체 가이드')),
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
                  const Text('반려동물', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  onSelected: (f) => setState(() => _currentFood = f),
                  onClear: () => setState(() => _currentFood = null),
                ),
                const SizedBox(height: 20),
                _FoodPickerField(
                  label: '바꿀 사료',
                  selected: _targetFood,
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

class _FoodPickerField extends StatefulWidget {
  const _FoodPickerField({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.onClear,
  });

  final String label;
  final CommercialFoodModel? selected;
  final ValueChanged<CommercialFoodModel> onSelected;
  final VoidCallback onClear;

  @override
  State<_FoodPickerField> createState() => _FoodPickerFieldState();
}

class _FoodPickerFieldState extends State<_FoodPickerField> {
  final _controller = TextEditingController();
  List<CommercialFoodModel> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    setState(() => _searching = true);
    try {
      final res = await ApiClient.get('/api/v1/foods/search', query: {'query': query}) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _results = res.map((e) => CommercialFoodModel.fromJson(e as Map<String, dynamic>)).toList();
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (widget.selected != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: ChowCozy.stone300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.selected!.brandName} · ${widget.selected!.productName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onClear,
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: '브랜드명 또는 제품명으로 검색'),
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
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: ChowCozy.stone300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _results
                    .map((f) => ListTile(
                          title: Text('${f.brandName} · ${f.productName}', overflow: TextOverflow.ellipsis),
                          subtitle: Text('100g당 ${f.caloriesPer100g?.toStringAsFixed(0) ?? '-'}kcal'),
                          onTap: () {
                            widget.onSelected(f);
                            setState(() => _results = []);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
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
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        for (final step in result.schedule) ...[
          _TransitionStepCard(step: step),
          const SizedBox(height: 10),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('주의사항', style: TextStyle(fontWeight: FontWeight.w600)),
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
      ],
    );
  }
}

class _TransitionStepCard extends StatelessWidget {
  const _TransitionStepCard({required this.step});
  final FoodTransitionStepModel step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: ChowCozy.stone300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(step.dayRange, style: const TextStyle(fontWeight: FontWeight.w700)),
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
