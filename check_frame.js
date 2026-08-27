const sharp = require('sharp');

const framePath = 'C:\\Users\\wntjd\\Desktop\\graduation\\ChowChow-Sample\\ChowChow-Front\\flutter_app\\assets\\gifs\\cat1_longhair\\cat1_longhair_idle\\frame_0.png';

sharp(framePath).metadata().then(m => {
  console.log('이미지 크기:', m.width, 'x', m.height);
  console.log('Format:', m.format);
  console.log('hasAlpha (투명도):', m.hasAlpha);
}).catch(e => console.error('에러:', e.message));
