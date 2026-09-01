import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/character_service.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class CharacterFormPage extends StatefulWidget {
  const CharacterFormPage({super.key, this.characterId});

  final int? characterId;

  bool get isEdit => characterId != null;

  @override
  State<CharacterFormPage> createState() => _CharacterFormPageState();
}

class _CharacterFormPageState extends State<CharacterFormPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // 반려동물 선택
  List<PetModel> _pets = [];
  PetModel? _selectedPet;

  // 수정 모드용
  int? _breedId;

  // 이미 캐릭터가 있는 petId 목록
  Set<int> _characterizedPetIds = {};

  bool _loading = true;
  bool _saving = false;
  bool _generatingImage = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadPets(),
      _loadCharacterizedPetIds(),
      if (widget.isEdit) _loadCharacter(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCharacterizedPetIds() async {
    try {
      final chars = await CharacterService.fetchCharacters();
      if (!mounted) return;
      setState(() {
        _characterizedPetIds = chars.map((c) => c.petId).toSet();
      });
    } catch (_) {}
  }

  Future<void> _loadPets() async {
    try {
      final res = await ApiClient.get('/api/pets') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _pets = res.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadCharacter() async {
    try {
      final c = await CharacterService.fetchCharacter(widget.characterId!);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = c.characterName;
        _descCtrl.text = c.description ?? '';
        _breedId = c.breedId;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('불러오기 실패: $e')));
    }
  }

  void _selectPet(PetModel pet) {
    if (_characterizedPetIds.contains(pet.petId)) return;
    setState(() {
      _selectedPet = pet;
      if (_nameCtrl.text.isEmpty) _nameCtrl.text = pet.petName;
    });
  }

  bool get _valid {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (widget.isEdit) return true;
    if (_selectedPet == null) return false;
    return !_characterizedPetIds.contains(_selectedPet!.petId);
  }

  String _getCharacterImageByGroup(String? petType, String? groupName) {
    if (petType == 'CAT') {
      // 고양이 그룹명을 번호로 매핑 (8: Longhair, 9: Shorthair, 10: Hairless)
      final catGroupMap = {'Longhair': 8, 'Shorthair': 9, 'Hairless': 10};
      final catGroupNum = catGroupMap[groupName] ?? 8;
      return 'character_group_$catGroupNum';
    }

    if (groupName == null || groupName.isEmpty) {
      return 'character_group_1';
    }

    // FCI 그룹명을 번호로 매핑
    final groupMap = {
      'Toy': 1,
      'Terrier': 2,
      'Working': 3,
      'Herding': 4,
      'Hound': 5,
      'Sporting': 6,
      'Non-Sporting': 7,
    };

    final groupNum = groupMap[groupName] ?? 1;
    return 'character_group_$groupNum';
  }

  Future<void> _save() async {
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반려동물을 선택하고 이름을 입력해 주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.isEdit) {
        await CharacterService.updateCharacter(
          widget.characterId!,
          characterName: _nameCtrl.text.trim(),
          breedId: _breedId,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
        if (!mounted) return;
        context.pop(true);
      } else {
        final pet = _selectedPet!;

        // 품종 그룹에 따라 이미지 패턴 미리 결정
        final groupImagePath = _getCharacterImageByGroup(
          pet.petType,
          pet.groupName,
        );

        // 1. 캐릭터 생성 (이미지와 함께)
        final created = await CharacterService.createCharacter(
          characterName: _nameCtrl.text.trim(),
          petType: pet.petType ?? 'DOG',
          petId: pet.petId,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          characterImageUrl: groupImagePath,
        );
        if (!mounted) return;
        setState(() { _saving = false; _generatingImage = false; });

        if (!mounted) return;
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _generatingImage = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? '캐릭터 수정' : '새 캐릭터 생성'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ChowCozy.stone500))
          : _generatingImage
              ? _GeneratingImageOverlay(petName: _selectedPet?.petName ?? '')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.isEdit) ...[
                        _PetSelectionSection(
                          pets: _pets,
                          selectedPet: _selectedPet,
                          characterizedPetIds: _characterizedPetIds,
                          onSelect: _selectPet,
                        ),
                        const SizedBox(height: 24),
                      ],
                      TextField(
                        controller: _nameCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: '캐릭터 이름 *',
                          hintText: '반려동물 이름을 입력하세요',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: '설명 (선택)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _saving || !_valid ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: ChowCozy.stone500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.isEdit ? '수정 완료' : '생성하기',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PetSelectionSection extends StatelessWidget {
  const _PetSelectionSection({
    required this.pets,
    required this.selectedPet,
    required this.characterizedPetIds,
    required this.onSelect,
  });

  final List<PetModel> pets;
  final PetModel? selectedPet;
  final Set<int> characterizedPetIds;
  final ValueChanged<PetModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '반려동물 선택 *',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: ChowColors.gray800),
        ),
        const SizedBox(height: 4),
        const Text(
          '설정에서 등록한 반려동물을 선택하면 AI가 캐릭터 이미지를 자동 생성합니다.',
          style: TextStyle(fontSize: 12, color: ChowColors.gray500),
        ),
        const SizedBox(height: 12),
        if (pets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ChowColors.gray50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ChowColors.gray200),
            ),
            child: const Column(
              children: [
                Icon(Icons.pets, color: ChowColors.gray300, size: 36),
                SizedBox(height: 8),
                Text(
                  '등록된 반려동물이 없습니다.\n프로필 설정에서 먼저 등록해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ChowColors.gray500, fontSize: 13),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _PetCard(
                pet: pets[i],
                selected: selectedPet?.petId == pets[i].petId,
                hasCharacter: characterizedPetIds.contains(pets[i].petId),
                onTap: () => onSelect(pets[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.selected,
    required this.hasCharacter,
    required this.onTap,
  });

  final PetModel pet;
  final bool selected;
  final bool hasCharacter;
  final VoidCallback onTap;

  // 사진을 등록하지 않은 반려동물은 종에 맞는 기본 프로필 이미지를 보여준다.
  String get _placeholder =>
      pet.petType == 'CAT'
          ? 'assets/images/base_cat.png'
          : 'assets/images/base_dog.png';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasCharacter ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 88,
        decoration: BoxDecoration(
          color: hasCharacter
              ? ChowColors.gray100
              : selected
                  ? ChowCozy.stone100
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasCharacter
                ? ChowColors.gray200
                : selected
                    ? ChowCozy.stone500
                    : ChowColors.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: hasCharacter ? 0.4 : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox.expand(
                      child: ChowNetworkImage(url: pet.petProfileImg ?? _placeholder),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 16,
                width: double.infinity,
                child: Text(
                  pet.petName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: hasCharacter
                        ? ChowColors.gray400
                        : selected
                            ? ChowCozy.stone700
                            : ChowColors.gray800,
                  ),
                ),
              ),
              SizedBox(
                height: 14,
                width: double.infinity,
                child: Text(
                  hasCharacter ? '이미 있음' : pet.displayType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: hasCharacter ? ChowColors.gray400 : ChowColors.gray500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratingImageOverlay extends StatelessWidget {
  const _GeneratingImageOverlay({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: ChowCozy.stone500),
            const SizedBox(height: 24),
            Text(
              '$petName의 AI 캐릭터 생성 중...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ChowColors.gray800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '잠시만 기다려주세요.\n고화질 캐릭터 이미지를 만들고 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ChowColors.gray500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
