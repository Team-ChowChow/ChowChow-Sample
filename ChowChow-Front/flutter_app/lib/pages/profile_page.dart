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

class _ProfilePageState extends State<ProfilePage> {
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
                            _buildPetOptionGroup(
                              label: '성별',
                              options: const ['남아', '여아'],
                              selected: _petGender == 'MALE' ? const ['남아'] : _petGender == 'FEMALE' ? const ['여아'] : const [],
                              onChanged: (value) => updateForm(() => _petGender = value == '남아' ? 'MALE' : 'FEMALE'),
                            ),
                            CheckboxListTile(
                              value: _isNeutered,
                              contentPadding: EdgeInsets.zero,
                              activeColor: ChowCozy.stone500,
                              title: const Text('중성화 수술 완료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              onChanged: (value) => updateForm(() => _isNeutered = value ?? false),
                            ),
                            _buildPetOptionGroup(
                              label: '하루 산책',
                              options: const ['30분 미만', '30분–1시간', '1시간 이상'],
                              selected: _activityLevel == 1 ? const ['30분 미만'] : _activityLevel == 3 ? const ['30분–1시간'] : _activityLevel == 5 ? const ['1시간 이상'] : const [],
                              onChanged: (value) => updateForm(() => _activityLevel = const {'30분 미만': 1, '30분–1시간': 3, '1시간 이상': 5}[value]),
                            ),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '주식 형태', options: const ['건식', '습식', '동결건조', '소프트 (반습식)', '자연식 (화식/생식)', '홈메이드'], selected: _foodTypes, onChanged: (value) => updateForm(() => _toggle(_foodTypes, value))),
                            const SizedBox(height: 18),
                            _buildAllergySelector(updateForm),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '건강 고민', options: const ['해당 없음', '피부/피모', '관절', '소화기', '체중 관리', '치아/구강'], selected: _healthFocusAreas, onChanged: (value) => updateForm(() => _toggle(_healthFocusAreas, value, limit: 3)), helper: '최대 3개까지 선택할 수 있어요.'),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '좋아하는 음식', options: const ['해당 없음', '닭고기', '소고기', '생선', '채소'], selected: _favoriteFoods, onChanged: (value) => updateForm(() => _toggle(_favoriteFoods, value))),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '가장 중요한 우선순위', options: const ['균형 잡힌 식사', '체중 & 영양', '실시간 행동', '건강 추적'], selected: _priorities, onChanged: (value) => updateForm(() => _toggle(_priorities, value))),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '주 생활 공간', options: const ['실내', '마당', '테라스 / 발코니'], selected: _livingSpaces, onChanged: (value) => updateForm(() => _toggle(_livingSpaces, value))),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '낮 시간을 보내는 방법', options: const ['집에 혼자 있어요', '유치원에 가요', '산책 도우미와 함께해요', '항상 가족과 함께해요'], selected: _daytimeRoutines, onChanged: (value) => updateForm(() => _toggle(_daytimeRoutines, value))),
                            const SizedBox(height: 18),
                            _buildPetOptionGroup(label: '궁금하거나 걱정되는 행동', options: const ['분리 불안 / 짖음', '수면 / 휴식 패턴', '식이 / 음수 습관', '전반적 활동량'], selected: _behaviorConcerns, onChanged: (value) => updateForm(() => _toggle(_behaviorConcerns, value))),
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
        _buildPetLabel(label, required: true),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              selectedColor: ChowCozy.stone300,
              side: BorderSide(color: isSelected ? ChowCozy.stone500 : ChowColors.gray300),
              labelStyle: TextStyle(
                color: isSelected ? ChowCozy.stone800 : ChowColors.gray700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              onSelected: (_) => onChanged(option),
            );
          }).toList(),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper, style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
        ],
      ],
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
            final date = await showDatePicker(context: context, initialDate: _petBirthdate ?? DateTime.now(), firstDate: DateTime(1990), lastDate: DateTime.now());
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

  Widget _buildPetWeightBcsField(void Function(VoidCallback) updateForm) {
    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('체중 기록', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text('체중 *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '예) 4.5',
                    suffixText: 'kg',
                    suffixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ChowColors.gray800),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: ChowColors.gray300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: ChowCozy.stone500, width: 2)),
                  ),
                  onChanged: (value) => updateForm(() => _petWeight = value),
                ),
                const SizedBox(height: 18),
                const Text('신체충실지수 (BCS) *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(9, (index) {
                    final selected = _bodyConditionScore == index + 1;
                    return InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () { updateForm(() => _bodyConditionScore = index + 1); setSheet(() {}); },
                      child: Container(
                        width: 34, height: 34, alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? ChowCozy.stone700 : Colors.white, border: Border.all(color: selected ? ChowCozy.stone700 : ChowColors.gray300)),
                        child: Text('${index + 1}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? Colors.white : ChowColors.gray600)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Image.asset('assets/images/bcs.png', fit: BoxFit.contain),
              ],
            ),
          ),
        ),
      ),
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
                          '멍냥밥상 v1.0.0',
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
    '피부/피모', '관절', '소화기', '비뇨기', '치아/구강', '눈/귀', '체중 관리', '심장',
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
