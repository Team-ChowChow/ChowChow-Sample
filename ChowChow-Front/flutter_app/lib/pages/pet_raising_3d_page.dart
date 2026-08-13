import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

      final url = 'http://35.78.87.150:8080/api/pets/${widget.petId}';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final pet = PetModel.fromJson(jsonDecode(response.body));
        setState(() {
          _pet = pet;
          _loading = false;
        });
      } else {
        setState(() {
          _error = '펫 정보 로드 실패';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
              Text(_error!, textAlign: TextAlign.center),
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
              padding: const EdgeInsets.all(20),
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
                  // 프로필 이모지
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ChowColors.gray100,
                      border: Border.all(color: ChowColors.gray300, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _getGroupEmoji(),
                        style: const TextStyle(fontSize: 50),
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
                  // 정보
                  Text(
                    '${_pet?.groupName} • ${_pet?.breedName ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: ChowColors.gray600,
                    ),
                  ),
                  if (_pet?.petGender != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _pet!.petGender!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ChowColors.gray500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 상태 섹션
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

            // 안내 메시지
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ChowColors.orange50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ChowColors.orange200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎮 펫 키우기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ChowColors.orange500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3D 펫 키우기 기능은 준비 중입니다.\n곧 더 좋은 경험으로 찾아뵙겠습니다!',
                    style: TextStyle(
                      fontSize: 13,
                      color: ChowColors.gray700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
