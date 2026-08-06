import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
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
  WebViewController? _webViewController;
  bool _isWalking = false;
  PetModel? _pet;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPet();
    _initWebViewAsync();
  }

  Future<void> _initWebViewAsync() async {
    try {
      debugPrint('🔧 Creating WebViewController...');
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFlutterAsset('assets/viewer.html');

      _webViewController = controller;
      debugPrint('✅ WebViewController ready');

      if (_pet != null) {
        _loadModel();
      }
    } catch (e) {
      debugPrint('❌ WebView error: $e');
      setState(() => _error = 'WebView 로드 실패: $e');
    }
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
        if (_webViewController != null) {
          _loadModel();
        }
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

    final groupNum = groupMap[_pet?.groupName] ?? 1;
    return groupNum.toString();
  }

  String get _modelPath {
    final groupNum = _getGroupNumber();
    return 'assets/images/characters/character_group_$groupNum.glb';
  }

  Future<void> _loadModel() async {
    if (_pet == null || _webViewController == null) return;
    try {
      debugPrint('📦 Loading GLB: $_modelPath');
      final data = await rootBundle.load(_modelPath);
      final bytes = data.buffer.asUint8List();
      final base64 = base64Encode(bytes);

      final message = {
        'type': 'loadModel',
        'modelData': 'data:model/gltf-binary;base64,$base64',
      };
      await _webViewController!.runJavaScript(
        'window.postMessage(${jsonEncode(message)}, "*")',
      );
      debugPrint('✅ GLB loaded');
    } catch (e) {
      debugPrint('❌ GLB load error: $e');
    }
  }

  void _toggleAnimation() {
    if (_webViewController == null) return;

    setState(() => _isWalking = !_isWalking);
    final message = {
      'type': 'toggleAnimation',
      'walking': _isWalking,
    };
    _webViewController?.runJavaScript(
      'window.postMessage(${jsonEncode(message)}, "*")',
    );
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
          // 3D 캐릭터 표시 영역 (중앙 - WebView)
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
                child: _webViewController != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: WebViewWidget(controller: _webViewController!),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: ChowColors.orange500),
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

          // 애니메이션 상태 표시
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isWalking ? ChowColors.orange500 : ChowColors.gray300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isWalking ? '🚶 걷는 중...' : '⏸️ 정지 중',
                style: TextStyle(
                  color: _isWalking ? Colors.white : ChowColors.gray600,
                  fontWeight: FontWeight.bold,
                ),
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
