import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/character_service.dart';
import '../services/models.dart';
import '../services/shop_service.dart';
import '../theme/chow_theme.dart';
import '../theme/shop_visuals.dart';
import '../widgets/chow_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _DashedStadiumBorderPainter extends CustomPainter {
  const _DashedStadiumBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + 5).clamp(0.0, metric.length).toDouble(),
          ),
          paint,
        );
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedStadiumBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ProfilePageState extends State<ProfilePage> {
  static const List<String> _healthFocusOptions = [
    '피부/모질',
    '뼈/관절',
    '치아/구강',
    '위장/소화',
    '체중 관리',
    '신장/비뇨기',
    '심장/혈관',
    '간 건강',
    '눈 건강',
    '귀 건강',
    '면역력',
    '노령 관리',
  ];

  static const List<String> _favoriteFoodOptions = [
    '닭고기',
    '소고기',
    '돼지고기',
    '오리고기',
    '양고기',
    '칠면조',
    '연어',
    '흰살생선',
    '달걀',
    '고구마',
    '단호박',
    '당근',
    '브로콜리',
    '치즈',
  ];

  static const List<String> _diseaseOptions = [
    '신장 질환',
    '비만',
    '당뇨',
    '관절염',
    '피부 질환',
    '심장 질환',
    '췌장염',
    '간 질환',
    '구강 질환',
    '갑상선 질환',
    '염증성 장질환(IBD)',
    '요로결석',
    '식이 과민반응',
    '빈혈',
    '고혈압',
    '저혈당증',
    '암(종양)',
    '노령 관리',
  ];

  UserModel? _user;
  List<PetModel> _pets = [];
  bool _loading = true;
  int _savedRecipes = 0;
  int _completedCooking = 0;
  int _writtenReviews = 0;
  int _coinBalance = 0;
  String _profileFrameKey = 'frame_orange';

  String _petType = '';
  int? _breedId;
  String _breedDisplayName = '';
  List<BreedModel> _availableBreeds = [];
  String _petName = '';
  String _petAge = '';
  bool _isExactBirthdate = true;
  DateTime? _petBirthdate;
  int _petAgeYears = 0;
  int _petAgeMonths = 0;
  String _petWeight = '';
  List<AllergyModel> _allAllergies = [];
  List<int> _selectedAllergyIds = [];
  String? _petGender;
  bool _isNeutered = false;
  int? _bodyConditionScore;
  int? _activityLevel;
  final List<String> _foodTypes = [];
  final List<String> _healthFocusAreas = [];
  final List<String> _favoriteFoods = [];
  final List<String> _diseases = [];
  bool _noHealthFocus = false;
  bool _noFavoriteFood = false;
  bool _noAllergy = false;
  bool _noDisease = false;
  final List<String> _priorities = [];
  final List<String> _livingSpaces = [];
  final List<String> _daytimeRoutines = [];
  final List<String> _behaviorConcerns = [];

  List<_ProfileNotice> _notifications = [];

  bool get _isPetFormValid {
    return _petType.isNotEmpty &&
        _petName.trim().isNotEmpty &&
        _petWeight.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadShopStyle();
  }

  Future<void> _loadShopStyle() async {
    try {
      final catalog = await ShopService.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _coinBalance = catalog.balance;
        _profileFrameKey = catalog.equippedProfileFrameKey;
      });
    } catch (_) {}
  }

  Future<void> _openCoinShop() async {
    await context.push('/coin-shop');
    if (!mounted) return;
    await _loadShopStyle();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/api/users/me'),
        ApiClient.get('/api/pets'),
        ApiClient.get(
          '/api/users/me/stats',
        ).catchError((_) => <String, dynamic>{}),
        ApiClient.get('/api/notifications').catchError((_) => <dynamic>[]),
        ApiClient.get('/api/v1/allergies').catchError((_) => <dynamic>[]),
      ]);

      if (!mounted) return;

      final stats = results[2] as Map<String, dynamic>? ?? {};
      final rawNotifs = results[3] as List<dynamic>? ?? [];
      final rawAllergies = results[4] as List<dynamic>? ?? [];

      setState(() {
        _user = UserModel.fromJson(results[0] as Map<String, dynamic>);
        _pets = (results[1] as List<dynamic>)
            .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _allAllergies = rawAllergies
            .map((e) => AllergyModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _savedRecipes = (stats['savedRecipes'] as num?)?.toInt() ?? 0;
        _completedCooking = (stats['completedCooking'] as num?)?.toInt() ?? 0;
        _writtenReviews = (stats['writtenReviews'] as num?)?.toInt() ?? 0;
        _notifications = rawNotifs.map((e) {
          final m = e as Map<String, dynamic>;
          final createdAt = m['createdAt'] as String?;
          final timeStr = createdAt != null ? _formatNotifTime(createdAt) : '';
          return _ProfileNotice(
            type: m['notificationType'] as String? ?? 'notice',
            title:
                m['notificationTitle'] as String? ??
                m['title'] as String? ??
                '알림',
            message:
                m['notificationContent'] as String? ??
                m['message'] as String? ??
                '',
            time: timeStr,
            isNew: !(m['isRead'] as bool? ?? false),
          );
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatNotifTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      return '${diff.inDays}일 전';
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleLogout() async {
    try {
      await ApiClient.post('/api/auth/logout', {}, auth: true);
    } catch (_) {}

    await ApiClient.clearToken();

    if (mounted) {
      context.go('/login');
    }
  }

  void _resetPetForm() {
    _petType = '';
    _breedId = null;
    _breedDisplayName = '';
    _availableBreeds = [];
    _petName = '';
    _petAge = '';
    _isExactBirthdate = true;
    _petBirthdate = null;
    _petAgeYears = 0;
    _petAgeMonths = 0;
    _petWeight = '';
    _selectedAllergyIds = [];
    _petGender = null;
    _isNeutered = false;
    _bodyConditionScore = null;
    _activityLevel = null;
    _foodTypes.clear();
    _healthFocusAreas.clear();
    _favoriteFoods.clear();
    _diseases.clear();
    _noHealthFocus = false;
    _noFavoriteFood = false;
    _noAllergy = false;
    _noDisease = false;
    _priorities.clear();
    _livingSpaces.clear();
    _daytimeRoutines.clear();
    _behaviorConcerns.clear();
  }

  double? _parseWeight(String value) {
    final cleaned = value
        .replaceAll('kg', '')
        .replaceAll('KG', '')
        .replaceAll('Kg', '')
        .trim();

    return double.tryParse(cleaned);
  }

  // "3살", "2살" 같은 문자열을 ISO 날짜 문자열로 변환
  String? _ageToBirthdate(String age) {
    final match = RegExp(r'(\d+)').firstMatch(age);
    if (match == null) return null;
    final years = int.tryParse(match.group(1)!);
    if (years == null) return null;
    final birth = DateTime(
      DateTime.now().year - years,
      DateTime.now().month,
      DateTime.now().day,
    );
    return '${birth.year}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitPetForm() async {
    if (!_isPetFormValid) return;

    final body = <String, dynamic>{
      'petName': _petName.trim(),
      'petType': _petType == 'dog' ? 'DOG' : 'CAT',
      if (_breedId != null) 'breedId': _breedId,
      if (_parseWeight(_petWeight) != null)
        'petWeight': _parseWeight(_petWeight),
      if (_isExactBirthdate && _petBirthdate != null)
        'petBirthdate': _formatBirthdate(_petBirthdate!)
      else if (!_isExactBirthdate)
        'petBirthdate': _approximateBirthdate(),
      if (_selectedAllergyIds.isNotEmpty) 'allergyIds': _selectedAllergyIds,
      if (_petGender != null) 'petGender': _petGender,
      'isNeutered': _isNeutered,
      if (_bodyConditionScore != null) 'petBodyConditionScore': _bodyConditionScore,
      if (_activityLevel != null) 'petActivityLevel': _activityLevel,
      if (_healthFocusAreas.isNotEmpty) 'healthFocusAreas': _healthFocusAreas,
    };

    try {
      await ApiClient.post('/api/pets', body, auth: true);

      if (!mounted) return;

      Navigator.of(context).pop();

      setState(() {
        _resetPetForm();
        _loading = true;
      });

      await _loadProfile();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반려동물 추가에 실패했습니다. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  void _openAddPetSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateForm(VoidCallback callback) {
              setModalState(callback);
              setState(() {});
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                        child: Row(
                          children: [
                            const Text(
                              '반려동물 추가',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: ChowColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          children: [
                            _buildPetTypeSelector(updateForm),
                            const SizedBox(height: 22),
                            if (_petType.isNotEmpty) ...[
                              _buildBreedSelector(updateForm),
                              const SizedBox(height: 22),
                            ],
                            _buildPetInputField(
                              label: '이름',
                              required: true,
                              hintText: '반려동물 이름을 입력하세요',
                              onChanged: (value) {
                                updateForm(() => _petName = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildBirthdateSelector(updateForm),
                            const SizedBox(height: 18),
                            _buildPetWeightBcsField(updateForm),
                            const SizedBox(height: 18),
                            _buildPetLifestyleFields(updateForm),
                            const SizedBox(height: 24),
                            const Divider(height: 10, thickness: 10, color: ChowColors.gray100),
                            const SizedBox(height: 24),
                            _buildPreferenceSections(updateForm),
                            const SizedBox(height: 24),
                            const Divider(height: 10, thickness: 10, color: ChowColors.gray100),
                            const SizedBox(height: 24),
                            _buildPetOptionGroup(label: '가장 중요한 우선순위', options: const ['균형 잡힌 식사', '체중 & 영양', '실시간 행동', '건강 추적'], selected: _priorities, onChanged: (value) => updateForm(() => _toggleSingle(_priorities, value))),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '주 생활 공간', options: const ['실내', '마당', '테라스 / 발코니'], selected: _livingSpaces, onChanged: (value) => updateForm(() => _toggleSingle(_livingSpaces, value))),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '낮 시간을 보내는 방법', options: const ['집에 혼자 있어요', '유치원에 가요', '산책 도우미와 함께해요', '항상 가족과 함께해요'], selected: _daytimeRoutines, onChanged: (value) => updateForm(() => _toggleSingle(_daytimeRoutines, value))),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '궁금하거나 걱정되는 행동', options: const ['분리 불안 / 짖음', '수면 / 휴식 패턴', '식이 / 음수 습관', '전반적 활동량'], selected: _behaviorConcerns, onChanged: (value) => updateForm(() => _toggleSingle(_behaviorConcerns, value))),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isPetFormValid
                                    ? _submitPetForm
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ChowCozy.stone500,
                                  disabledBackgroundColor: ChowColors.gray300,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  '추가하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _resetPetForm();
        });
      }
    });
  }

  Widget _buildPetTypeSelector(void Function(VoidCallback) updateForm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetLabel('반려동물 종류', required: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPetTypeButton(
                emoji: '🐶',
                label: '강아지',
                selected: _petType == 'dog',
                onTap: () async {
                  updateForm(() {
                    _petType = 'dog';
                    _breedId = null;
                    _breedDisplayName = '';
                    _availableBreeds = [];
                  });
                  final breeds = await CharacterService.fetchBreeds('DOG');
                  updateForm(() => _availableBreeds = breeds);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPetTypeButton(
                emoji: '🐱',
                label: '고양이',
                selected: _petType == 'cat',
                onTap: () async {
                  updateForm(() {
                    _petType = 'cat';
                    _breedId = null;
                    _breedDisplayName = '';
                    _availableBreeds = [];
                  });
                  final breeds = await CharacterService.fetchBreeds('CAT');
                  updateForm(() => _availableBreeds = breeds);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPetTypeButton({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? ChowCozy.stone100 : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ChowCozy.stone500 : ChowColors.gray200,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: ChowColors.gray800),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                const Icon(Icons.check, color: ChowCozy.stone500, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreedSelector(void Function(VoidCallback) updateForm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetLabel('품종', required: false),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _availableBreeds.isEmpty
                ? null
                : () {
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            itemCount: _availableBreeds.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final breed = _availableBreeds[index];
                              return ListTile(
                                title: Text(
                                  breed.displayName,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                trailing: _breedId == breed.breedId
                                    ? const Icon(
                                        Icons.check,
                                        color: ChowCozy.stone500,
                                      )
                                    : null,
                                onTap: () {
                                  updateForm(() {
                                    _breedId = breed.breedId;
                                    _breedDisplayName = breed.displayName;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ChowColors.gray300),
              ),
              child: _availableBreeds.isEmpty
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ChowCozy.stone500,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '품종 불러오는 중...',
                          style: TextStyle(
                            color: ChowColors.gray500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _breedDisplayName.isEmpty
                          ? '품종을 선택하세요 (선택)'
                          : _breedDisplayName,
                      style: TextStyle(
                        color: _breedDisplayName.isEmpty
                            ? ChowColors.gray500
                            : const Color(0xFF111827),
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetLifestyleFields(void Function(VoidCallback) updateForm) {
    const foodOptions = ['건식', '습식', '동결건조', '소프트 (반습식)', '자연식 (화식/생식)', '홈메이드'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetLabel('성별', required: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLargeChoiceButton(label: '남아', selected: _petGender == 'MALE', onTap: () => updateForm(() => _petGender = 'MALE'))),
            const SizedBox(width: 12),
            Expanded(child: _buildLargeChoiceButton(label: '여아', selected: _petGender == 'FEMALE', onTap: () => updateForm(() => _petGender = 'FEMALE'))),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _isNeutered,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: ChowCozy.stone700,
          title: const Text('중성화 수술 완료', style: TextStyle(fontSize: 15, color: ChowColors.gray600)),
          onChanged: (value) => updateForm(() => _isNeutered = value ?? false),
        ),
        const SizedBox(height: 18),
        _buildPetLabel('하루 산책', required: true),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final option in const [('30분 미만', 1), ('30분–1시간', 3), ('1시간 이상', 5)]) ...[
              if (option.$2 != 1) const SizedBox(width: 8),
              Expanded(child: _buildLargeChoiceButton(label: option.$1, selected: _activityLevel == option.$2, compact: true, onTap: () => updateForm(() => _activityLevel = option.$2))),
            ],
          ],
        ),
        const SizedBox(height: 22),
        _buildPetLabel('주식 형태', required: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: foodOptions.map((option) {
            final selected = _foodTypes.contains(option);
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => updateForm(() => _toggle(_foodTypes, option)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? ChowCozy.stone700 : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? ChowCozy.stone700 : ChowColors.gray300),
                ),
                child: Text(option, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: selected ? Colors.white : ChowColors.gray600)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLargeChoiceButton({required String label, required bool selected, required VoidCallback onTap, bool compact = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: compact ? 54 : 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ChowCozy.stone700 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? ChowCozy.stone700 : ChowColors.gray300),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w400, color: selected ? Colors.white : ChowColors.gray800)),
      ),
    );
  }

  void _toggle(List<String> values, String value, {int? limit}) {
    if (value == '해당 없음') {
      values
        ..clear()
        ..add(value);
      return;
    }
    values.remove('해당 없음');
    if (values.contains(value)) {
      values.remove(value);
    } else if (limit == null || values.length < limit) {
      values.add(value);
    }
  }

  void _toggleSingle(List<String> values, String value) {
    if (values.length == 1 && values.first == value) {
      values.clear();
      return;
    }
    values
      ..clear()
      ..add(value);
  }

  Widget _buildPetOptionGroup({
    required String label,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onChanged,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetLabel(label, required: false),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final itemWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: options.map((option) {
                final isSelected = selected.contains(option);
                return SizedBox(
                  width: itemWidth,
                  height: 58,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? ChowCozy.stone700 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? ChowCozy.stone700 : ChowColors.gray300,
                        ),
                      ),
                      child: Text(
                        option,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isSelected ? Colors.white : ChowColors.gray700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper, style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
        ],
      ],
    );
  }

  Widget _buildPreferenceSections(void Function(VoidCallback) updateForm) {
    final allergyLabels = _selectedAllergyIds.map((id) {
      for (final item in _allAllergies) {
        if (item.allergyId == id) return item.allergyName;
      }
      return null;
    }).whereType<String>().toList();
    final allergyOptions = _allAllergies
        .map((item) => item.allergyName)
        .toSet()
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAddableSection(
          label: '건강 고민',
          selected: _healthFocusAreas,
          noneSelected: _noHealthFocus,
          onNone: () => updateForm(() { _healthFocusAreas.clear(); _noHealthFocus = true; }),
          onRemove: (value) => updateForm(() => _healthFocusAreas.remove(value)),
          helper: '최대 3개까지 선택할 수 있어요.',
          onAdd: () => _openSelectionSheet(
            title: '건강 고민',
            options: _healthFocusOptions,
            selected: _healthFocusAreas,
            maxSelections: 3,
            onDone: (values) => updateForm(() { _healthFocusAreas..clear()..addAll(values); _noHealthFocus = false; }),
          ),
        ),
        const SizedBox(height: 24),
        _buildAddableSection(
          label: '좋아하는 음식',
          selected: _favoriteFoods,
          noneSelected: _noFavoriteFood,
          onNone: () => updateForm(() { _favoriteFoods.clear(); _noFavoriteFood = true; }),
          onRemove: (value) => updateForm(() => _favoriteFoods.remove(value)),
          onAdd: () => _openSelectionSheet(
            title: '좋아하는 음식',
            options: _favoriteFoodOptions,
            selected: _favoriteFoods,
            onDone: (values) => updateForm(() { _favoriteFoods..clear()..addAll(values); _noFavoriteFood = false; }),
          ),
        ),
        const SizedBox(height: 24),
        _buildAddableSection(
          label: '알레르기',
          selected: allergyLabels,
          noneSelected: _noAllergy,
          onNone: () => updateForm(() { _selectedAllergyIds = []; _noAllergy = true; }),
          onRemove: (value) => updateForm(() {
            _selectedAllergyIds.removeWhere((id) => _allAllergies.any((item) => item.allergyId == id && item.allergyName == value));
          }),
          onAdd: () => _openSelectionSheet(
            title: '알레르기',
            options: allergyOptions,
            selected: allergyLabels,
            onDone: (values) => updateForm(() {
              _selectedAllergyIds = _allAllergies.where((item) => values.contains(item.allergyName)).map((item) => item.allergyId).toList();
              _noAllergy = false;
            }),
          ),
        ),
        const SizedBox(height: 24),
        _buildAddableSection(
          label: '질환',
          selected: _diseases,
          noneSelected: _noDisease,
          onNone: () => updateForm(() { _diseases.clear(); _noDisease = true; }),
          onRemove: (value) => updateForm(() => _diseases.remove(value)),
          onAdd: () => _openSelectionSheet(
            title: '질환',
            options: _diseaseOptions,
            selected: _diseases,
            onDone: (values) => updateForm(() { _diseases..clear()..addAll(values.where((value) => value != '해당 없음')); _noDisease = false; }),
          ),
        ),
      ],
    );
  }

  Widget _buildAddableSection({required String label, required List<String> selected, required bool noneSelected, required VoidCallback onAdd, required VoidCallback onNone, required ValueChanged<String> onRemove, String? helper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetLabel(label, required: true),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _noneSelectionButton(selected: noneSelected, onTap: onNone),
            if (selected.isNotEmpty) ...selected.map((value) => _selectedSummaryChip(value, () => onRemove(value))),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(999),
              child: CustomPaint(
                painter: const _DashedStadiumBorderPainter(color: ChowColors.gray300),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 19, color: ChowCozy.stone800),
                      SizedBox(width: 5),
                      Text('추가', style: TextStyle(fontSize: 13, color: ChowCozy.stone800)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(helper, style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
        ],
      ],
    );
  }

  Widget _selectedSummaryChip(String value, VoidCallback onRemove) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(color: ChowColors.gray100, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 13, color: ChowColors.gray700)),
        const SizedBox(width: 6),
        InkWell(
          onTap: onRemove,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.close, size: 16, color: ChowColors.gray500),
        ),
      ],
    ),
  );

  Widget _noneSelectionButton({required bool selected, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? ChowCozy.stone700 : Colors.white,
        border: Border.all(color: selected ? ChowCozy.stone700 : ChowColors.gray300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '해당 없음',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: selected ? Colors.white : ChowColors.gray600),
      ),
    ),
  );

  Future<void> _openSelectionSheet({required String title, required List<String> options, required List<String> selected, required ValueChanged<List<String>> onDone, int? maxSelections}) async {
    final temporary = List<String>.from(selected);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => FractionallySizedBox(
          heightFactor: 0.78,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(color: ChowColors.gray300, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  Expanded(
                    child: options.isEmpty
                        ? const Center(child: Text('선택할 수 있는 항목이 없습니다.', style: TextStyle(color: ChowColors.gray500)))
                        : ListView.separated(
                            itemCount: options.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: ChowColors.gray200),
                            itemBuilder: (context, index) {
                              final option = options[index];
                              final checked = temporary.contains(option);
                              return InkWell(
                                onTap: () => setSheet(() {
                                  if (checked) {
                                    temporary.remove(option);
                                  } else if (maxSelections == null || temporary.length < maxSelections) {
                                    temporary.add(option);
                                  }
                                }),
                                child: SizedBox(
                                  height: 58,
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(option, style: const TextStyle(fontSize: 16, color: ChowColors.gray800))),
                                      if (checked) const Icon(Icons.check, color: ChowCozy.stone700, size: 24),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        onDone(temporary);
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(backgroundColor: ChowCozy.stone700, foregroundColor: Colors.white),
                      child: const Text('완료', style: TextStyle(fontSize: 16)),
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

  Widget _buildAllergySelector(void Function(VoidCallback) updateForm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetLabel('알러지', required: false),
        const SizedBox(height: 8),
        if (_allAllergies.isEmpty)
          const Text(
            '알러지 목록을 불러오는 중...',
            style: TextStyle(color: ChowColors.gray500, fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _allAllergies.map((a) {
              final selected = _selectedAllergyIds.contains(a.allergyId);
              return GestureDetector(
                onTap: () {
                  updateForm(() {
                    if (selected) {
                      _selectedAllergyIds = List.from(_selectedAllergyIds)
                        ..remove(a.allergyId);
                    } else {
                      _selectedAllergyIds = [
                        ..._selectedAllergyIds,
                        a.allergyId,
                      ];
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? ChowCozy.stone300 : Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? ChowCozy.stone500
                          : ChowColors.gray300,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    a.allergyName,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected
                          ? ChowCozy.stone700
                          : ChowColors.gray700,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _formatBirthdate(DateTime value) =>
      '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

  String _approximateBirthdate() {
    final today = DateTime.now();
    return _formatBirthdate(DateTime(today.year - _petAgeYears, today.month - _petAgeMonths, today.day));
  }

  Widget _buildBirthdateSelector(void Function(VoidCallback) updateForm) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildPetLabel('생년월일', required: true),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: ChowColors.gray100, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final exact in [true, false]) Expanded(child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => updateForm(() => _isExactBirthdate = exact),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: _isExactBirthdate == exact ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: _isExactBirthdate == exact ? const [BoxShadow(color: Colors.black12, blurRadius: 4)] : null),
              child: Text(exact ? '정확한 날짜' : '대략', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: _isExactBirthdate == exact ? ChowColors.gray900 : ChowColors.gray500))),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      if (_isExactBirthdate)
        OutlinedButton.icon(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _petBirthdate ?? DateTime.now(),
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
              builder: (context, child) {
                final theme = Theme.of(context);
                return Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: ChowColors.gray800,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: ChowColors.gray900,
                    ),
                    datePickerTheme: const DatePickerThemeData(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      headerBackgroundColor: Colors.white,
                      headerForegroundColor: ChowColors.gray900,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) updateForm(() => _petBirthdate = date);
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Align(alignment: Alignment.centerLeft, child: Text(_petBirthdate == null ? '생년월일 선택' : _formatBirthdate(_petBirthdate!))),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), alignment: Alignment.centerLeft, side: const BorderSide(color: ChowColors.gray300), foregroundColor: ChowColors.gray700),
        )
      else
        Row(children: [
          Expanded(child: _buildAgeStepper('년', _petAgeYears, 30, (v) => updateForm(() => _petAgeYears = v))),
          const SizedBox(width: 12),
          Expanded(child: _buildAgeStepper('개월', _petAgeMonths, 11, (v) => updateForm(() => _petAgeMonths = v))),
        ]),
    ]);
  }

  Widget _buildAgeStepper(
    String label,
    int value,
    int max,
    ValueChanged<int> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: ChowColors.gray700)),
      const SizedBox(height: 6),
      Container(
        height: 64,
        decoration: BoxDecoration(
          border: Border.all(color: ChowColors.gray300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _openPetWeightBcsSheet(void Function(VoidCallback) updateForm) async {
    final weightController = TextEditingController(text: _petWeight);
    var temporaryWeight = _petWeight;
    var temporaryBcs = _bodyConditionScore;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final parsedWeight = _parseWeight(temporaryWeight);
          final canSave = parsedWeight != null && parsedWeight > 0 && temporaryBcs != null;
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Text('체중 기록', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text('체중 *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '예) 4.5',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Center(
                      widthFactor: 1,
                      child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: ChowColors.gray800,
                          ),
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(minWidth: 56),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: ChowColors.gray300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: ChowCozy.stone500, width: 2)),
                  ),
                  onChanged: (value) => setSheet(() => temporaryWeight = value),
                ),
                const SizedBox(height: 16),
                const Text('신체충실지수 (BCS) *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(9, (index) {
                    final selected = temporaryBcs == index + 1;
                    return InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setSheet(() => temporaryBcs = index + 1),
                      child: Container(
                        width: 34, height: 34, alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? ChowCozy.stone700 : Colors.white, border: Border.all(color: selected ? ChowCozy.stone700 : ChowColors.gray300)),
                        child: Text('${index + 1}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? Colors.white : ChowColors.gray600)),
                      ),
                    );
                  }),
                ),
                if (temporaryBcs != null) ...[
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Image.asset(
                      'assets/images/BCS_$temporaryBcs.png',
                      key: ValueKey(temporaryBcs),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: canSave
                        ? () {
                            updateForm(() {
                              _petWeight = temporaryWeight.trim();
                              _bodyConditionScore = temporaryBcs;
                            });
                            Navigator.of(ctx).pop();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChowCozy.stone700,
                      disabledBackgroundColor: ChowColors.gray300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('저장', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
    weightController.dispose();
  }

  Widget _buildPetWeightBcsField(void Function(VoidCallback) updateForm) {
    return InkWell(
      onTap: () => _openPetWeightBcsSheet(updateForm),
      child: IgnorePointer(
        child: _buildPetInputField(
          label: '체중 / BCS',
          required: true,
          hintText: _petWeight.isEmpty ? '체중 & BCS 설정' : '${_petWeight}kg · BCS ${_bodyConditionScore ?? '-'}',
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildPetInputField({
    required String label,
    required bool required,
    required String hintText,
    String? helperText,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetLabel(label, required: required),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: ChowColors.gray500, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ChowColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ChowCozy.stone500,
                width: 2,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
          ),
        ],
      ],
    );
  }

  Widget _buildPetLabel(String text, {required bool required}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14, color: ChowColors.gray700),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: ChowCozy.stone500),
            ),
        ],
      ),
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ChowColors.gray300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '알림',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: ChowColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 48,
                                  color: ChowColors.gray300,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '알림이 없어요',
                                  style: TextStyle(
                                    color: ChowColors.gray500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _notifications.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];

                              return Material(
                                color: item.isNew
                                    ? const Color(0xFFFDF7EA)
                                    : Colors.white,
                                child: InkWell(
                                  onTap: () {
                                    if (!item.isNew) return;

                                    setModalState(() {
                                      _notifications[index] = item.copyWith(
                                        isNew: false,
                                      );
                                    });

                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _noticeBg(item.type),
                                          child: Icon(
                                            _noticeIcon(item.type),
                                            color: _noticeFg(item.type),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                item.message,
                                                style: const TextStyle(
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.time,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: ChowColors.gray500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 12,
                                          child: Center(
                                            child: item.isNew
                                                ? Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: ChowColors
                                                              .orange500,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  IconData _noticeIcon(String type) {
    switch (type) {
      case 'recipe':
        return Icons.restaurant_menu;
      case 'achievement':
        return Icons.auto_awesome;
      case 'community':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _noticeBg(String type) {
    switch (type) {
      case 'recipe':
        return ChowCozy.stone300;
      case 'achievement':
        return const Color(0xFFFDF2C9);
      case 'community':
        return const Color(0xFFDBEAFE);
      default:
        return ChowColors.gray100;
    }
  }

  Color _noticeFg(String type) {
    switch (type) {
      case 'recipe':
        return ChowCozy.stone500;
      case 'achievement':
        return ChowColors.yellow600;
      case 'community':
        return ChowColors.blue500;
      default:
        return ChowColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _user?.displayName ?? '사용자';
    final userEmail = _user?.authEmail ?? '';
    final profileFrame = profileFrameVisualFor(_profileFrameKey);

    return ColoredBox(
      color: ChowColors.gray50,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: ChowCozy.stone500,
                    padding: const EdgeInsets.fromLTRB(20, 48, 8, 40),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: profileFrame.colors,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: profileFrame.shadowColor,
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 34,
                                  color: Colors.deepPurple.shade300,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userEmail,
                                      style: const TextStyle(
                                        color: Color(0xD9FFFFFF),
                                        fontSize: 13,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.push('/app-settings'),
                              padding: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.bookmark_border,
                                value: '$_savedRecipes',
                                label: '저장한 레시피',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.check_circle_outline,
                                value: '$_completedCooking',
                                label: '조리 완료',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.rate_review_outlined,
                                value: '$_writtenReviews',
                                label: '작성한 리뷰',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Material(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      elevation: 2,
                      shadowColor: Color(0x14000000),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    '우리 아이들',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: ChowColors.gray800,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _openAddPetSheet,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '+ 추가하기',
                                    style: TextStyle(
                                      color: ChowCozy.stone500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_pets.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    '등록된 반려동물이 없습니다.',
                                    style: TextStyle(color: ChowColors.gray500),
                                  ),
                                ),
                              )
                            else
                              ..._pets.map(
                                (pet) => _PetRow(
                                  pet: pet,
                                  onDeleted: _loadProfile,
                                  onUpdated: _loadProfile,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MenuSection(
                    title: '내 활동',
                    items: [
                      _MenuItem(
                        label: '내가 작성한 글',
                        icon: Icons.edit_note,
                        onTap: () => context.push('/my-posts'),
                      ),
                      _MenuItem(
                        label: '저장한 글',
                        icon: Icons.bookmark_border,
                        onTap: () => context.push('/saved-posts'),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MenuSection(
                    title: '계정',
                    items: [
                      _MenuItem(
                        label: '알림',
                        icon: Icons.notifications_none,
                        badge: _notifications.where((e) => e.isNew).isNotEmpty
                            ? '${_notifications.where((e) => e.isNew).length}'
                            : null,
                        onTap: _openNotificationsSheet,
                      ),
                      _MenuItem(
                        label: '앱 설정',
                        icon: Icons.settings_outlined,
                        onTap: () => context.push('/app-settings'),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MenuSection(
                    title: '꾸미기',
                    items: [
                      _MenuItem(
                        label: '코인 상점',
                        icon: Icons.storefront_outlined,
                        badge: '🪙 $_coinBalance',
                        onTap: _openCoinShop,
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MenuSection(
                    title: '지원',
                    items: [
                      _MenuItem(
                        label: 'AI 챗봇 상담',
                        icon: Icons.chat_bubble_outline,
                        onTap: () => context.push('/ai-chat'),
                      ),
                      _MenuItem(
                        label: '공지사항',
                        icon: Icons.campaign_outlined,
                        onTap: () => context.push('/notices'),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          '펫푸드 레시피 v1.0.0',
                          style: TextStyle(
                            fontSize: 13,
                            color: ChowColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                '이용약관',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ChowColors.gray500,
                                ),
                              ),
                            ),
                            const Text(
                              '|',
                              style: TextStyle(color: ChowColors.gray300),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                '개인정보처리방침',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ChowColors.gray500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ChowColors.red500,
                        side: BorderSide.none,
                        backgroundColor: Colors.transparent,
                      ),
                      icon: const Icon(Icons.logout, color: ChowColors.red500),
                      label: const Text('로그아웃'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 10.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetRow extends StatefulWidget {
  const _PetRow({required this.pet, this.onDeleted, this.onUpdated});
  final PetModel pet;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;
  @override
  State<_PetRow> createState() => _PetRowState();
}

class _PetRowState extends State<_PetRow> {
  static const _placeholder =
      'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=400&q=80';

  PetModel get pet => widget.pet;

  String get _breedAgeLine {
    final breed = pet.breedName?.isNotEmpty == true ? pet.breedName : pet.displayType;
    final group = pet.groupName?.isNotEmpty == true ? pet.groupName : null;
    final age = _ageLabel;

    List<String> parts = [];

    if (breed != null && breed.isNotEmpty) {
      parts.add(breed);
    }
    if (group != null && group.isNotEmpty) {
      parts.add(group);
    }
    if (age != null && age.isNotEmpty) {
      parts.add(age);
    }

    return parts.isNotEmpty ? parts.join(' • ') : pet.displayType;
  }

  String? get _ageLabel {
    final birthRaw = pet.petBirthdate;
    if (birthRaw == null || birthRaw.isEmpty) return null;
    final birth = DateTime.tryParse(birthRaw);
    if (birth == null) return null;
    var years = DateTime.now().year - birth.year;
    final now = DateTime.now();
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    if (years < 1) return '1살 미만';
    return '$years살';
  }

  String? get _weightLabel {
    final w = pet.petWeight;
    if (w == null) return null;
    final rounded = w == w.roundToDouble()
        ? w.toInt().toString()
        : w.toStringAsFixed(1);
    return '체중: ${rounded}kg';
  }

  Future<void> _deletePet() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('반려동물 삭제'),
            content: Text(
              '${pet.petName}을(를) 정말 삭제하시겠습니까?\n삭제하면 관련 정보도 함께 삭제됩니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    try {
      await ApiClient.delete('/api/pets/${pet.petId}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('반려동물이 삭제되었습니다.')));
        widget.onDeleted?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 실패: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _openPetDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ChowColors.gray300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: ChowNetworkImage(
                          url: pet.petProfileImg ?? _placeholder,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: ChowCozy.stone500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '사진을 탭하면 변경할 수 있어요',
                style: TextStyle(fontSize: 12, color: ChowColors.gray500),
              ),
              const SizedBox(height: 16),
              Text(
                pet.petName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ChowColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _breedAgeLine,
                style: const TextStyle(fontSize: 14, color: ChowColors.gray500),
              ),
              if (_weightLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  _weightLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ChowColors.gray600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _CharacteristicsSummary(pet: pet),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openEditCharacteristicsSheet(context);
                  },
                  icon: const Icon(Icons.tune, color: ChowCozy.stone500),
                  label: const Text(
                    '특징 수정',
                    style: TextStyle(color: ChowCozy.stone500),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ChowCozy.stone300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _deletePet();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    '삭제하기',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _activityLabels = ['매우 적음', '적음', '보통', '많음', '매우 많음'];
  static const _healthFocusOptions = [
    '피부/모질', '관절', '소화기', '비뇨기', '치아/구강', '눈/귀', '체중 관리', '심장',
  ];

  void _openEditCharacteristicsSheet(BuildContext context) {
    int bcs = pet.petBodyConditionScore ?? 5;
    int activity = pet.petActivityLevel ?? 3;
    List<String> healthFocus = List.from(pet.healthFocusAreas);
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('반려동물 특징 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Text('체형 점수 (BCS): $bcs / 9', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Text('1(마름) ~ 5(적정) ~ 9(비만)', style: TextStyle(fontSize: 12, color: ChowColors.gray500)),
                Slider(
                  value: bcs.toDouble(),
                  min: 1,
                  max: 9,
                  divisions: 8,
                  activeColor: ChowCozy.stone500,
                  label: '$bcs',
                  onChanged: (v) => setSheet(() => bcs = v.round()),
                ),
                const SizedBox(height: 12),
                Text('활동량: ${_activityLabels[activity - 1]}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Slider(
                  value: activity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: ChowCozy.stone500,
                  label: _activityLabels[activity - 1],
                  onChanged: (v) => setSheet(() => activity = v.round()),
                ),
                const SizedBox(height: 12),
                const Text('관심 건강 부위 (최대 3개)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _healthFocusOptions.map((area) {
                    final selected = healthFocus.contains(area);
                    return ChoiceChip(
                      label: Text(area),
                      selected: selected,
                      selectedColor: ChowCozy.stone100,
                      onSelected: (v) => setSheet(() {
                        if (v) {
                          if (healthFocus.length < 3) healthFocus.add(area);
                        } else {
                          healthFocus.remove(area);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            try {
                              await ApiClient.patch('/api/pets/${pet.petId}', {
                                'petName': pet.petName,
                                'petType': pet.petType,
                                'petBodyConditionScore': bcs,
                                'petActivityLevel': activity,
                                'healthFocusAreas': healthFocus,
                              });
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              widget.onUpdated?.call();
                            } catch (_) {
                              setSheet(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('저장에 실패했어요. 잠시 후 다시 시도해주세요.')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChowCozy.stone500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('저장하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightLabel = _weightLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openPetDetail(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 76,
                            height: 76,
                            child: ChowNetworkImage(
                              url: pet.petProfileImg ?? _placeholder,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Material(
                            color: ChowCozy.stone500,
                            shape: const CircleBorder(),
                            elevation: 1,
                            shadowColor: Colors.black26,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _openPetDetail(context),
                              child: const SizedBox(
                                width: 28,
                                height: 28,
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.petName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ChowColors.gray800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _breedAgeLine,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ChowColors.gray500,
                              height: 1.25,
                            ),
                          ),
                          if (weightLabel != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              weightLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ChowColors.gray600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: ChowColors.gray400,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: ChowColors.gray500),
          ),
          const SizedBox(height: 6),
          ...items,
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ChowColors.gray600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: ChowColors.gray800),
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ChowCozy.stone500,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            const Icon(Icons.chevron_right, color: ChowColors.gray400),
          ],
        ),
      ),
    );
  }
}

class _ProfileNotice {
  const _ProfileNotice({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isNew,
  });

  final String type;
  final String title;
  final String message;
  final String time;
  final bool isNew;

  _ProfileNotice copyWith({
    String? type,
    String? title,
    String? message,
    String? time,
    bool? isNew,
  }) {
    return _ProfileNotice(
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isNew: isNew ?? this.isNew,
    );
  }
}

class _CharacteristicsSummary extends StatelessWidget {
  const _CharacteristicsSummary({required this.pet});
  final PetModel pet;

  static const _activityLabels = ['매우 적음', '적음', '보통', '많음', '매우 많음'];

  @override
  Widget build(BuildContext context) {
    final bcs = pet.petBodyConditionScore;
    final activity = pet.petActivityLevel;
    final areas = pet.healthFocusAreas;

    if (bcs == null && activity == null && areas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChowColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bcs != null)
            Text('체형 점수(BCS): $bcs / 9', style: const TextStyle(fontSize: 13, color: ChowColors.gray700)),
          if (activity != null) ...[
            if (bcs != null) const SizedBox(height: 4),
            Text('활동량: ${_activityLabels[activity - 1]}', style: const TextStyle(fontSize: 13, color: ChowColors.gray700)),
          ],
          if (areas.isNotEmpty) ...[
            if (bcs != null || activity != null) const SizedBox(height: 4),
            Text('관심 건강 부위: ${areas.join(', ')}', style: const TextStyle(fontSize: 13, color: ChowColors.gray700)),
          ],
        ],
      ),
    );
  }
}
