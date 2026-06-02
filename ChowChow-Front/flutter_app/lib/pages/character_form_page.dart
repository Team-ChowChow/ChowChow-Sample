import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  final _imageUrlCtrl = TextEditingController();

  String _petType = '';
  int? _breedId;
  String? _breedName;
  List<BreedModel> _breeds = [];
  String? _imageUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadCharacter();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCharacter() async {
    try {
      final c = await CharacterService.fetchCharacter(widget.characterId!);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = c.characterName;
        _descCtrl.text = c.description ?? '';
        _petType = c.petType ?? 'DOG';
        _breedId = c.breedId;
        _breedName = c.breedName;
        _imageUrl = c.characterImageUrl;
        _imageUrlCtrl.text = c.characterImageUrl ?? '';
        _loading = false;
      });
      await _loadBreeds(_petType);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('불러오기 실패: $e')));
    }
  }

  Future<void> _loadBreeds(String petType) async {
    try {
      final breeds = await CharacterService.fetchBreeds(petType);
      if (!mounted) return;
      setState(() {
        _breeds = breeds;
        if (_breedId != null && !_breeds.any((b) => b.breedId == _breedId)) {
          _breedId = null;
          _breedName = null;
        }
      });
    } catch (_) {
      setState(() => _breeds = []);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final url = await ApiClient.uploadImage(File(file.path), type: 'character');
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _imageUrlCtrl.text = url;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드 실패: $e')));
    }
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty && _petType.isNotEmpty && _breedId != null;

  Future<void> _save() async {
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름, 종류, 품종을 입력해 주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    final image = _imageUrlCtrl.text.trim().isNotEmpty ? _imageUrlCtrl.text.trim() : _imageUrl;
    try {
      if (widget.isEdit) {
        await CharacterService.updateCharacter(
          widget.characterId!,
          characterName: _nameCtrl.text.trim(),
          breedId: _breedId,
          characterImageUrl: image,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
      } else {
        await CharacterService.createCharacter(
          characterName: _nameCtrl.text.trim(),
          petType: _petType,
          breedId: _breedId,
          characterImageUrl: image,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
          ? const Center(child: CircularProgressIndicator(color: ChowColors.orange500))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _saving ? null : _pickImage,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: ChowColors.orange100,
                        child: _imageUrl != null && _imageUrl!.isNotEmpty
                            ? ClipOval(
                                child: SizedBox(
                                  width: 104,
                                  height: 104,
                                  child: ChowNetworkImage(url: _imageUrl!, fit: BoxFit.cover),
                                ),
                              )
                            : const Icon(Icons.add_a_photo, size: 40, color: ChowColors.orange500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('탭하여 이미지 선택', style: TextStyle(fontSize: 12, color: ChowColors.gray500)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: '이름 *'),
                  ),
                  const SizedBox(height: 16),
                  const Text('종류 *', style: TextStyle(fontWeight: FontWeight.w600, color: ChowColors.gray700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeChip(
                          label: '강아지',
                          selected: _petType == 'DOG',
                          onTap: () async {
                            setState(() {
                              _petType = 'DOG';
                              _breedId = null;
                              _breedName = null;
                            });
                            await _loadBreeds('DOG');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeChip(
                          label: '고양이',
                          selected: _petType == 'CAT',
                          onTap: () async {
                            setState(() {
                              _petType = 'CAT';
                              _breedId = null;
                              _breedName = null;
                            });
                            await _loadBreeds('CAT');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _breedId,
                    decoration: InputDecoration(
                      labelText: _petType.isEmpty ? '품종 (종류를 먼저 선택)' : '품종 *',
                    ),
                    items: _breeds
                        .map((b) => DropdownMenuItem(value: b.breedId, child: Text(b.displayName)))
                        .toList(),
                    onChanged: _petType.isEmpty
                        ? null
                        : (v) {
                            setState(() {
                              _breedId = v;
                              _breedName = _breeds.firstWhere((b) => b.breedId == v).displayName;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _imageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: '이미지 URL (선택)',
                      hintText: 'https://...',
                    ),
                    onChanged: (v) => setState(() => _imageUrl = v.trim().isEmpty ? null : v.trim()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '설명',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _saving || !_valid ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: ChowColors.orange500),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.isEdit ? '수정 완료' : '생성하기'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ChowColors.orange100 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? ChowColors.orange500 : ChowColors.gray300, width: selected ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? ChowColors.orange600 : ChowColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}
