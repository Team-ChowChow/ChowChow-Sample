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
  String _currentAnimation = 'idle';
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadPet();
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

  String _getGifPath(String animation) {
    final groupNum = _getGroupNumber();
    const fallbackGif = 'group1_idle';

    final animationMap = {
      'eating': 'group${groupNum}_eating',
      'petting': 'group${groupNum}_petting',
      'exercise': 'group${groupNum}_exercise',
      'bath': 'group${groupNum}_bath',
      'idle': 'group${groupNum}_idle',
    };

    final gifName = animationMap[animation] ?? fallbackGif;
    return 'assets/gifs/$gifName.gif';
  }

  bool _gifExists(String animation) {
    final groupNum = _getGroupNumber();
    final animationMap = {
      'eating': 'group${groupNum}_eating',
      'petting': 'group${groupNum}_petting',
      'exercise': 'group${groupNum}_exercise',
      'bath': 'group${groupNum}_bath',
      'idle': 'group${groupNum}_eating',
    };

    final gifName = animationMap[animation] ?? 'group1_eating';
    return gifName == 'group1_eating' || gifName.contains('group${_getGroupNumber()}');
  }

  void _playAnimation(String animation) {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _currentAnimation = animation;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentAnimation = 'idle';
          _isAnimating = false;
        });
      }
    });
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
          Center(
            child: Image.asset(
              _getGifPath(_currentAnimation),
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text('GIF를 로드할 수 없습니다');
              },
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
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
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
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton('🍖', 'eating', _isAnimating ? null : () => _playAnimation('eating')),
                _actionButton('❤️', 'petting', _isAnimating ? null : () => _playAnimation('petting')),
                _actionButton('💪', 'exercise', _isAnimating ? null : () => _playAnimation('exercise')),
                _actionButton('🛁', 'bath', _isAnimating ? null : () => _playAnimation('bath')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String emoji, String label, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FloatingActionButton(
        mini: true,
        onPressed: onPressed,
        backgroundColor: onPressed == null ? Colors.grey : ChowColors.orange500,
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
