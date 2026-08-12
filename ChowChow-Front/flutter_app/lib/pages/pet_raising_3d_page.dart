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
  bool _isWalking = false;

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

  String _getGroupEmoji() {
    final emojiMap = {
      'Toy': '🐶',
      'Terrier': '🐕',
      'Working': '🦮',
      'Herding': '🐑',
      'Hound': '🦗',
      'Sporting': '🦆',
      'Non-Sporting': '🐩',
    };
    return emojiMap[_pet?.groupName] ?? '🐕';
  }

  void _toggleAnimation() {
    setState(() {
      _isWalking = !_isWalking;
    });
    debugPrint('🚶 애니메이션: ${_isWalking ? "재생" : "정지"}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('3D 펫 키우기'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: ChowColors.orange500)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('3D 펫 키우기'),
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
        title: Text(_pet?.petName ?? '3D 펫 키우기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // 3D 캐릭터 영역 (중앙)
          Center(
            child: GestureDetector(
              onTap: _toggleAnimation,
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ChowColors.gray300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 거대한 이모지로 임시 3D 표현
                    Transform.rotate(
                      angle: _isWalking ? (_isWalking ? 0.1 : 0) : 0,
                      child: Text(
                        _getGroupEmoji(),
                        style: const TextStyle(fontSize: 120),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _pet?.groupName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ChowColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isWalking ? '🚶 걷는 중...' : '정지 중',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isWalking ? ChowColors.orange500 : ChowColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 상태창 (왼쪽 위)
          Positioned(
            top: 16,
            left: 16,
            child: _buildStatsPanel(),
          ),

          // 컨트롤 버튼 (우하단)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _toggleAnimation,
              backgroundColor: ChowColors.orange500,
              child: Icon(
                _isWalking ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statRow('🍖 배고픔', 50),
          const SizedBox(height: 8),
          _statRow('😊 행복도', 80),
          const SizedBox(height: 8),
          _statRow('❤️ 건강도', 75),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: ChowColors.gray200,
              valueColor: AlwaysStoppedAnimation(
                value > 70 ? ChowColors.orange500 : ChowColors.red500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
