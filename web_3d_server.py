#!/usr/bin/env python3
"""
3D 펫 캐릭터 뷰어 웹사이트
Three.js 기반
"""
from flask import Flask
from pathlib import Path

app = Flask(__name__)

# 모델 파일 경로
MODEL_DIR = Path(__file__).parent / "ChowChow-Front" / "flutter_app" / "assets" / "models"

# Three.js 기반 HTML
def get_viewer_html(group_num: int) -> str:
    return f'''
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D 펫 캐릭터</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            width: 100%;
            height: 100vh;
            background: linear-gradient(135deg, #f5f5f5 0%, #e8e8e8 100%);
            overflow: hidden;
        }}
        canvas {{
            display: block;
            width: 100%;
            height: 100%;
        }}
        #info {{
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
        }}
        #controls {{
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            gap: 12px;
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
        }}
        button:active {{
            transform: scale(0.95);
        }}
    </style>
</head>
<body>
    <div id="info">✅ 로드 완료</div>
    <div id="controls">
        <button onclick="toggleRotation()">🚶 정지</button>
        <button onclick="window.history.back()">← 돌아가기</button>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/examples/js/loaders/GLTFLoader.min.js"></script>

    <script>
        let scene, camera, renderer, model, rotating = true;
        const groupNum = {group_num};

        function init() {{
            // Scene
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0xf5f5f5);

            // Camera
            camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.z = 3;

            // Renderer
            renderer = new THREE.WebGLRenderer({{ antialias: true, alpha: true }});
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.pixelRatio = window.devicePixelRatio;
            document.body.appendChild(renderer.domElement);

            // Lighting
            const light1 = new THREE.DirectionalLight(0xffffff, 1);
            light1.position.set(5, 10, 7);
            scene.add(light1);

            const light2 = new THREE.AmbientLight(0xffffff, 0.6);
            scene.add(light2);

            // Load model
            loadModel();

            // Resize handler
            window.addEventListener('resize', onWindowResize);

            // Animation loop
            animate();
        }}

        function loadModel() {{
            const loader = new THREE.GLTFLoader();
            const modelPath = `/models/character_group_${{groupNum}}.glb`;

            console.log('📡 로딩:', modelPath);

            loader.load(
                modelPath,
                (gltf) => {{
                    if (model) scene.remove(model);

                    model = gltf.scene;
                    scene.add(model);

                    // Center and scale
                    const box = new THREE.Box3().setFromObject(model);
                    const center = box.getCenter(new THREE.Vector3());
                    const size = box.getSize(new THREE.Vector3());
                    const maxDim = Math.max(size.x, size.y, size.z);
                    const scale = 2 / maxDim;

                    model.position.sub(center.multiplyScalar(scale));
                    model.scale.multiplyScalar(scale);

                    console.log('✅ 완료');
                    document.getElementById('info').textContent = '✅ 완료';
                }},
                undefined,
                (error) => {{
                    console.error('❌ 에러:', error);
                    document.getElementById('info').textContent = '❌ 로드 실패';
                }}
            );
        }}

        function toggleRotation() {{
            rotating = !rotating;
            document.querySelector('#controls button').textContent = rotating ? '🚶 정지' : '⏸️ 재생';
        }}

        function animate() {{
            requestAnimationFrame(animate);

            if (model && rotating) {{
                model.rotation.y += 0.005;
            }}

            renderer.render(scene, camera);
        }}

        function onWindowResize() {{
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        }}

        // Start
        init();
    </script>
</body>
</html>
    '''

@app.route('/', methods=['GET'])
def index():
    """그룹 선택 페이지"""
    groups = [
        ('Toy', 1, '🐶'),
        ('Terrier', 2, '🐕'),
        ('Working', 3, '🦮'),
        ('Herding', 4, '🐑'),
        ('Hound', 5, '🐩'),
        ('Sporting', 6, '🦆'),
        ('Non-Sporting', 7, '🦴'),
    ]

    html = '''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D 펫 캐릭터</title>
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

    for group_name, group_num, emoji in groups:
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
    """3D 뷰어"""
    if group_num < 1 or group_num > 7:
        return {'error': 'Invalid group'}, 404
    return get_viewer_html(group_num), 200, {'Content-Type': 'text/html; charset=utf-8'}

@app.route('/models/<path:filename>', methods=['GET'])
def serve_model(filename):
    """GLB 파일 제공"""
    from flask import send_file
    try:
        file_path = MODEL_DIR / filename
        if not file_path.exists():
            return {'error': 'Not found'}, 404
        return send_file(file_path, mimetype='model/gltf-binary')
    except Exception as e:
        return {'error': str(e)}, 500

if __name__ == '__main__':
    print('=' * 60)
    print('🚀 3D 펫 캐릭터 웹사이트')
    print('=' * 60)
    print('📍 http://localhost:8888')
    print('🛑 종료: Ctrl+C')
    print('=' * 60)
    app.run(host='localhost', port=8888, debug=True, use_reloader=True)
