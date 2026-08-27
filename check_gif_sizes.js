const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

async function checkSizes() {
  // idle GIF 크기 확인
  const idleGif = path.join(gifs_path, 'group1', 'group1_idle', 'group1_idle.gif');

  if (!fs.existsSync(idleGif)) {
    console.log('❌ Idle GIF 찾을 수 없음');
    return;
  }

  const idleMetadata = await sharp(idleGif).metadata();
  console.log(`✅ Idle GIF 크기: ${idleMetadata.width} x ${idleMetadata.height}`);

  // 다른 동작 GIF들의 크기 확인
  console.log('\n📊 기존 동작 GIF 크기들:');
  const actions = ['eating', 'petting', 'exercise', 'bath'];

  for (const action of actions) {
    const gifPath = path.join(gifs_path, `group1_${action}.gif`);
    if (fs.existsSync(gifPath)) {
      const metadata = await sharp(gifPath).metadata();
      console.log(`  ${action}: ${metadata.width} x ${metadata.height}`);
    } else {
      console.log(`  ${action}: 파일 없음`);
    }
  }
}

checkSizes().catch(console.error);
