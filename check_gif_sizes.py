from PIL import Image
import os

gifs_path = r'C:\Users\wntjd\Desktop\graduation\ChowChow-Sample\ChowChow-Front\flutter_app\assets\gifs'

# idle GIF 크기 확인
idle_gif = os.path.join(gifs_path, 'group1', 'group1_idle', 'group1_idle.gif')
if os.path.exists(idle_gif):
    img = Image.open(idle_gif)
    print(f'✅ Idle GIF 크기: {img.width} x {img.height}')
    target_width = img.width
    target_height = img.height
    img.close()
else:
    print('❌ Idle GIF 찾을 수 없음')
    exit(1)

# 다른 동작 GIF들의 크기 확인
print('\n📊 기존 동작 GIF 크기들:')
actions = ['eating', 'petting', 'exercise', 'bath']
for action in actions:
    gif_path = os.path.join(gifs_path, f'group1_{action}.gif')
    if os.path.exists(gif_path):
        img = Image.open(gif_path)
        print(f'  {action}: {img.width} x {img.height}')
        img.close()
