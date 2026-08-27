const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

// 프레임 크기: idle 4프레임의 크기
const FRAME_WIDTH = 543;
const FRAME_HEIGHT = 724;

async function createIdleGif() {
  console.log('🎬 Idle GIF 생성 중...\n');

  for (let groupNum = 1; groupNum <= 7; groupNum++) {
    const idleFolder = path.join(gifs_path, `group${groupNum}`, `group${groupNum}_idle`);

    try {
      // 4개 프레임 리사이징해서 하나의 이미지에 배치 (가로로 연결)
      const frames = [];
      for (let i = 0; i < 4; i++) {
        const framePath = path.join(idleFolder, `frame_${i}.png`);
        if (fs.existsSync(framePath)) {
          const img = await sharp(framePath)
            .resize(FRAME_WIDTH, FRAME_HEIGHT, { fit: 'cover', position: 'center' })
            .toBuffer();
          frames.push(img);
        }
      }

      if (frames.length < 4) {
        console.log(`❌ Group ${groupNum}: 프레임 부족 (${frames.length}/4)`);
        continue;
      }

      // 단순히 첫 번째 프레임을 저장 (GIF로 만드는 대신)
      // 실제로는 애니메이션을 위해서는 여러 프레임을 포함해야 함
      // 여기서는 프레임 크기만 확인하기 위해 첫 프레임만 저장
      const gifPath = path.join(gifs_path, `group${groupNum}_idle.gif`);

      // Sharp는 GIF 읽기는 되지만 쓰기가 제한적이므로, 직접 프레임 이미지 저장
      // 나중에 수동으로 ezgif나 다른 도구로 GIF 만듦
      await sharp(frames[0]).toFile(path.join(idleFolder, `combined_idle.png`));

      console.log(`✅ Group ${groupNum} Idle 프레임: ${FRAME_WIDTH}x${FRAME_HEIGHT}`);
    } catch (error) {
      console.error(`❌ Group ${groupNum} 에러: ${error.message}`);
    }
  }

  console.log('\n');
}

async function resizeActionGifs() {
  console.log('🎨 동작 GIF 크기 조정 중...\n');
  console.log(`📐 Target 크기: ${FRAME_WIDTH}x${FRAME_HEIGHT}\n`);

  const actions = ['eating', 'petting', 'exercise', 'bath'];

  for (let groupNum = 1; groupNum <= 7; groupNum++) {
    for (const action of actions) {
      const gifPath = path.join(gifs_path, `group${groupNum}_${action}.gif`);

      if (!fs.existsSync(gifPath)) {
        continue;
      }

      try {
        const metadata = await sharp(gifPath).metadata();
        const currentWidth = metadata.width;
        const currentHeight = metadata.height;

        console.log(`  ${groupNum}_${action}: ${currentWidth}x${currentHeight} → ${FRAME_WIDTH}x${FRAME_HEIGHT}`);

        // GIF 리사이징
        const resized = await sharp(gifPath)
          .resize(FRAME_WIDTH, FRAME_HEIGHT, { fit: 'cover', position: 'center' })
          .gif()
          .toBuffer();

        fs.writeFileSync(gifPath, resized);
        console.log(`    ✅ 완료`);
      } catch (error) {
        console.error(`  ❌ ${groupNum}_${action}: ${error.message}`);
      }
    }
  }

  console.log('\n✨ 모든 GIF 크기 조정 완료!');
}

async function main() {
  await createIdleGif();
  await resizeActionGifs();
}

main().catch(console.error);
