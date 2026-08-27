const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

async function splitIdleImages() {
  console.log('🎬 Idle PNG 8프레임 분할 시작...\n');

  for (let groupNum = 1; groupNum <= 7; groupNum++) {
    const imagePath = path.join(gifs_path, `group${groupNum}_idle.png`);

    if (!fs.existsSync(imagePath)) {
      console.log(`❌ Group ${groupNum}: 파일 없음`);
      continue;
    }

    try {
      const metadata = await sharp(imagePath).metadata();
      console.log(`Group ${groupNum}: ${metadata.width} x ${metadata.height}`);

      // 가로 8등분
      const frameWidth = Math.floor(metadata.width / 8);
      const frameHeight = metadata.height;

      const idleFolder = path.join(gifs_path, `group${groupNum}`, `group${groupNum}_idle`);
      if (!fs.existsSync(idleFolder)) {
        fs.mkdirSync(idleFolder, { recursive: true });
      }

      console.log(`  → 프레임 크기: ${frameWidth}x${frameHeight}`);

      // 8개 프레임 추출
      for (let i = 0; i < 8; i++) {
        const framePath = path.join(idleFolder, `frame_${i}.png`);
        const left = i * frameWidth;

        await sharp(imagePath)
          .extract({ left, top: 0, width: frameWidth, height: frameHeight })
          .toFile(framePath);

        console.log(`  ✅ frame_${i}.png`);
      }

      console.log(`✨ Group ${groupNum} 완료\n`);
    } catch (error) {
      console.error(`❌ Group ${groupNum} 에러: ${error.message}`);
    }
  }

  console.log('✨ 모든 Idle PNG 분할 완료!');
}

splitIdleImages().catch(console.error);
