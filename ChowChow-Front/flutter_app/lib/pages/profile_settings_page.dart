import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _profileImageUrl;
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _nicknameController.text.trim().length >= 2 &&
      _nicknameController.text.trim().length <= 20;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refreshForm);
    _nicknameController.addListener(_refreshForm);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refreshForm)
      ..dispose();
    _nicknameController
      ..removeListener(_refreshForm)
      ..dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiClient.get('/api/users/me')
          as Map<String, dynamic>;
      final user = UserModel.fromJson(response);
      final accountEmail = user.authEmail ?? await _emailFromAccessToken();
      if (!mounted) return;
      _nameController.text = user.userName ?? '';
      _nicknameController.text = user.userNickname ?? '';
      _emailController.text = accountEmail ?? '';
      setState(() {
        _profileImageUrl = user.userProfileImg;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '프로필 정보를 불러오지 못했습니다.';
      });
    }
  }

  Future<String?> _emailFromAccessToken() async {
    try {
      final token = await ApiClient.getToken();
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return payload['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '사진을 불러오지 못했습니다. 다른 이미지를 선택해주세요.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_isValid || _saving) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      var imageUrl = _profileImageUrl;
      if (_selectedImageBytes != null) {
        imageUrl = await ApiClient.uploadImageBytes(
          _selectedImageBytes!,
          filename: _selectedImageName ?? 'profile-image.jpg',
          type: 'profile',
        );
      }

      await ApiClient.patch('/api/users/me', {
        'userName': _nameController.text.trim(),
        'userNickname': _nicknameController.text.trim(),
        if (imageUrl != null) 'userProfileImg': imageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '프로필 저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '프로필 설정',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF111827),
            size: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ChowCozy.stone500),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Center(
                  child: _ProfileImageEditor(
                    selectedImageBytes: _selectedImageBytes,
                    imageUrl: _profileImageUrl,
                    onTap: _pickProfileImage,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickProfileImage,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('프로필 사진 변경'),
                    style: TextButton.styleFrom(
                      foregroundColor: ChowCozy.stone500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SettingsSection(
                  title: '기본 정보',
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          hintText: '이름을 입력하세요',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nicknameController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: '닉네임',
                          hintText: '2~20자로 입력하세요',
                          helperText: '프로필과 커뮤니티에 표시되는 이름입니다.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: '계정 정보',
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          helperText: '가입 이메일은 계정 식별을 위해 변경할 수 없습니다.',
                          suffixIcon: Icon(Icons.lock_outline, size: 19),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.password_outlined,
                          color: ChowCozy.stone500,
                        ),
                        title: const Text('비밀번호 변경'),
                        subtitle: const Text('현재 비밀번호를 확인한 후 변경합니다.'),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: ChowColors.gray400,
                        ),
                        onTap: () => context.push('/change-password'),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ChowColors.red500,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isValid && !_saving ? _saveProfile : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChowCozy.stone500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '저장하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileImageEditor extends StatelessWidget {
  const _ProfileImageEditor({
    required this.selectedImageBytes,
    required this.imageUrl,
    required this.onTap,
  });

  final Uint8List? selectedImageBytes;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ChowCozy.stone300,
            ),
            child: ClipOval(child: _buildImage()),
          ),
          Positioned(
            right: -2,
            bottom: 2,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ChowCozy.stone500,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (selectedImageBytes != null) {
      return Image.memory(selectedImageBytes!, fit: BoxFit.cover);
    }
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return ChowNetworkImage(url: url, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 48, color: ChowCozy.stone500),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ChowColors.gray800,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
