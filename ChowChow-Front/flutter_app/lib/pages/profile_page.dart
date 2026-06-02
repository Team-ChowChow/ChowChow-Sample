import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/character_service.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
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

  String _petType = '';
  int? _breedId;
  String _breedDisplayName = '';
  List<BreedModel> _availableBreeds = [];
  String _petName = '';
  String _petAge = '';
  String _petWeight = '';
  List<AllergyModel> _allAllergies = [];
  List<int> _selectedAllergyIds = [];

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
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/api/users/me'),
        ApiClient.get('/api/pets'),
        ApiClient.get('/api/users/me/stats').catchError((_) => <String, dynamic>{}),
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
            title: m['notificationTitle'] as String? ?? m['title'] as String? ?? '알림',
            message: m['notificationContent'] as String? ?? m['message'] as String? ?? '',
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
    _petWeight = '';
    _selectedAllergyIds = [];
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
    final birth = DateTime(DateTime.now().year - years, DateTime.now().month, DateTime.now().day);
    return '${birth.year}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitPetForm() async {
    if (!_isPetFormValid) return;

    final body = <String, dynamic>{
      'petName': _petName.trim(),
      'petType': _petType == 'dog' ? 'DOG' : 'CAT',
      if (_breedId != null) 'breedId': _breedId,
      if (_parseWeight(_petWeight) != null) 'petWeight': _parseWeight(_petWeight),
      if (_petAge.trim().isNotEmpty) 'petBirthdate': _ageToBirthdate(_petAge.trim()),
      if (_selectedAllergyIds.isNotEmpty) 'allergyIds': _selectedAllergyIds,
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
        const SnackBar(
          content: Text('반려동물 추가에 실패했습니다. 잠시 후 다시 시도해주세요.'),
        ),
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
                            _buildPetInputField(
                              label: '나이',
                              required: true,
                              hintText: '예: 3살',
                              onChanged: (value) {
                                updateForm(() => _petAge = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildPetInputField(
                              label: '체중',
                              required: true,
                              hintText: '예: 5kg',
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                updateForm(() => _petWeight = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildAllergySelector(updateForm),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    _isPetFormValid ? _submitPetForm : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ChowColors.orange500,
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
      color: selected ? const Color(0xFFFFF7ED) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ChowColors.orange500 : ChowColors.gray200,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: ChowColors.gray800,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                const Icon(
                  Icons.check,
                  color: ChowColors.orange500,
                  size: 20,
                ),
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
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            itemCount: _availableBreeds.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final breed = _availableBreeds[index];
                              return ListTile(
                                title: Text(breed.displayName, style: const TextStyle(fontSize: 15)),
                                trailing: _breedId == breed.breedId
                                    ? const Icon(Icons.check, color: ChowColors.orange500)
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
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: ChowColors.orange500)),
                        SizedBox(width: 10),
                        Text('품종 불러오는 중...', style: TextStyle(color: ChowColors.gray500, fontSize: 15)),
                      ],
                    )
                  : Text(
                      _breedDisplayName.isEmpty ? '품종을 선택하세요 (선택)' : _breedDisplayName,
                      style: TextStyle(
                        color: _breedDisplayName.isEmpty ? ChowColors.gray500 : const Color(0xFF111827),
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
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
          const Text('알러지 목록을 불러오는 중...', style: TextStyle(color: ChowColors.gray500, fontSize: 13))
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
                      _selectedAllergyIds = List.from(_selectedAllergyIds)..remove(a.allergyId);
                    } else {
                      _selectedAllergyIds = [..._selectedAllergyIds, a.allergyId];
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? ChowColors.orange100 : Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected ? ChowColors.orange500 : ChowColors.gray300,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    a.allergyName,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? ChowColors.orange600 : ChowColors.gray700,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
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
            hintStyle: const TextStyle(
              color: ChowColors.gray500,
              fontSize: 14,
            ),
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
                color: ChowColors.orange500,
                width: 2,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 12,
              color: ChowColors.gray500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPetLabel(String text, {required bool required}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          color: ChowColors.gray700,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: ChowColors.orange500),
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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                                Icon(Icons.notifications_none, size: 48, color: ChowColors.gray300),
                                SizedBox(height: 12),
                                Text('알림이 없어요', style: TextStyle(color: ChowColors.gray500, fontSize: 15)),
                              ],
                            ),
                          )
                        : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
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
                                _notifications[index] =
                                    item.copyWith(isNew: false);
                              });

                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          style: const TextStyle(height: 1.35),
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
                                              decoration: const BoxDecoration(
                                                color: ChowColors.orange500,
                                                shape: BoxShape.circle,
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
        return ChowColors.orange100;
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
        return ChowColors.orange500;
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

    return ColoredBox(
      color: ChowColors.gray50,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: ChowColors.orange500,
                    padding: const EdgeInsets.fromLTRB(20, 48, 8, 40),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.person,
                                size: 34,
                                color: Colors.deepPurple.shade300,
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
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '+ 추가하기',
                                    style: TextStyle(
                                      color: ChowColors.orange500,
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
                                    style: TextStyle(
                                      color: ChowColors.gray500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._pets.map((pet) => _PetRow(pet: pet)),
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
                      icon: const Icon(
                        Icons.logout,
                        color: ChowColors.red500,
                      ),
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
  const _PetRow({required this.pet});
  final PetModel pet;
  @override
  State<_PetRow> createState() => _PetRowState();
}

class _PetRowState extends State<_PetRow> {
  bool _generating = false;

  static const _placeholder =
      'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=400&q=80';

  PetModel get pet => widget.pet;

  String get _breedAgeLine {
    final breed = pet.breedName ?? pet.displayType;
    final age = _ageLabel;
    if (age == null) return breed;
    return '$breed • $age';
  }

  String? get _ageLabel {
    final birthRaw = pet.petBirthdate;
    if (birthRaw == null || birthRaw.isEmpty) return null;
    final birth = DateTime.tryParse(birthRaw);
    if (birth == null) return null;
    var years = DateTime.now().year - birth.year;
    final now = DateTime.now();
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    if (years < 1) return '1살 미만';
    return '$years살';
  }

  String? get _weightLabel {
    final w = pet.petWeight;
    if (w == null) return null;
    final rounded = w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
    return '체중: ${rounded}kg';
  }

  Future<void> _generateCharacter() async {
    if (_generating) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _generating = true);
    try {
      final uploadedUrl = await ApiClient.uploadImage(File(picked.path), type: 'recipe');
      await ApiClient.patch('/api/pets/${pet.petId}', {
        'petName': pet.petName,
        'petType': pet.petType,
        'petProfileImg': uploadedUrl,
      });
      final result = await ApiClient.post('/api/ai/image/character', {
        'petId': pet.petId,
        'style': 'cute chibi anime',
      }) as Map<String, dynamic>;
      final imageUrl = result['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty && mounted) {
        await ApiClient.patch('/api/pets/${pet.petId}', {
          'petName': pet.petName,
          'petType': pet.petType,
          'petProfileImg': imageUrl,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 캐릭터 변환 완료!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변환 실패: $e'), duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
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
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: ChowColors.gray300, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () { Navigator.of(ctx).pop(); _generateCharacter(); },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 120, height: 120,
                        child: ChowNetworkImage(url: pet.petProfileImg ?? _placeholder),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: ChowColors.orange500, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text('사진을 탭하면 변경할 수 있어요', style: TextStyle(fontSize: 12, color: ChowColors.gray500)),
              const SizedBox(height: 16),
              Text(pet.petName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ChowColors.gray900)),
              const SizedBox(height: 4),
              Text(_breedAgeLine, style: const TextStyle(fontSize: 14, color: ChowColors.gray500)),
              if (_weightLabel != null) ...[
                const SizedBox(height: 2),
                Text(_weightLabel!, style: const TextStyle(fontSize: 13, color: ChowColors.gray600)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () { Navigator.of(ctx).pop(); _generateCharacter(); },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('사진 선택 후 AI 캐릭터 자동 변환'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChowColors.orange500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
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
                        color: ChowColors.orange500,
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
      if (_generating)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(color: ChowColors.orange500),
        ),
    ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.title,
    required this.items,
  });

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
            style: const TextStyle(
              fontSize: 13,
              color: ChowColors.gray500,
            ),
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
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: ChowColors.gray600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: ChowColors.gray800,
                ),
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: ChowColors.orange500,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right,
              color: ChowColors.gray400,
            ),
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
