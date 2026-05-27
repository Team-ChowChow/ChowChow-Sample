/// React 앱과 동일한 목업 데이터
class MealPhoto {
  const MealPhoto({
    required this.id,
    required this.image,
    required this.title,
    required this.date,
    required this.likes,
  });
  final int id;
  final String image;
  final String title;
  final String date;
  final int likes;
}

class TrendingRecipe {
  const TrendingRecipe({
    required this.id,
    required this.image,
    required this.title,
    required this.tags,
  });
  final int id;
  final String image;
  final String title;
  final List<String> tags;
}

class SearchRecipe {
  const SearchRecipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.author,
    required this.tags,
  });
  final int id;
  final String title;
  final String ingredients;
  final String image;
  final double rating;
  final int reviews;
  final String author;
  final List<String> tags;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.avatar,
    required this.timeAgo,
    required this.content,
    required this.image,
    required this.likes,
    required this.comments,
    required this.views,
    required this.tags,
  });
  final int id;
  final String author;
  final String avatar;
  final String timeAgo;
  final String content;
  final String image;
  final int likes;
  final int comments;
  final int views;
  final List<String> tags;
}

class UserPet {
  const UserPet({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.weight,
    required this.allergies,
    required this.image,
  });
  final int id;
  final String name;
  final String type;
  final String breed;
  final String age;
  final String weight;
  final List<String> allergies;
  final String image;
}

final kMealPhotos = <MealPhoto>[
  MealPhoto(
    id: 1,
    image:
        'https://images.unsplash.com/photo-1760445528367-7f0fa0229d19?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBlYXRpbmclMjBoZWFsdGh5JTIwbWVhbHxlbnwxfHx8fDE3NzE0MjIwOTh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: '닭가슴살 야채 볶음',
    date: '2026.02.18',
    likes: 24,
  ),
  MealPhoto(
    id: 2,
    image:
        'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXQlMjBmb29kJTIwaW5ncmVkaWVudHMlMjB2ZWdldGFibGVzfGVufDF8fHx8MTc3MTQyMjA5OXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: '연어 고구마 믹스',
    date: '2026.02.17',
    likes: 31,
  ),
  MealPhoto(
    id: 3,
    image:
        'https://images.unsplash.com/photo-1769947322352-dd6cbdc4ec2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXQlMjBlYXRpbmclMjBmb29kfGVufDF8fHx8MTc3MTM2MDQzMHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: '참치 브로콜리 스튜',
    date: '2026.02.16',
    likes: 18,
  ),
];

final kTrendingRecipes = <TrendingRecipe>[
  TrendingRecipe(
    id: 1,
    image:
        'https://images.unsplash.com/photo-1588505617603-f80b72bf8f24?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBmb29kJTIwY2hpY2tlbiUyMHZlZ2V0YWJsZXMlMjBoZWFsdGh5JTIwbWVhbHxlbnwxfHx8fDE3NzQ0MzI2Njh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: '닭가슴살 야채 볶음',
    tags: ['#트렌드', '#저지방'],
  ),
  TrendingRecipe(
    id: 2,
    image:
        'https://images.unsplash.com/photo-1565299647508-7c3b8ec04837?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzYWxtb24lMjBzd2VldCUyMHBvdGF0byUyMHBldCUyMGZvb2QlMjBpbmdyZWRpZW50c3xlbnwxfHx8fDE3NzQ0MzI2Njh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: '연어 고구마 믹스',
    tags: ['#오메가3', '#영양만점'],
  ),
  TrendingRecipe(
    id: 3,
    image:
        'https://images.unsplash.com/photo-1769195045450-a53e5fef9d5e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWVmJTIwYnJvY2NvbGklMjBkb2clMjBudXRyaXRpb24lMjBtZWFsfGVufDF8fHx8MTc3NDQzMjY2OXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: '소고기 브로콜리',
    tags: ['#단백질', '#근육발달'],
  ),
  TrendingRecipe(
    id: 4,
    image:
        'https://images.unsplash.com/photo-1739595415308-ba632ebfbfe2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxob21lbWFkZSUyMHBldCUyMGZvb2QlMjBjb29raW5nJTIwcHJlcGFyYXRpb258ZW58MXx8fHwxNzc0NDMyNjY5fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: '홈메이드 특선 요리',
    tags: ['#수제', '#프리미엄'],
  ),
];

final kSearchRecipes = <SearchRecipe>[
  SearchRecipe(
    id: 1,
    title: '토종닭 저지방 닭가슴살 레시피',
    ingredients: '주재료: 닭가슴살, 고구마, ...',
    image:
        'https://images.unsplash.com/photo-1684882726821-2999db517441?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaGlja2VuJTIwYnJlYXN0JTIwdmVnZXRhYmxlJTIwZG9nJTIwZm9vZHxlbnwxfHx8fDE3NzUwMzg2NzV8MA&ixlib=rb-4.1.0&q=80&w=1080',
    rating: 4.8,
    reviews: 234,
    author: '명랑이엄마',
    tags: ['#저지방', '#다이어트'],
  ),
  SearchRecipe(
    id: 2,
    title: '연어 오메가3 영양 밥',
    ingredients: '주재료: 연어, 현미, 당근, ...',
    image:
        'https://images.unsplash.com/photo-1580683750935-cecfc7ea57f0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzYWxtb24lMjByaWNlJTIwdmVnZXRhYmxlJTIwYm93bHxlbnwxfHx8fDE3NzUwMzg2NzV8MA&ixlib=rb-4.1.0&q=80&w=1080',
    rating: 4.9,
    reviews: 189,
    author: '냥이집사',
    tags: ['#트렌드', '#면역력'],
  ),
  SearchRecipe(
    id: 3,
    title: '소고기 야채 영양식',
    ingredients: '주재료: 소고기, 단호박, ...',
    image:
        'https://images.unsplash.com/photo-1618788856642-8e491177d973?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmcmVzaCUyMG1lYXQlMjB2ZWdldGFibGVzJTIwY29va2luZ3xlbnwxfHx8fDE3NzUwMzg2NzZ8MA&ixlib=rb-4.1.0&q=80&w=1080',
    rating: 4.7,
    reviews: 156,
    author: '댕댕이아빠',
    tags: ['#시니어', '#치아건강'],
  ),
];

final kCommunityPosts = <CommunityPost>[
  CommunityPost(
    id: 1,
    author: '멍멍이엄마',
    avatar: '🐕',
    timeAgo: '2시간 전',
    content:
        '오늘 초코한테 닭가슴살 야채 볶음 만들어줬어요! 너무 잘 먹네요 😊',
    image:
        'https://images.unsplash.com/photo-1760445528367-7f0fa0229d19?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBlYXRpbmclMjBoZWFsdGh5JTIwbWVhbHxlbnwxfHx8fDE3NzE0MjIwOTh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    likes: 42,
    comments: 8,
    views: 156,
    tags: ['#닭가슴살', '#야채볶음'],
  ),
  CommunityPost(
    id: 2,
    author: '냥이집사',
    avatar: '🐱',
    timeAgo: '5시간 전',
    content:
        '연어 고구마 믹스 레시피 따라해봤는데 대박입니다! 우리 나비가 평소에 밥을 안 먹는 편인데 이건 진짜 순식간에 다 먹었어요 ㅋㅋㅋ',
    image:
        'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXQlMjBmb29kJTIwaW5ncmVkaWVudHMlMjB2ZWdldGFibGVzfGVufDF8fHx8MTc3MTQyMjA5OXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    likes: 67,
    comments: 12,
    views: 234,
    tags: ['#연어', '#고구마', '#강추'],
  ),
  CommunityPost(
    id: 3,
    author: '펫푸드마스터',
    avatar: '👨‍🍳',
    timeAgo: '1일 전',
    content:
        '소고기 채소 스튜 만드는 팁 공유할게요! 소고기는 꼭 살짝 데쳐서 기름을 빼주세요. 반려동물 소화에 훨씬 좋답니다 👍',
    image:
        'https://images.unsplash.com/photo-1769947322352-dd6cbdc4ec2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXQlMjBlYXRpbmclMjBmb29kfGVufDF8fHx8MTc3MTM2MDQzMHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    likes: 89,
    comments: 15,
    views: 412,
    tags: ['#소고기', '#채소스튜', '#팁'],
  ),
];

final kUserPets = <UserPet>[
  UserPet(
    id: 1,
    name: '초코',
    type: '강아지',
    breed: '골든 리트리버',
    age: '3살',
    weight: '28kg',
    allergies: ['닭고기', '밀'],
    image:
        'https://images.unsplash.com/photo-1744824838728-59f825fc7da1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBwb3J0cmFpdCUyMGN1dGV8ZW58MXx8fHwxNzcxNDIyMDk5fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
  ),
  UserPet(
    id: 2,
    name: '나비',
    type: '고양이',
    breed: '코리안 숏헤어',
    age: '2살',
    weight: '4.2kg',
    allergies: ['생선'],
    image:
        'https://images.unsplash.com/photo-1769947322352-dd6cbdc4ec2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXQlMjBlYXRpbmclMjBmb29kfGVufDF8fHx8MTc3MTM2MDQzMHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
  ),
];

const kPopularSearches = <({int rank, String term, bool isNew})>[
  (rank: 1, term: '닭가슴살 레시피', isNew: false),
  (rank: 2, term: '다이어트 펫푸드', isNew: true),
  (rank: 3, term: '알레르기 대응식', isNew: false),
  (rank: 4, term: '강아지 간식', isNew: false),
  (rank: 5, term: '연어 고구마', isNew: true),
  (rank: 6, term: '생식 레시피', isNew: false),
  (rank: 7, term: '저지방 식단', isNew: false),
  (rank: 8, term: '시니어 건강식', isNew: true),
  (rank: 9, term: '치킨 야채볼', isNew: false),
  (rank: 10, term: '면역력 강화', isNew: false),
];

const kAutocompleteSuggestions = [
  '닭가슴살 야채 통조림',
  '닭가슴살 고구마 볼',
  '닭가슴살 연어 믹스',
  '닭가슴살 브로콜리',
];

const kPopularCategories = [
  '#트렌드',
  '#저지방',
  '#알러지프리',
  '#시니어',
  '#피부/키트',
  '#다이어트',
  '#치아건강',
  '#면역력',
];

const kTrendingTopics = <({String name, int count})>[
  (name: '저지방 레시피', count: 234),
  (name: '알러지 프리', count: 189),
  (name: '다이어트 식단', count: 156),
  (name: '시니어 케어', count: 142),
];

const kRecipeGenSteps = [
  '반려동물 정보 분석 중...',
  '알레르기 정보 확인 중...',
  '영양 균형 계산 중...',
  '맛있는 레시피 생성 중...',
];

const kAiQuickQuestions = [
  '알러지 있는 강아지 레시피 추천해줘',
  '다이어트 식단 알려줘',
  '고양이 건강식 레시피',
  '강아지 간식 만들기',
];
