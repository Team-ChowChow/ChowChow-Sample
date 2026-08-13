#!/usr/bin/env python3
"""3D 펫 캐릭터 뷰어 - Three.js + 로컬 GLB"""
from flask import Flask
from pathlib import Path

app = Flask(__name__)

# 모델 디렉토리 경로 (절대 경로)
SCRIPT_DIR = Path(__file__).resolve().parent
MODEL_DIR = SCRIPT_DIR / "ChowChow-Front" / "flutter_app" / "assets" / "models"

# 경로 확인
print(f"📂 모델 디렉토리: {MODEL_DIR}")
print(f"📂 존재: {MODEL_DIR.exists()}")
if MODEL_DIR.exists():
    print(f"📂 파일 수: {len(list(MODEL_DIR.glob('*.glb')))}")
    for f in sorted(MODEL_DIR.glob('*.glb')):
        print(f"  ✅ {f.name}")

def get_viewer_html(group_num: int) -> str:
    return f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D 펫 캐릭터 - 그룹 {group_num}</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/examples/js/loaders/GLTFLoader.min.js"></script>
    <style>
        * {{ margin: 0; padding: 0; }}
        body {{ width: 100%; height: 100vh; background: #f5f5f5; font-family: sans-serif; }}
        canvas {{ display: block; width: 100%; height: 100%; }}
        #ui {{ position: fixed; top: 0; left: 0; right: 0; bottom: 0; pointer-events: none; }}
        #info {{ position: fixed; top: 20px; left: 20px; background: white; padding: 12px 16px; border-radius: 8px; font-size: 14px; font-weight: bold; box-shadow: 0 2px 8px rgba(0,0,0,0.1); pointer-events: auto; }}
        #controls {{ position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%); display: flex; gap: 10px; pointer-events: auto; }}
        button {{ padding: 12px 20px; border: none; border-radius: 8px; background: #FF7000; color: white; font-weight: bold; cursor: pointer; box-shadow: 0 2px 10px rgba(255,112,0,0.3); }}
        button:hover {{ background: #E85A00; }}
    </style>
</head>
<body>
    <div id="ui">
        <div id="info">🐕 로딩 중...</div>
        <div id="controls">
            <button onclick="toggle()">🚶 정지</button>
            <button onclick="history.back()">← 돌아가기</button>
        </div>
    </div>

    <script>
        let scene, camera, renderer, model, rotating = true;
        const groupNum = {group_num};

        function init() {{
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0xf5f5f5);

            camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.z = 3;

            renderer = new THREE.WebGLRenderer({{ antialias: true, alpha: true }});
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.pixelRatio = window.devicePixelRatio;
            document.body.appendChild(renderer.domElement);

            const light1 = new THREE.DirectionalLight(0xffffff, 1);
            light1.position.set(5, 10, 7);
            scene.add(light1);

            const light2 = new THREE.AmbientLight(0xffffff, 0.6);
            scene.add(light2);

            window.addEventListener('resize', () => {{
                camera.aspect = window.innerWidth / window.innerHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(window.innerWidth, window.innerHeight);
            }});

            loadModel();
            animate();
        }}

        function loadModel() {{
            const loader = new THREE.GLTFLoader();
            const path = `/models/character_group_${{groupNum}}.glb`;

            console.log('📡', path);
            document.getElementById('info').textContent = '⏳ 로딩 중...';

            loader.load(path, (gltf) => {{
                model = gltf.scene;
                scene.add(model);

                const box = new THREE.Box3().setFromObject(model);
                const center = box.getCenter(new THREE.Vector3());
                const size = box.getSize(new THREE.Vector3());
                const scale = 2 / Math.max(size.x, size.y, size.z);

                model.position.sub(center.multiplyScalar(scale));
                model.scale.multiplyScalar(scale);

                document.getElementById('info').textContent = '✅ 완료';
            }}, undefined, (err) => {{
                document.getElementById('info').textContent = '❌ ' + err.message;
            }});
        }}

        function toggle() {{
            rotating = !rotating;
            document.querySelectorAll('button')[0].textContent = rotating ? '🚶 정지' : '⏸️ 재생';
        }}

        function animate() {{
            requestAnimationFrame(animate);
            if (model && rotating) model.rotation.y += 0.005;
            renderer.render(scene, camera);
        }}

        init();
    </script>
</body>
</html>
    '''

@app.route('/')
def index():
    return '''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D 펫 캐릭터</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;
            background: linear-gradient(135deg, #f5f5f5, #e8e8e8);
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
        h1 { text-align: center; font-size: 32px; margin-bottom: 12px; color: #333; }
        .subtitle { text-align: center; color: #666; margin-bottom: 32px; font-size: 14px; }
        .groups { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 16px; }
        .group-btn {
            padding: 24px;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            background: white;
            cursor: pointer;
            text-align: center;
            text-decoration: none;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 12px;
            font-size: 24px;
            font-weight: 600;
            color: #FF7000;
            transition: all 0.2s;
        }
        .group-btn:hover {
            border-color: #FF7000;
            background: #FFF7F0;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(255, 112, 0, 0.2);
        }
        .group-emoji { font-size: 40px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐕 3D 펫 캐릭터</h1>
        <p class="subtitle">그룹을 선택하세요</p>
        <div class="groups">
            <a href="/character_group_1.html" class="group-btn"><div class="group-emoji">🐶</div>Toy</a>
            <a href="/character_group_2.html" class="group-btn"><div class="group-emoji">🐕</div>Terrier</a>
            <a href="/character_group_3.html" class="group-btn"><div class="group-emoji">🦮</div>Working</a>
            <a href="/character_group_4.html" class="group-btn"><div class="group-emoji">🐑</div>Herding</a>
            <a href="/character_group_5.html" class="group-btn"><div class="group-emoji">🐩</div>Hound</a>
            <a href="/character_group_6.html" class="group-btn"><div class="group-emoji">🦆</div>Sporting</a>
            <a href="/character_group_7.html" class="group-btn"><div class="group-emoji">🦴</div>Non-Sporting</a>
        </div>
    </div>
</body>
</html>
    '''

@app.route('/character_group_<int:group_num>.html')
def viewer(group_num: int):
    if group_num < 1 or group_num > 7:
        return 'Invalid', 404
    return get_viewer_html(group_num), 200, {'Content-Type': 'text/html; charset=utf-8'}

@app.route('/models/<path:filename>')
def serve_model(filename):
    from flask import send_file
    try:
        file_path = MODEL_DIR / filename
        if not file_path.exists():
            return 'Not found', 404
        return send_file(file_path, mimetype='model/gltf-binary')
    except Exception as e:
        return str(e), 500

if __name__ == '__main__':
    print('🚀 3D 펫 캐릭터 웹사이트')
    print('📍 http://localhost:8888')
    app.run(host='localhost', port=8888, debug=True, use_reloader=True)
