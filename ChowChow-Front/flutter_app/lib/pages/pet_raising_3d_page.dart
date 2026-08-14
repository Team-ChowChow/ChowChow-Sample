import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/models.dart';
import '../theme/chow_theme.dart';

/// 3D 뷰어(webview_flutter 기반)는 플랫폼별로 불안정해서 당분간 비활성화하고,
/// 품종 그룹별로 미리 준비된 2D 캐릭터 이미지(assets/images/characters/)를 보여준다.
/// 3D가 다시 준비되면 이 페이지만 교체하면 된다.
class PetRaising3DPage extends StatefulWidget {
  final int petId;

  const PetRaising3DPage({
    super.key,
    required this.petId,
  });

  @override
  State<PetRaising3DPage> createState() => _PetRaising3DPageState();
}

class _PetRaising3DPageState extends State<PetRaising3DPage>
    with SingleTickerProviderStateMixin {
  PetModel? _pet;
  bool _loading = true;
  String? _error;

  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _loadPet();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPet() async {
    try {
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

  int _groupNumber() {
    const groupMap = {
      'Toy': 1,
      'Terrier': 2,
      'Working': 3,
      'Herding': 4,
      'Hound': 5,
      'Sporting': 6,
      'Non-Sporting': 7,
    };
    return groupMap[_pet?.groupName] ?? 1;
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
          child: CircularProgressIndicator(color: ChowCozy.stone500),
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
              Text(_error!),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadPet, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_pet?.petName ?? '펫 키우기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ChowCozy.stone100, ChowCozy.stone50],
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: child,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/characters/character_group_${_groupNumber()}.png',
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      // 캐릭터 이미지가 아직 없거나 로드에 실패해도 화면 전체가 죽지 않도록,
                      // 그 자리만 비워두고 나머지(스탯 카드 등)는 그대로 보여준다.
                      errorBuilder: (_, _, _) => const SizedBox(width: 220, height: 220),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: ChowCozy.stone200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '🐾 2D 캐릭터 — 3D 뷰어는 준비 중이에요',
                        style: TextStyle(fontSize: 12, color: ChowCozy.stone800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
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
            ),
          ),
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
                value > 70 ? ChowCozy.stone500 : ChowColors.red500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
