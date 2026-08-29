import 'package:chowchow/services/recipe_share_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('공유 문구에 제목, 설명, 앱 안내를 포함한다', () {
    final text = RecipeShareContent.shareText(
      title: ' 닭고기 건강식 ',
      subtitle: '관절 건강 맞춤식',
      description: '부드러운 닭고기와\n채소를 넣은 레시피입니다.',
    );

    expect(text, contains('🐾 닭고기 건강식'));
    expect(text, contains('관절 건강 맞춤식'));
    expect(text, contains('부드러운 닭고기와 채소를 넣은 레시피입니다.'));
    expect(text, contains('멍냥밥상에서 레시피를 확인해 보세요 🐾'));
    expect(text, isNot(contains('://')));
  });
}
