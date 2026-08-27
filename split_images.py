from PIL import Image
import os

gifs_base = r"C:\Users\wntjd\Desktop\graduation\ChowChow-Sample\ChowChow-Front\flutter_app\assets\gifs"

for group_num in range(1, 8):
    idle_folder = os.path.join(gifs_base, f"group{group_num}", f"group{group_num}_idle")
    image_path = os.path.join(idle_folder, f"group{group_num}_idle.png")

    if not os.path.exists(image_path):
        print(f"❌ {image_path} 파일을 찾을 수 없습니다")
        continue

    try:
        # 이미지 열기
        img = Image.open(image_path)
        width, height = img.size
        print(f"✓ Group {group_num}: {width}x{height} 로드됨")

        # 높이를 4로 나누기 (세로 4등분)
        frame_height = height // 4

        for frame_num in range(4):
            top = frame_num * frame_height
            bottom = top + frame_height

            # 프레임 자르기
            frame = img.crop((0, top, width, bottom))

            # 저장
            output_path = os.path.join(idle_folder, f"frame_{frame_num}.png")
            frame.save(output_path)
            print(f"  ✅ frame_{frame_num}.png 저장됨")

        print(f"🎬 Group {group_num} 완료!\n")

    except Exception as e:
        print(f"❌ Group {group_num} 처리 실패: {e}\n")

print("✨ 모든 그룹 4등분 완료!")
