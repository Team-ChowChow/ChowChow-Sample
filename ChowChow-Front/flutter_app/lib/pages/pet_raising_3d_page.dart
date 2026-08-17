import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  String _getGifPath(String animation) {
    final group = _groupNumber();
    final animName = animation;

    // 명시적 1:1 매핑
    if (group == 1) {
      if (animName == 'idle') return 'assets/gifs/group1_idle.gif';
      if (animName == 'eating') return 'assets/gifs/group1_eating.gif';
      if (animName == 'petting') return 'assets/gifs/group1_petting.gif';
      if (animName == 'exercise') return 'assets/gifs/group1_exercise.gif';
      if (animName == 'bath') return 'assets/gifs/group1_bath.gif';
    } else if (group == 2) {
      if (animName == 'idle') return 'assets/gifs/group2_idle.gif';
      if (animName == 'eating') return 'assets/gifs/group2_eating.gif';
      if (animName == 'petting') return 'assets/gifs/group2_petting.gif';
      if (animName == 'exercise') return 'assets/gifs/group2_exercise.gif';
      if (animName == 'bath') return 'assets/gifs/group2_bath.gif';
    } else if (group == 3) {
      if (animName == 'idle') return 'assets/gifs/group3_idle.gif';
      if (animName == 'eating') return 'assets/gifs/group3_eating.gif';
      if (animName == 'petting') return 'assets/gifs/group3_petting.gif';
      if (animName == 'exercise') return 'assets/gifs/group3_exercise.gif';
      if (animName == 'bath') return 'assets/gifs/group3_bath.gif';
    } else if (group == 4) {
      if (animName == 'idle') return 'assets/gifs/group4_idle.gif';
      if (animName == 'eating') return 'assets/gifs/group4_eating.gif';
      if (animName == 'petting') return 'assets/gifs/group4_petting.gif';
      if (animName == 'exercise') return 'assets/gifs/group4_exercise.gif';
      if (animName == 'bath') return 'assets/gifs/group4_bath.gif';
    } else if (group == 5) {
      if (animName == 'idle') return 'assets/gifs/group5_idle.gif';
      if (animName == 'eating') return 'assets/gifs/group5_eating.gif';
      if (animName == 'petting') return 'assets/gifs/group5_petting.gif';
      if (animName == 'exercise') return 'assets/gifs/group5_exercise.gif';
      if (animName == 'bath') return 'assets/gifs/group5_bath.gif';
    } else if (group == 6) {
      if (animName == 'idle') return 'assets/gifs/group6_idle.gif';
      if (animName == 'eating') return 'assets/gifs/group6_eating.gif';
      if (animName == 'petting') return 'assets/gifs/group6_petting.gif';
      if (animName == 'exercise') return 'assets/gifs/group6_exercise.gif';
      if (animName == 'bath') return 'assets/gifs/group6_bath.gif';
    } else if (group == 7) {
      if (animName == 'idle') return 'assets/gifs/group7_idle.gif';
      if (animName == 'eating') return 'assets/gifs/group7_eating.gif';
      if (animName == 'petting') return 'assets/gifs/group7_petting.gif';
      if (animName == 'exercise') return 'assets/gifs/group7_exercise.gif';
      if (animName == 'bath') return 'assets/gifs/group7_bath.gif';
    }

    return 'assets/gifs/group1_idle.gif'; // 기본값
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
          child: Text(_error!),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ChowCozy.stone100, ChowCozy.stone50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                _getGifPath(_currentAnimation),
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    mini: true,
                    onPressed: _isAnimating ? null : () => _playAnimation('eating'),
                    backgroundColor: _isAnimating ? Colors.grey : ChowCozy.stone500,
                    child: const Text('🍖', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _isAnimating ? null : () => _playAnimation('petting'),
                    backgroundColor: _isAnimating ? Colors.grey : ChowCozy.stone500,
                    child: const Text('❤️', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _isAnimating ? null : () => _playAnimation('exercise'),
                    backgroundColor: _isAnimating ? Colors.grey : ChowCozy.stone500,
                    child: const Text('💪', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _isAnimating ? null : () => _playAnimation('bath'),
                    backgroundColor: _isAnimating ? Colors.grey : ChowCozy.stone500,
                    child: const Text('🛁', style: TextStyle(fontSize: 20)),
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
