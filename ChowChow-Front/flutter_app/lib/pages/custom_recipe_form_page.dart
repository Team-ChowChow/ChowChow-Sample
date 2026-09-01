import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../theme/chow_theme.dart';

class CustomRecipeFormPage extends StatefulWidget {
  const CustomRecipeFormPage({super.key, required this.petId, this.petType});

  final int petId;
  final String? petType;

  @override
  State<CustomRecipeFormPage> createState() => _CustomRecipeFormPageState();
}

class _IngredientRow {
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
}

class _CustomRecipeFormPageState extends State<CustomRecipeFormPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingredients = <_IngredientRow>[_IngredientRow()];
  final _steps = <TextEditingController>[TextEditingController()];

  List<Map<String, dynamic>> _menus = [];
  int? _selectedMenuId;
  bool _loadingMenus = true;
  bool _saving = false;

  final _picker = ImagePicker();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      debugPrint('MENU_LOAD_START: petType=${widget.petType}');
      final res = await ApiClient.get(
        '/api/v1/menus',
        query: {'petType': widget.petType ?? 'DOG'},
      ) as List<dynamic>;
      debugPrint('MENU_LOAD_RESULT: $res');
      if (!mounted) return;
      setState(() {
        _menus = res.cast<Map<String, dynamic>>();
        _selectedMenuId = _menus.isNotEmpty ? _menus.first['menuId'] as int? : null;
        _loadingMenus = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('MENU_LOAD_ERROR: $e');
      setState(() => _loadingMenus = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _imagePath = image.path);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('레시피 이름을 입력해 주세요.')),
      );
      return;
    }
    if (_selectedMenuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메뉴 종류를 불러오지 못했어요.')),
      );
      return;
    }

    final ingredients = _ingredients
        .where((r) => r.nameCtrl.text.trim().isNotEmpty)
        .map((r) => {
              'ingredientId': null,
              'amount': double.tryParse(r.amountCtrl.text.trim()),
              'unit': r.unitCtrl.text.trim().isEmpty ? null : r.unitCtrl.text.trim(),
              'note': r.nameCtrl.text.trim(),
            })
        .toList();

    final steps = _steps
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => {'stepNumber': e.key + 1, 'stepDescription': e.value})
        .toList();

    setState(() => _saving = true);
    try {
      String? imageUrl;
      if (_imagePath != null) {
        imageUrl = await ApiClient.uploadImage(File(_imagePath!), type: 'recipe');
      }
      await ApiClient.post('/api/v1/recipes', {
        'petId': widget.petId,
        'menuId': _selectedMenuId,
        'recipeTitle': _titleCtrl.text.trim(),
        'recipeDescription': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'isPublic': false,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'ingredients': ingredients,
        'steps': steps,
      });
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final r in _ingredients) {
      r.nameCtrl.dispose();
      r.amountCtrl.dispose();
      r.unitCtrl.dispose();
    }
    for (final c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ChowColors.gray300),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(title: const Text('내 레시피 만들기')),
      body: _loadingMenus
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('레시피 사진', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ChowColors.gray300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: IconButton.filled(
                                  onPressed: () => setState(() => _imagePath = null),
                                  icon: const Icon(Icons.close, size: 18),
                                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: ChowColors.gray500),
                                SizedBox(height: 6),
                                Text('사진 추가 (선택)', style: TextStyle(color: ChowColors.gray500, fontSize: 13)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('레시피 이름 *', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(controller: _titleCtrl, decoration: _dec('예) 닭가슴살 야채죽')),
                const SizedBox(height: 16),
                const Text('설명', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(controller: _descCtrl, maxLines: 2, decoration: _dec('간단한 설명 (선택)')),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('재료', style: TextStyle(fontWeight: FontWeight.w500)),
                    TextButton.icon(
                      onPressed: () => setState(() => _ingredients.add(_IngredientRow())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('재료 추가'),
                    ),
                  ],
                ),
                ..._ingredients.asMap().entries.map((entry) {
                  final row = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(controller: row.nameCtrl, decoration: _dec('재료명')),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: row.amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _dec('양'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(controller: row.unitCtrl, decoration: _dec('단위')),
                        ),
                        if (_ingredients.length > 1)
                          IconButton(
                            onPressed: () => setState(() => _ingredients.removeAt(entry.key)),
                            icon: const Icon(Icons.close, size: 18, color: ChowColors.gray500),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('조리 순서', style: TextStyle(fontWeight: FontWeight.w500)),
                    TextButton.icon(
                      onPressed: () => setState(() => _steps.add(TextEditingController())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('순서 추가'),
                    ),
                  ],
                ),
                ..._steps.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ctrl = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(controller: ctrl, maxLines: 2, decoration: _dec('조리 순서를 입력하세요')),
                        ),
                        if (_steps.length > 1)
                          IconButton(
                            onPressed: () => setState(() => _steps.removeAt(i)),
                            icon: const Icon(Icons.close, size: 18, color: ChowColors.gray500),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChowCozy.stone700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('저장', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
    );
  }
}
