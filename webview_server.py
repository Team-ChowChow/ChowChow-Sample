#!/usr/bin/env python3
"""
3D Model Viewer Server (개발 중 로컬 테스트용)
배포 시: Spring Boot의 /viewer 엔드포인트로 통합
"""
from flask import Flask, send_file, send_from_directory, render_template_string
import os
from pathlib import Path

app = Flask(__name__)

# 모델 파일 경로
MODEL_DIR = Path(__file__).parent / "ChowChow-Front" / "flutter_app" / "assets" / "models"
STATIC_DIR = Path(__file__).parent / "ChowChow-Front" / "flutter_app" / "assets"

# HTML 템플릿
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D Model Viewer</title>
    <script type="module" src="https://cdn.jsdelivr.net/npm/@google/model-viewer@4.1.2/dist/model-viewer.min.js"></script>
    <style>
        * { margin: 0; padding: 0; }
        body {
            width: 100%;
            height: 100vh;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
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
            display: flex;
            gap: 10px;
            z-index: 100;
        }
        button {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            background-color: #FF7000;
            color: white;
            font-weight: bold;
            font-size: 14px;
            cursor: pointer;
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
            transition: all 0.2s;
        }
        button:hover {
            background-color: #E85A00;
        }
        button:active {
            transform: scale(0.95);
        }
        .status {
            position: fixed;
            top: 20px;
            left: 20px;
            background: white;
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: bold;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            color: #333;
        }
    </style>
</head>
<body>
    <div class="status" id="status">✅ 로드 완료</div>
    <model-viewer id="viewer" loading="eager" camera-controls interaction-prompt="none" auto-rotate></model-viewer>
    <div class="controls">
        <button id="toggleBtn" onclick="toggle()">🚶 정지</button>
    </div>

    <script>
        const viewer = document.getElementById('viewer');
        const toggleBtn = document.getElementById('toggleBtn');
        const status = document.getElementById('status');
        let walking = true;

        // URL 파라미터에서 모델 가져오기
        const urlParams = new URLSearchParams(window.location.search);
        const modelParam = urlParams.get('model');
        const modelPath = modelParam ? '/models/' + modelParam + '.glb' : '/models/character_group_1.glb';

        console.log('📡 모델 로드:', modelPath);
        viewer.src = modelPath;

        // 모델 로드 완료
        viewer.addEventListener('load', () => {
            console.log('✅ 모델 로드 완료');
            status.textContent = '✅ 로드 완료';
        });

        // 로드 에러
        viewer.addEventListener('error', (e) => {
            console.error('❌ 로드 실패:', e);
            status.textContent = '❌ 로드 실패';
        });

        // 걷기 애니메이션 토글
        function toggle() {
            walking = !walking;
            viewer.setAttribute('auto-rotate', walking ? 'true' : 'false');
            toggleBtn.textContent = walking ? '⏸️ 정지' : '🚶 재생';
            console.log('🎬 애니메이션:', walking ? '재생' : '정지');
        }

        // 클릭으로도 토글
        viewer.addEventListener('click', () => {
            toggle();
        });
    </script>
</body>
</html>
'''

@app.route('/', methods=['GET'])
def index():
    """메인 뷰어 페이지"""
    return render_template_string(HTML_TEMPLATE)

@app.route('/models/<model_name>.glb', methods=['GET'])
def get_model(model_name):
    """GLB 모델 파일 제공"""
    try:
        file_path = MODEL_DIR / f"{model_name}.glb"
        if not file_path.exists():
            return {'error': f'Model not found: {model_name}'}, 404

        print(f'📦 Serving model: {model_name}')
        return send_file(
            file_path,
            mimetype='model/gltf-binary',
            as_attachment=False
        )
    except Exception as e:
        print(f'❌ Error serving model: {e}')
        return {'error': str(e)}, 500

@app.route('/health', methods=['GET'])
def health():
    """헬스 체크"""
    return {'status': 'ok', 'message': '3D Viewer Server is running'}

if __name__ == '__main__':
    print('🚀 3D Viewer Server 시작...')
    print('📍 접속: http://localhost:8888')
    print('🐕 모델 테스트: http://localhost:8888/?model=character_group_5')
    print('🛑 종료: Ctrl+C')
    print()

    app.run(
        host='localhost',
        port=8888,
        debug=True,
        use_reloader=True
    )
