const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

const cat_groups = [
  { name: 'cat1_longhair' },
  { name: 'cat2_shorthair' },
  { name: 'cat3_hairless' }
];

const actions = ['idle', 'eating', 'petting', 'exercise', 'bath'];

async function centerAlignFrames() {
  console.log('🎯 고양이 프레임 중앙 정렬 시작...\n');

  for (const cat of cat_groups) {
    console.log(`Processing ${cat.name}...`);

    // 동작별로 최대 크기 찾기
    const maxSizes = {};

    for (const action of actions) {
      const actionFolder = path.join(gifs_path, cat.name, `${cat.name}_${action}`);
      let maxWidth = 0;
      let maxHeight = 0;

      // 모든 프레임의 크기 확인
      for (let i = 0; i < 8; i++) {
        const framePath = path.join(actionFolder, `frame_${i}.png`);
        if (fs.existsSync(framePath)) {
          const metadata = await sharp(framePath).metadata();
          maxWidth = Math.max(maxWidth, metadata.width);
          maxHeight = Math.max(maxHeight, metadata.height);
        }
      }

      maxSizes[action] = { width: maxWidth, height: maxHeight };
      console.log(`  ${action}: ${maxWidth}x${maxHeight}`);
    }

    // 각 프레임을 최대 크기에 맞춰서 중앙 정렬
    for (const action of actions) {
      const actionFolder = path.join(gifs_path, cat.name, `${cat.name}_${action}`);
      const canvasWidth = maxSizes[action].width;
      const canvasHeight = maxSizes[action].height;

      for (let i = 0; i < 8; i++) {
        const framePath = path.join(actionFolder, `frame_${i}.png`);
        if (!fs.existsSync(framePath)) continue;

        const metadata = await sharp(framePath).metadata();
        const currentWidth = metadata.width;
        const currentHeight = metadata.height;

        // 중앙 정렬 위치 계산
        const offsetLeft = Math.floor((canvasWidth - currentWidth) / 2);
        const offsetTop = Math.floor((canvasHeight - currentHeight) / 2);

        try {
          // 배경이 투명한 PNG로 확장
          const tempPath = path.join(actionFolder, `frame_${i}_temp.png`);

          await sharp(framePath)
            .extend({
              top: offsetTop,
              bottom: canvasHeight - currentHeight - offsetTop,
              left: offsetLeft,
              right: canvasWidth - currentWidth - offsetLeft,
              background: { r: 0, g: 0, b: 0, alpha: 0 } // 투명 배경
            })
            .png()
            .toFile(tempPath);

          // 원본 삭제 후 교체
          fs.unlinkSync(framePath);
          fs.renameSync(tempPath, framePath);

          console.log(`    └─ frame_${i}.png 중앙 정렬 완료`);
        } catch (error) {
          console.error(`    ❌ frame_${i}: ${error.message}`);
        }
      }
    }

    console.log('');
  }

  console.log('✨ 모든 프레임 중앙 정렬 완료!');
}

centerAlignFrames().catch(console.error);
