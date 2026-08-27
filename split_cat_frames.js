const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

const cat_groups = [
  { name: 'cat1_longhair', label: 'Longhair' },
  { name: 'cat2_shorthair', label: 'Shorthair' },
  { name: 'cat3_hairless', label: 'Hairless' }
];

const actions = ['idle', 'eating', 'petting', 'exercise', 'bath'];

async function splitCatFrames() {
  console.log('🐱 고양이 2x4 프레임 분할 시작...\n');

  for (const cat of cat_groups) {
    for (const action of actions) {
      const actionFolder = path.join(gifs_path, cat.name, `${cat.name}_${action}`);
      const imagePath = path.join(actionFolder, `${cat.name}_${action}.png`);

      if (!fs.existsSync(imagePath)) {
        console.log(`⏭️  ${cat.name}/${action}: 이미지 파일 없음`);
        continue;
      }

      try {
        const metadata = await sharp(imagePath).metadata();
        const imageWidth = metadata.width;
        const imageHeight = metadata.height;

        // 2x4 레이아웃: 가로 4개, 세로 2개
        const frameWidth = Math.floor(imageWidth / 4);
        const frameHeight = Math.floor(imageHeight / 2);

        console.log(`✓ ${cat.name}/${action}: ${imageWidth}x${imageHeight} → ${frameWidth}x${frameHeight} (8 frames)`);

        // 8개 프레임 추출 (2행 x 4열)
        let frameNum = 0;
        for (let row = 0; row < 2; row++) {
          for (let col = 0; col < 4; col++) {
            const framePath = path.join(actionFolder, `frame_${frameNum}.png`);
            const left = col * frameWidth;
            const top = row * frameHeight;

            await sharp(imagePath)
              .extract({ left, top, width: frameWidth, height: frameHeight })
              .toFile(framePath);

            console.log(`  └─ frame_${frameNum}.png`);
            frameNum++;
          }
        }

        console.log('');
      } catch (error) {
        console.error(`❌ ${cat.name}/${action}: ${error.message}`);
      }
    }
  }

  console.log('✨ 모든 고양이 프레임 분할 완료!');
}

splitCatFrames().catch(console.error);
