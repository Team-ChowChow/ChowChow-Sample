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
  console.log('🎯 고양이 프레임 중앙 정렬 v2...\n');

  for (const cat of cat_groups) {
    console.log(`Processing ${cat.name}...`);

    // 동작별로 최대 크기 찾기
    const maxSizes = {};

    for (const action of actions) {
      const actionFolder = path.join(gifs_path, cat.name, `${cat.name}_${action}`);
      let maxWidth = 0;
      let maxHeight = 0;

      for (let i = 0; i < 8; i++) {
        const framePath = path.join(actionFolder, `frame_${i}.png`);
        if (fs.existsSync(framePath)) {
          const metadata = await sharp(framePath).metadata();
          maxWidth = Math.max(maxWidth, metadata.width);
          maxHeight = Math.max(maxHeight, metadata.height);
        }
      }

      maxSizes[action] = { width: maxWidth, height: maxHeight };
    }

    // 각 프레임을 투명 배경 캔버스에 중앙 정렬
    for (const action of actions) {
      const actionFolder = path.join(gifs_path, cat.name, `${cat.name}_${action}`);
      const canvasWidth = maxSizes[action].width;
      const canvasHeight = maxSizes[action].height;

      console.log(`  ${action}: canvas ${canvasWidth}x${canvasHeight}`);

      for (let i = 0; i < 8; i++) {
        const framePath = path.join(actionFolder, `frame_${i}.png`);
        if (!fs.existsSync(framePath)) continue;

        try {
          const metadata = await sharp(framePath).metadata();
          const currentWidth = metadata.width;
          const currentHeight = metadata.height;

          // 중앙 정렬 위치
          const left = Math.floor((canvasWidth - currentWidth) / 2);
          const top = Math.floor((canvasHeight - currentHeight) / 2);

          const tempPath = path.join(actionFolder, `frame_${i}_temp.png`);

          // 투명한 배경 생성 후 프레임을 중앙에 composite
          const svg = `<svg width="${canvasWidth}" height="${canvasHeight}"><rect width="${canvasWidth}" height="${canvasHeight}" fill="transparent"/></svg>`;

          await sharp(Buffer.from(svg))
            .png()
            .composite([
              {
                input: framePath,
                left: left,
                top: top
              }
            ])
            .toFile(tempPath);

          fs.unlinkSync(framePath);
          fs.renameSync(tempPath, framePath);

          console.log(`    └─ frame_${i}.png 완료 (offset: ${left}, ${top})`);
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
