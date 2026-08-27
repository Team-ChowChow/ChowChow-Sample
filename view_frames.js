const path = require('path');
const fs = require('fs');

const gifs_path = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs';

const frames = [
  'cat1_longhair/cat1_longhair_idle/frame_0.png',
  'cat1_longhair/cat1_longhair_idle/frame_1.png',
  'cat1_longhair/cat1_longhair_idle/frame_2.png',
  'cat1_longhair/cat1_longhair_idle/frame_3.png',
];

console.log('🖼️  cat1_longhair idle 프레임 확인:\n');

frames.forEach((frame, idx) => {
  const fullPath = path.join(gifs_path, frame);
  if (fs.existsSync(fullPath)) {
    const size = fs.statSync(fullPath).size;
    console.log(`frame_${idx}: ${fullPath}`);
    console.log(`  크기: ${size} bytes\n`);
  }
});

console.log('💡 프레임 파일들이 있습니다.');
console.log('직접 이미지 파일을 열어서 캐릭터 위치를 확인해보세요!');
