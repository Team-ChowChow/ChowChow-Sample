import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';

class PetRaising3DPage extends StatefulWidget {
  final int petId;

  const PetRaising3DPage({
    super.key,
    required this.petId,
  });

  @override
  State<PetRaising3DPage> createState() => _PetRaising3DPageState();
}

class _PetRaising3DPageState extends State<PetRaising3DPage> {
  PetModel? _pet;
  bool _loading = true;
  String? _error;

  // 3D 웹사이트 URL (나중에 배포할 주소)
  static const String VIEWER_BASE_URL = 'http://localhost:8888';

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  Future<void> _loadPet() async {
    try {
      debugPrint('🐕 Loading pet with ID: ${widget.petId}');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      debugPrint('🔑 Token exists: ${token != null}');

      final url = 'http://35.78.87.150:8080/api/pets/${widget.petId}';
      debugPrint('📡 Calling: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('📊 Response status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final pet = PetModel.fromJson(jsonDecode(response.body));
        debugPrint('✅ Pet loaded: ${pet.petName}, group: ${pet.groupName}');
        setState(() {
          _pet = pet;
          _loading = false;
        });
      } else {
        setState(() {
          _error = '펫 정보 로드 실패 (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _getGroupNumber() {
    final groupMap = {
      'Toy': 1,
      'Terrier': 2,
      'Working': 3,
      'Herding': 4,
      'Hound': 5,
      'Sporting': 6,
      'Non-Sporting': 7,
    };
    return (groupMap[_pet?.groupName] ?? 1).toString();
  }

  Future<void> _open3DViewer() async {
    try {
      final groupNum = _getGroupNumber();
      final viewerUrl = '$VIEWER_BASE_URL/character_group_$groupNum.html';

      debugPrint('🌐 Opening 3D viewer: $viewerUrl');

      if (await canLaunchUrl(Uri.parse(viewerUrl))) {
        await launchUrl(Uri.parse(viewerUrl), mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('웹 브라우저를 열 수 없습니다')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('펫 키우기'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ChowColors.orange500),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('펫 키우기'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ChowColors.gray600)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadPet, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('펫 키우기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 캐릭터 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 프로필 사진 (이모지 임시)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ChowColors.gray100,
                      border: Border.all(color: ChowColors.gray300, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _getGroupEmoji(),
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 이름
                  Text(
                    _pet?.petName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ChowColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 품종
                  Text(
                    '${_pet?.groupName} • ${_pet?.breed ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: ChowColors.gray600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 통계 섹션
            const Text(
              '상태',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ChowColors.gray900,
              ),
            ),
            const SizedBox(height: 12),

            _statCard('🍖 배고픔', 50),
            const SizedBox(height: 12),
            _statCard('😊 행복도', 80),
            const SizedBox(height: 12),
            _statCard('❤️ 건강도', 75),

            const SizedBox(height: 32),

            // 3D 보기 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _open3DViewer,
                icon: const Icon(Icons.pets),
                label: const Text('3D 캐릭터로 키우기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChowColors.orange500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 설명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChowColors.orange50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 "3D 캐릭터로 키우기"를 누르면 웹에서 3D 캐릭터를 볼 수 있습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: ChowColors.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGroupEmoji() {
    final emojiMap = {
      'Toy': '🐶',
      'Terrier': '🐕',
      'Working': '🦮',
      'Herding': '🐑',
      'Hound': '🐩',
      'Sporting': '🦆',
      'Non-Sporting': '🦴',
    };
    return emojiMap[_pet?.groupName] ?? '🐕';
  }

  Widget _statCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChowColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ChowColors.gray800,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 8,
                  backgroundColor: ChowColors.gray200,
                  valueColor: AlwaysStoppedAnimation(
                    value > 70 ? ChowColors.orange500 : ChowColors.red500,
                  ),
                ),
              ),
            ),
          ),
          Text(
            '$value%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ChowColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}
