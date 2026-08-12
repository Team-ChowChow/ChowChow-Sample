import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadPet();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('✅ WebView 페이지 로드 완료');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView 에러: ${error.description}');
          },
        ),
      );
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
        _loadWebView();
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

  Future<void> _loadWebView() async {
    if (_pet == null) return;

    try {
      final groupNum = _getGroupNumber();

      // 간단한 HTML 직접 생성
      final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="module" src="https://cdn.jsdelivr.net/npm/@google/model-viewer@4.1.2/dist/model-viewer.min.js"></script>
    <style>
        * { margin: 0; padding: 0; }
        body { width: 100%; height: 100vh; }
        model-viewer {
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #f5f5f5 0%, #e8e8e8 100%);
        }
        .controls {
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
        }
        button {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            background: #FF7000;
            color: white;
            font-weight: bold;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <model-viewer id="viewer" camera-controls interaction-prompt="none" auto-rotate></model-viewer>
    <div class="controls">
        <button onclick="toggle()">🚶 정지</button>
    </div>
    <script>
        const viewer = document.getElementById('viewer');
        let walking = true;

        // 플랫폼별 모델 경로
        const model = 'character_group_$groupNum.glb';

        // Android/iOS의 경우 file:// 경로 사용
        viewer.src = 'file:///android_asset/flutter_assets/assets/models/' + model;

        function toggle() {
            walking = !walking;
            viewer.setAttribute('auto-rotate', walking);
            document.querySelector('button').textContent = walking ? '⏸️ 정지' : '🚶 재생';
        }
    </script>
</body>
</html>
      ''';

      _webViewController.loadHtmlString(html);

      debugPrint('🌐 WebView 로드됨 (그룹: $groupNum)');
    } catch (e) {
      debugPrint('❌ WebView 로드 실패: $e');
    }
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
          // WebView (3D 모델)
          WebViewWidget(controller: _webViewController),

          // 상태창 (왼쪽 위)
          Positioned(
            top: 16,
            left: 16,
            child: _buildStatsPanel(),
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
