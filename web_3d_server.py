#!/usr/bin/env python3
"""
3D 펫 캐릭터 뷰어 웹사이트
Flask 기반 로컬 개발 서버
배포: Spring Boot 백엔드 또는 별도 호스팅
"""
from flask import Flask
from pathlib import Path

app = Flask(__name__)

# 모델 파일 경로
MODEL_DIR = Path(__file__).parent / "ChowChow-Front" / "flutter_app" / "assets" / "models"

# 각 그룹별 HTML 템플릿
def get_viewer_html(group_num: int) -> str:
    return f'''
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D 펫 캐릭터 - 그룹 {group_num}</title>
    <script type="module" src="https://cdn.jsdelivr.net/npm/@google/model-viewer@4.1.2/dist/model-viewer.min.js"></script>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        html, body {{
            width: 100%;
            height: 100%;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }}
        body {{
            background: linear-gradient(135deg, #f5f5f5 0%, #e8e8e8 100%);
        }}
        model-viewer {{
            width: 100%;
            height: 100%;
            --poster-color: #f5f5f5;
        }}
        .ui {{
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            pointer-events: none;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            align-items: flex-start;
            padding: 20px;
        }}
        .ui > * {{
            pointer-events: auto;
        }}
        .header {{
            display: flex;
            align-items: center;
            gap: 12px;
            background: white;
            padding: 16px;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.1);
        }}
        .header h1 {{
            margin: 0;
            font-size: 20px;
            font-weight: 600;
            color: #333;
        }}
        .status {{
            background: white;
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            color: #666;
        }}
        .controls {{
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            gap: 12px;
            pointer-events: auto;
        }}
        button {{
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            background: #FF7000;
            color: white;
            font-weight: bold;
            font-size: 14px;
            cursor: pointer;
            box-shadow: 0 2px 12px rgba(255, 112, 0, 0.3);
            transition: all 0.2s;
        }}
        button:hover {{
            background: #E85A00;
            box-shadow: 0 4px 16px rgba(255, 112, 0, 0.4);
        }}
        button:active {{
            transform: scale(0.95);
        }}
        .info {{
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: white;
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 12px;
            color: #666;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            pointer-events: auto;
            max-width: 200px;
        }}
    </style>
</head>
<body>
    <model-viewer id="viewer" loading="eager" camera-controls interaction-prompt="none" auto-rotate></model-viewer>

    <div class="ui">
        <div class="header">
            <span>🐕</span>
            <h1>그룹 {group_num} 캐릭터</h1>
        </div>
        <div class="status" id="status">로딩 중...</div>
    </div>

    <div class="controls">
        <button id="toggleBtn" onclick="toggle()">🚶 정지</button>
        <button onclick="goBack()">← 돌아가기</button>
    </div>

    <div class="info">
        💡 클릭하면 회전을 멈출 수 있습니다
    </div>

    <script>
        const viewer = document.getElementById('viewer');
        const toggleBtn = document.getElementById('toggleBtn');
        const status = document.getElementById('status');
        const groupNum = {group_num};
        let walking = true;

        // 모델 로드
        const modelPath = `/models/character_group_${{groupNum}}.glb`;
        console.log('📡 모델 로드:', modelPath);
        viewer.src = modelPath;

        // 모델 로드 완료
        viewer.addEventListener('load', () => {{
            console.log('✅ 모델 로드 완료');
            status.textContent = '✅ 로드 완료';
        }});

        // 로드 에러
        viewer.addEventListener('error', (e) => {{
            console.error('❌ 로드 실패:', e);
            status.textContent = '❌ 로드 실패';
        }});

        // 토글 함수
        function toggle() {{
            walking = !walking;
            viewer.setAttribute('auto-rotate', walking ? 'true' : 'false');
            toggleBtn.textContent = walking ? '🚶 정지' : '⏸️ 재생';
        }}

        // 돌아가기
        function goBack() {{
            window.history.back();
        }}

        // 클릭으로도 토글
        viewer.addEventListener('click', () => {{
            toggle();
        }});
    </script>
</body>
</html>
    '''

# 라우트
@app.route('/', methods=['GET'])
def index():
    """그룹 선택 페이지"""
    groups = [
        ('Toy', 1),
        ('Terrier', 2),
        ('Working', 3),
        ('Herding', 4),
        ('Hound', 5),
        ('Sporting', 6),
        ('Non-Sporting', 7),
    ]

    html = '''
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D 펫 캐릭터 뷰어</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #f5f5f5 0%, #e8e8e8 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.15);
            max-width: 600px;
        }
        h1 {
            text-align: center;
            font-size: 32px;
            margin-bottom: 12px;
            color: #333;
        }
        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 32px;
            font-size: 14px;
        }
        .groups {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
            gap: 16px;
        }
        .group-btn {
            padding: 24px;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            background: white;
            cursor: pointer;
            text-align: center;
            transition: all 0.2s;
            text-decoration: none;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 12px;
            font-size: 24px;
            font-weight: 600;
            color: #FF7000;
        }
        .group-btn:hover {
            border-color: #FF7000;
            background: #FFF7F0;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(255, 112, 0, 0.2);
        }
        .group-emoji {
            font-size: 40px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐕 3D 펫 캐릭터</h1>
        <p class="subtitle">보고 싶은 그룹을 선택하세요</p>
        <div class="groups">
    '''

    for group_name, group_num in groups:
        emoji_map = {
            'Toy': '🐶',
            'Terrier': '🐕',
            'Working': '🦮',
            'Herding': '🐑',
            'Hound': '🐩',
            'Sporting': '🦆',
            'Non-Sporting': '🦴',
        }
        emoji = emoji_map.get(group_name, '🐕')
        html += f'''
            <a href="/character_group_{group_num}.html" class="group-btn">
                <div class="group-emoji">{emoji}</div>
                {group_name}
            </a>
        '''

    html += '''
        </div>
    </div>
</body>
</html>
    '''
    return html

@app.route('/character_group_<int:group_num>.html', methods=['GET'])
def viewer(group_num: int):
    """3D 뷰어 페이지"""
    if group_num < 1 or group_num > 7:
        return {'error': 'Invalid group number'}, 404
    return get_viewer_html(group_num), 200, {'Content-Type': 'text/html; charset=utf-8'}

@app.route('/models/<path:filename>', methods=['GET'])
def serve_model(filename):
    """GLB 모델 파일 제공"""
    from flask import send_file
    try:
        file_path = MODEL_DIR / filename
        if not file_path.exists():
            return {'error': 'Model not found'}, 404
        return send_file(file_path, mimetype='model/gltf-binary')
    except Exception as e:
        return {'error': str(e)}, 500

@app.route('/health', methods=['GET'])
def health():
    """헬스 체크"""
    return {'status': 'ok'}

if __name__ == '__main__':
    print('=' * 60)
    print('🚀 3D 펫 캐릭터 웹사이트 시작')
    print('=' * 60)
    print('📍 접속: http://localhost:8888')
    print('🐕 그룹 선택: http://localhost:8888/')
    print('🎨 그룹 1 보기: http://localhost:8888/character_group_1.html')
    print('🛑 종료: Ctrl+C')
    print('=' * 60)
    print()

    app.run(
        host='localhost',
        port=8888,
        debug=True,
        use_reloader=True
    )
