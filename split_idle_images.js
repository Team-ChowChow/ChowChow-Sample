const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifsBase = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

async function splitImage(groupNum) {
  const idleFolder = path.join(gifsBase, `group${groupNum}`, `group${groupNum}_idle`);
  const imagePath = path.join(idleFolder, `group${groupNum}_idle.png`);

  if (!fs.existsSync(imagePath)) {
    console.log(`❌ Group ${groupNum}: 파일 없음`);
    return;
  }

  try {
    const metadata = await sharp(imagePath).metadata();
    const frameWidth = Math.floor(metadata.width / 4);
    const frameHeight = metadata.height;

    console.log(`처리 중: Group ${groupNum} (${metadata.width}x${metadata.height}) -> 4등분 ${frameWidth}x${frameHeight}`);

    for (let i = 0; i < 4; i++) {
      const framePath = path.join(idleFolder, `frame_${i}.png`);
      const left = i * frameWidth;

      await sharp(imagePath)
        .extract({ left, top: 0, width: frameWidth, height: frameHeight })
        .toFile(framePath);
      console.log(`  ✅ frame_${i}.png (left: ${left})`);
    }

    console.log(`✨ Group ${groupNum} 완료\n`);
  } catch (error) {
    console.error(`❌ Group ${groupNum} 에러: ${error.message}`);
  }
}

async function main() {
  console.log('🎬 Idle 이미지 4등분 시작...\n');

  for (let i = 1; i <= 7; i++) {
    await splitImage(i);
  }

  console.log('✨ 모든 이미지 4등분 완료!');
}

main();
