import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

const _kGenSteps = [
  '반려동물 정보 분석 중...',
  '알레르기 정보 확인 중...',
  '영양 균형 계산 중...',
  '맛있는 레시피 생성 중...',
];

const kRecipeGenerateFailedMessage = '레시피를 생성할 수 없습니다. 다시 시도해주세요.';

/// 홈으로 이동한 뒤 레시피 생성 실패 팝업만 표시
void navigateHomeAndShowRecipeGenerationFailed(BuildContext context) {
  GoRouter.of(context).go('/');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final rootCtx = rootNavigatorKey.currentContext;
    if (rootCtx != null) showRecipeGenerationFailedDialog(rootCtx);
  });
}

Future<void> showRecipeGenerationFailedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('레시피 생성 실패'),
      content: const Text(kRecipeGenerateFailedMessage),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ChowColors.orange500),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

class RecipeGenerationPage extends StatefulWidget {
  const RecipeGenerationPage({super.key, this.quickStart = false});

  /// 홈 화면 등에서 바로 생성·로딩·결과 표시
  final bool quickStart;

  @override
  State<RecipeGenerationPage> createState() => _RecipeGenerationPageState();
}

class _RecipeGenerationPageState extends State<RecipeGenerationPage>
    with TickerProviderStateMixin {
  // 'select' | 'generating' | 'result'
  String _phase = 'select';

  List<PetModel> _pets = [];
  PetModel? _selectedPet;
  bool _petsLoading = true;
  DietGenerateModel? _result;
  final _notesCtrl = TextEditingController();

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceY;

  Timer? _progressTimer;
  Timer? _stepTimer;
  int _progress = 0;
  int _currentStep = 0;
  bool _apiDone = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))
      ..repeat(reverse: true);
    _bounceY = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut),
    );
    if (widget.quickStart) {
      _petsLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGeneration());
    } else {
      _loadPets();
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _stepTimer?.cancel();
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    try {
      final res = await ApiClient.get('/api/pets') as List<dynamic>;
      if (!mounted) return;
      final pets = res.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _pets = pets;
        if (pets.length == 1) _selectedPet = pets.first;
        _petsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _petsLoading = false);
    }
  }

  void _startGeneration() {
    if (!widget.quickStart && _pets.isNotEmpty && _selectedPet == null) return;
    _progressTimer?.cancel();
    _stepTimer?.cancel();
    setState(() {
      _phase = 'generating';
      _progress = 0;
      _currentStep = 0;
      _apiDone = false;
      _errorMsg = null;
      _result = null;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      final cap = _apiDone ? 100 : 90;
      if (_progress >= cap) {
        if (_apiDone && _result != null) {
          _progressTimer?.cancel();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _phase = 'result');
          });
        }
        return;
      }
      setState(() => _progress = (_progress + 1).clamp(0, cap));
    });

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        if (_currentStep < _kGenSteps.length - 1) {
          _currentStep++;
        } else {
          _stepTimer?.cancel();
        }
      });
    });

    _callApi();
  }

  Future<void> _callApi() async {
    try {
      final notes = _notesCtrl.text.trim();
      final body = <String, dynamic>{
        if (_selectedPet != null) 'petId': _selectedPet!.petId,
        if (notes.isNotEmpty) 'userNotes': notes,
      };
      final res = await ApiClient.post(
        '/api/ai/diet/recommend-and-save?generateImage=true',
        body,
      ) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _result = DietGenerateModel.fromJson(res);
        _apiDone = true;
      });
      // LLM 식단 생성 코인 적립 (1일 1회)
      ApiClient.post('/api/coins/earn', {'amount': 20, 'reason': 'LLM 식단 생성'}).ignore();
    } catch (e) {
      if (!mounted) return;
      navigateHomeAndShowRecipeGenerationFailed(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_phase) {
        'generating' => _buildGeneratingPhase(),
        'result' => _buildResultPhase(),
        _ => _buildSelectPhase(),
      },
    );
  }

  Widget _buildSelectPhase() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Text('AI 레시피 생성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              child: _petsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pets.isEmpty
                      ? _buildNoPetsView()
                      : _buildPetSelectView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPetsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: ChowColors.orange400, size: 44),
          ),
          const SizedBox(height: 16),
          const Text(
            '등록된 반려동물이 없어요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ChowColors.gray800),
          ),
          const SizedBox(height: 8),
          const Text(
            '반려동물을 등록하면 건강 상태와 알레르기를\n고려한 맞춤 식단을 추천받을 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: ChowColors.gray500, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ChowColors.orange500,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.add),
              label: const Text('반려동물 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '추가 요청사항 (선택)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ChowColors.gray700),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '예) 소형견, 저지방 식단으로 부탁해요...',
              hintStyle: const TextStyle(fontSize: 13, color: ChowColors.gray400),
              filled: true,
              fillColor: ChowColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(_errorMsg!, style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ChowColors.gray600,
                side: const BorderSide(color: ChowColors.gray300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _startGeneration,
              child: const Text('반려동물 없이 AI 레시피 생성', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetSelectView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('어떤 아이를 위한 레시피인가요?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
          const SizedBox(height: 12),
          ..._pets.map((pet) {
            final selected = _selectedPet?.petId == pet.petId;
            return GestureDetector(
              onTap: () => setState(() => _selectedPet = pet),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? ChowColors.orange50 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? ChowColors.orange500 : ChowColors.gray200,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ChowColors.orange100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets, color: ChowColors.orange500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pet.petName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                          Text(
                            '${pet.breedName ?? pet.displayType}${pet.petWeight != null ? ' • ${pet.petWeight!.toStringAsFixed(1)}kg' : ''}',
                            style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: ChowColors.orange500),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text('추가 요청사항 (선택)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ChowColors.gray700)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '예) 닭고기 알러지 있어요, 저지방 식단으로 부탁해요...',
              hintStyle: const TextStyle(fontSize: 13, color: ChowColors.gray400),
              filled: true,
              fillColor: ChowColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(_errorMsg!, style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444)), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _selectedPet != null ? ChowColors.orange500 : ChowColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _selectedPet != null ? _startGeneration : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI 레시피 생성하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingPhase() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: _pulseScale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [ChowColors.orange400, ChowColors.orange500]),
                            boxShadow: [BoxShadow(blurRadius: 12, offset: Offset(0, 4), color: Color(0x33000000))],
                          ),
                          child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 48),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: AnimatedBuilder(
                          animation: _bounceY,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, _bounceY.value),
                            child: child,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFFFACC15), size: 34),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _selectedPet != null
                        ? '${_selectedPet!.petName}를 위한'
                        : '우리 아이를 위한',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: ChowColors.gray900),
                  ),
                  Text(
                    '레시피가 만들어지고 있어요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ChowColors.orange500,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI가 영양 균형을 고려한 맞춤 레시피를\n정성껏 준비하고 있습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ChowColors.gray600, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 10,
                          width: constraints.maxWidth,
                          child: Stack(
                            children: [
                              Container(color: ChowColors.gray200),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                width: constraints.maxWidth * (_progress / 100).clamp(0.0, 1.0),
                                height: 10,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [ChowColors.orange400, ChowColors.orange500]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_progress%', style: const TextStyle(fontSize: 13, color: ChowColors.gray600)),
                      Text(
                        _progress >= 100 ? '완료!' : '생성 중...',
                        style: const TextStyle(fontSize: 13, color: ChowColors.orange500, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ChowColors.orange100),
                      boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x0A000000))],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ChowColors.orange500),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _kGenSteps[_currentStep.clamp(0, _kGenSteps.length - 1)],
                            style: const TextStyle(color: ChowColors.gray700, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_kGenSteps.length, (index) {
                    final active = index <= _currentStep;
                    final done = index < _currentStep;
                    final current = index == _currentStep;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: active ? 1 : 0.3,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? ChowColors.green500
                                    : current
                                        ? ChowColors.orange500
                                        : ChowColors.gray300,
                              ),
                              child: done
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: current ? Colors.white : ChowColors.gray600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _kGenSteps[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: active ? ChowColors.gray700 : ChowColors.gray400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ChowColors.orange50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ChowColors.orange100),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '💡 Tip: ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF9A3412))),
                          TextSpan(
                            text: 'AI가 생성한 레시피는 저장하여 언제든지 다시 확인할 수 있어요!',
                            style: TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultPhase() {
    final recipe = _result!;
    const placeholder =
        'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=800&q=80';

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: ChowColors.gray50,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      '생성된 레시피',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ChowNetworkImage(url: recipe.imageUrl ?? placeholder),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ChowColors.gray900,
                      ),
                    ),
                    if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        recipe.description!,
                        style: const TextStyle(fontSize: 14, color: ChowColors.gray600, height: 1.5),
                      ),
                    ],
                    if (recipe.feedingAmount != null && recipe.feedingAmount!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ChowColors.orange50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ChowColors.orange100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.restaurant, color: ChowColors.orange500, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                recipe.feedingAmount!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF9A3412), height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (recipe.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('재료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                      const SizedBox(height: 10),
                      ...recipe.ingredients.map(
                        (ing) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6, color: ChowColors.orange500),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ing.name,
                                  style: const TextStyle(fontSize: 14, color: ChowColors.gray800),
                                ),
                              ),
                              if (ing.amount != null)
                                Text(ing.amount!, style: const TextStyle(fontSize: 13, color: ChowColors.gray500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (recipe.steps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('조리 방법', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                      const SizedBox(height: 10),
                      ...recipe.steps.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: ChowColors.orange500,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(fontSize: 14, color: ChowColors.gray700, height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (recipe.warnings.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ChowColors.orange100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️ 주의사항', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF9A3412))),
                            const SizedBox(height: 6),
                            ...recipe.warnings.map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $w', style: const TextStyle(fontSize: 12, color: Color(0xFF9A3412), height: 1.4)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: ChowColors.orange500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => context.go('/'),
                        child: const Text('홈으로 돌아가기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
