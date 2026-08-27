const sharp = require('sharp');
const path = require('path');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

async function checkSizes() {
  console.log('📐 Idle 이미지 크기 확인...\n');

  for (let i = 1; i <= 7; i++) {
    const imagePath = path.join(gifs_path, `group${i}_idle.png`);

    try {
      const metadata = await sharp(imagePath).metadata();
      console.log(`Group ${i}: ${metadata.width} x ${metadata.height}`);
    } catch (error) {
      console.log(`Group ${i}: 파일 없음`);
    }
  }
}

checkSizes().catch(console.error);
