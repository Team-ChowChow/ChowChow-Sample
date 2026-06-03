import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../theme/chow_theme.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key, this.initialPost});

  /// null이면 새 글 작성, non-null이면 수정 모드
  final CommunityPost? initialPost;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  final List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedImagePath;
  String? _existingImageUrl; // 수정 모드에서 기존 이미지 URL 보관
  String? _selectedCategory;
  String? _selectedPetType; // '강아지', '고양이', null (선택안함)
  bool _isPosting = false;

  bool get _isEditMode => widget.initialPost != null;
  bool get _canPost => _contentController.text.trim().isNotEmpty;

  static const List<String> _suggestedCategories = [
    '자유',
    '질문',
    '후기',
    '질환정보',
  ];

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
    // 수정 모드: 기존 데이터 pre-fill
    final post = widget.initialPost;
    if (post != null) {
      _titleController.text = post.title ?? '';
      _contentController.text = post.content;
      _selectedCategory = _suggestedCategories.contains(post.category) ? post.category : null;
      // petType pre-fill
      if (post.petType == 'DOG') {
        _selectedPetType = '강아지';
      } else if (post.petType == 'CAT') {
        _selectedPetType = '고양이';
      }
      // 기존 이미지 URL은 별도 보관 (로컬 파일 없이 URL만 유지)
      if (post.image.isNotEmpty) {
        _existingImageUrl = post.image;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag([String? value]) {
    final tag = (value ?? _tagController.text).trim();

    if (tag.isEmpty || _tags.contains(tag)) return;

    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
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
      _selectedImageName = image.name;
      _selectedImagePath = image.path;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedImagePath = null;
      _existingImageUrl = null; // 기존 이미지도 제거
    });
  }

  Future<void> _handlePost() async {
    if (!_canPost || _isPosting) return;
    setState(() => _isPosting = true);
    try {
      // 새 이미지를 선택했으면 업로드, 없으면 기존 URL 사용
      String? imageUrl = _existingImageUrl;
      if (_selectedImagePath != null) {
        imageUrl = await ApiClient.uploadImage(
          File(_selectedImagePath!),
          type: 'recipe',
        );
      }

      if (_isEditMode) {
        // 수정 모드
        final updated = await CommunityService.updatePost(
          postId: widget.initialPost!.id,
          content: _contentController.text.trim(),
          category: _selectedCategory,
          tags: _tags,
          imageUrl: imageUrl,
        );
        if (mounted) context.pop(updated); // 수정된 post 반환
      } else {
        // 새 글 작성
        final petTypeValue = _selectedPetType == '강아지'
            ? 'DOG'
            : _selectedPetType == '고양이'
                ? 'CAT'
                : null;
        print('[CreatePost] 전송할 petType: $_selectedPetType -> $petTypeValue');

        final created = await CommunityService.createPost(
          content: _contentController.text.trim(),
          category: _selectedCategory,
          tags: _tags,
          imageUrl: imageUrl,
          title: _titleController.text.trim(),
          petType: petTypeValue,
        );
        print('[CreatePost] 응답 post.petType: ${created.petType}');

        // 백엔드 응답에 tagNames, petType이 없으면, 프론트엔드에서 직접 설정
        final tagsFormatted = _tags.map((tag) => tag.startsWith('#') ? tag : '#$tag').toList();
        final postWithTags = created.copyWith(
          tags: tagsFormatted,
          petType: created.petType ?? petTypeValue, // 응답에 petType이 없으면 전송한 값 사용
        );

        // SharedPreferences에 tags 저장 (앱 재시작 후에도 복원하기 위함)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('post_${created.id}_tags', tagsFormatted);

        // 커뮤니티 글쓰기 코인 적립
        ApiClient.post('/api/coins/earn', {'amount': 10, 'reason': '커뮤니티 글쓰기'}).ignore();

        if (mounted) context.pop(postWithTags); // post를 반환해서 부모에서 처리
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? '수정에 실패했습니다.' : '게시글 등록에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            _CreatePostHeader(
              isEditMode: _isEditMode,
              canPost: _canPost,
              onClose: () => _isEditMode ? context.pop() : context.go('/community'),
              onPost: _handlePost,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CategorySuggestionCard(
                          categories: _suggestedCategories,
                          selectedCategory: _selectedCategory,
                          onTapCategory: (category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // 제목 입력
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ChowColors.gray200),
                          ),
                          child: TextField(
                            controller: _titleController,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              hintText: '게시글 제목을 입력해주세요',
                              hintStyle: TextStyle(
                                color: ChowColors.gray400,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 강아지/고양이 선택
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ChowColors.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '반려동물 종류 (선택)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ChowColors.gray600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _PetTypeOption(
                                    label: '강아지',
                                    emoji: '🐶',
                                    selected: _selectedPetType == '강아지',
                                    onTap: () => setState(() => _selectedPetType = '강아지'),
                                  ),
                                  const SizedBox(width: 12),
                                  _PetTypeOption(
                                    label: '고양이',
                                    emoji: '🐱',
                                    selected: _selectedPetType == '고양이',
                                    onTap: () => setState(() => _selectedPetType = '고양이'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PetTypeOption(
                                      label: '선택안함',
                                      emoji: '',
                                      selected: _selectedPetType == null,
                                      onTap: () => setState(() => _selectedPetType = null),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ContentInputCard(controller: _contentController),
                        const SizedBox(height: 16),
                        if (_selectedImageBytes != null) ...[
                          _ImagePreviewCard(
                            imageBytes: _selectedImageBytes!,
                            onRemove: _removeImage,
                          ),
                          const SizedBox(height: 16),
                        ] else if (_existingImageUrl != null) ...[
                          _ExistingImagePreviewCard(
                            imageUrl: _existingImageUrl!,
                            onRemove: _removeImage,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _ImageUploadCard(
                          hasImage: _selectedImageBytes != null || _existingImageUrl != null,
                          onTap: _pickImage,
                        ),
                        const SizedBox(height: 16),
                        _TagCard(
                          controller: _tagController,
                          tags: _tags,
                          onAddTag: _addTag,
                          onRemoveTag: _removeTag,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostHeader extends StatelessWidget {
  const _CreatePostHeader({
    required this.isEditMode,
    required this.canPost,
    required this.onClose,
    required this.onPost,
  });

  final bool isEditMode;
  final bool canPost;
  final VoidCallback onClose;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ChowColors.gray200, width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: ChowColors.gray600, size: 26),
              visualDensity: VisualDensity.compact,
            ),
            const Spacer(),
            Text(
              isEditMode ? '글 수정' : '글쓰기',
              style: const TextStyle(
                fontSize: 18,
                color: ChowColors.gray800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: canPost ? onPost : null,
                style: FilledButton.styleFrom(
                  backgroundColor: ChowColors.orange500,
                  disabledBackgroundColor: ChowColors.gray300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  isEditMode ? '수정' : '게시',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentInputCard extends StatelessWidget {
  const _ContentInputCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: TextField(
        controller: controller,
        minLines: 9,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '반려동물 식단에 대한 이야기를 공유해보세요',
          hintStyle: TextStyle(color: ChowColors.gray400),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: ChowColors.gray700,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.imageBytes,
    required this.onRemove,
  });

  final Uint8List imageBytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingImagePreviewCard extends StatelessWidget {
  const _ExistingImagePreviewCard({
    required this.imageUrl,
    required this.onRemove,
  });

  final String imageUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(height: 120),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.controller,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final TextEditingController controller;
  final List<String> tags;
  final ValueChanged<String?> onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tag, size: 22, color: ChowColors.gray400),
              SizedBox(width: 8),
              Text(
                '태그 추가',
                style: TextStyle(
                  fontSize: 15,
                  color: ChowColors.gray700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => onAddTag(value),
                  decoration: InputDecoration(
                    hintText: '태그 입력 후 엔터',
                    hintStyle: const TextStyle(color: ChowColors.gray400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: ChowColors.gray200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: ChowColors.orange500),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => onAddTag(null),
                style: OutlinedButton.styleFrom(
                  backgroundColor: ChowColors.gray100,
                  foregroundColor: ChowColors.gray700,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('추가'),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ChowColors.orange50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 13,
                          color: ChowColors.orange600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onRemoveTag(tag),
                        child: const Icon(Icons.close, size: 14, color: ChowColors.orange600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageUploadCard extends StatelessWidget {
  const _ImageUploadCard({
    required this.hasImage,
    required this.onTap,
  });

  final bool hasImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: ChowColors.orange50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: ChowColors.orange500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '사진 추가',
                    style: TextStyle(
                      fontSize: 15,
                      color: ChowColors.gray800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasImage ? '다른 사진 선택하기' : '사진을 첨부해보세요',
                    style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySuggestionCard extends StatelessWidget {
  const _CategorySuggestionCard({
    required this.categories,
    required this.selectedCategory,
    required this.onTapCategory,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onTapCategory;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '카테고리',
            style: TextStyle(
              fontSize: 14,
              color: ChowColors.gray700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final selected = selectedCategory == category;

              return Material(
                color: selected ? ChowColors.orange500 : ChowColors.gray100,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => onTapCategory(category),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : ChowColors.gray600,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _PetTypeOption extends StatelessWidget {
  const _PetTypeOption({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? ChowColors.orange100 : ChowColors.gray100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji.isNotEmpty)
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                if (emoji.isNotEmpty) const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? ChowColors.orange600 : ChowColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}