from PIL import Image
import os
import glob
from pathlib import Path

# GIF 저장 경로
gifs_base = r"C:\Users\wntjd\Desktop\graduation\ChowChow-Sample\ChowChow-Front\flutter_app\assets\gifs"

# 각 그룹별로 처리
for group_num in range(1, 8):
    idle_folder = os.path.join(gifs_base, f"group{group_num}", f"group{group_num}_idle")

    if not os.path.exists(idle_folder):
        print(f"❌ {idle_folder} 폴더를 찾을 수 없습니다")
        continue

    # PNG 파일만 찾기
    png_files = sorted(glob.glob(os.path.join(idle_folder, "*.png")))
    png_files = [f for f in png_files if os.path.basename(f) != "frame.html" and not f.endswith(".css")]

    if not png_files:
        print(f"⚠️  {idle_folder}에 PNG 파일이 없습니다")
        continue

    # 처음 4개만 사용 (4프레임)
    frames = png_files[:4]

    if len(frames) < 4:
        print(f"⚠️  {idle_folder}에 PNG 파일이 {len(frames)}개만 있습니다 (4개 필요)")
        frames = png_files  # 있는 것만 사용

    # 이미지 열기
    images = []
    for frame_path in frames:
        try:
            img = Image.open(frame_path)
            images.append(img)
            print(f"✓ 로드: {os.path.basename(frame_path)}")
        except Exception as e:
            print(f"❌ 로드 실패: {frame_path} - {e}")
            continue

    if not images:
        print(f"❌ {idle_folder}에서 이미지를 로드하지 못했습니다")
        continue

    # GIF 생성
    output_path = os.path.join(gifs_base, f"group{group_num}_idle.gif")
    try:
        images[0].save(
            output_path,
            save_all=True,
            append_images=images[1:],
            duration=200,  # 200ms per frame
            loop=0  # 무한 반복
        )
        print(f"✅ GIF 생성 완료: {output_path}")
    except Exception as e:
        print(f"❌ GIF 생성 실패: {e}")

print("\n🎬 모든 GIF 생성 완료!")
