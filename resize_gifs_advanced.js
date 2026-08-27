const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

const FRAME_WIDTH = 543;
const FRAME_HEIGHT = 724;

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
        // 1. GIF를 읽고 프레임 수 확인
        const buffer = fs.readFileSync(gifPath);

        // 2. GIF 파일을 PNG로 변환하는 방식 대신,
        //    직접 리사이징된 GIF 생성 시도
        const resized = await sharp(buffer, { animated: true })
          .resize(FRAME_WIDTH, FRAME_HEIGHT, {
            fit: 'fill',  // 정확한 크기로 맞춤
            position: 'center'
          })
          .gif()
          .toBuffer();

        fs.writeFileSync(gifPath, resized);
        console.log(`✅ ${groupNum}_${action}: ${FRAME_WIDTH}x${FRAME_HEIGHT}로 리사이징 완료`);
      } catch (error) {
        console.error(`❌ ${groupNum}_${action}: ${error.message}`);
      }
    }
  }

  console.log('\n✨ 모든 GIF 크기 조정 완료!');
}

resizeActionGifs().catch(console.error);
