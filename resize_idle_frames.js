const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

const TARGET_WIDTH = 272;
const TARGET_HEIGHT = 724;

async function resizeIdleFrames() {
  console.log(`🎨 Idle 프레임 크기 조정 중 (${TARGET_WIDTH}x${TARGET_HEIGHT})...\n`);

  for (let groupNum = 1; groupNum <= 7; groupNum++) {
    const idleFolder = path.join(gifs_path, `group${groupNum}`, `group${groupNum}_idle`);

    try {
      // frame_0.png ~ frame_3.png 리사이징
      for (let i = 0; i < 4; i++) {
        const framePath = path.join(idleFolder, `frame_${i}.png`);
        const tempPath = path.join(idleFolder, `frame_${i}_temp.png`);

        if (fs.existsSync(framePath)) {
          // 임시 파일로 저장
          await sharp(framePath)
            .resize(TARGET_WIDTH, TARGET_HEIGHT, {
              fit: 'cover',
              position: 'center'
            })
            .toFile(tempPath);

          // 원본 삭제 후 임시 파일을 원본으로 이름 변경
          fs.unlinkSync(framePath);
          fs.renameSync(tempPath, framePath);

          console.log(`  ✅ Group ${groupNum} frame_${i}.png → ${TARGET_WIDTH}x${TARGET_HEIGHT}`);
        }
      }
    } catch (error) {
      console.error(`❌ Group ${groupNum}: ${error.message}`);
    }
  }

  console.log('\n✨ 모든 Idle 프레임 크기 조정 완료!');
}

resizeIdleFrames().catch(console.error);
