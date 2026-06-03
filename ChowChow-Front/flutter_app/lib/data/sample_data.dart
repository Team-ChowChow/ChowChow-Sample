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
    this.userId,
    required this.author,
    required this.avatar,
    required this.category,
    required this.timeAgo,
    required this.content,
    required this.image,
    required this.likes,
    required this.comments,
    required this.views,
    required this.tags,
    this.title,
    this.petType,
    this.likedByMe = false,
  });
  final int id;
  final int? userId; // 서버에서 받은 게시글 작성자 ID
  final String author;
  final String avatar;
  final String category;
  final String timeAgo;
  final String content;
  final String image;
  final int likes;
  final int comments;
  final int views;
  final List<String> tags;
  final String? title; // 게시글 제목
  final String? petType; // 'DOG' 또는 'CAT'
  final bool likedByMe;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // 태그 파싱 (tagNames 또는 tags 필드 모두 지원)
    List<String> parsedTags = [];
    final tagNames = json['tagNames'];
    final tags = json['tags'];

    if (tagNames is List) {
      parsedTags = tagNames
          .whereType<String>()
          .map((tag) => tag.startsWith('#') ? tag : '#$tag')
          .toList();
    } else if (tags is List) {
      parsedTags = tags
          .whereType<String>()
          .map((tag) => tag.startsWith('#') ? tag : '#$tag')
          .toList();
    }

    return CommunityPost(
      id: json['postId'] as int? ?? json['id'] as int? ?? 0,
      userId: json['userId'] as int?,
      author: json['userNickname'] as String? ??
          json['author'] as String? ??
          '사용자 ${json['userId'] ?? ''}'.trim(),
      avatar: json['avatar'] as String? ?? '🙂',
      category: json['postCategory'] as String? ?? json['category'] as String? ?? '기타',
      timeAgo: _timeAgo(json['createdAt'] as String?),
      content: json['postContent'] as String? ??
          json['postContentPreview'] as String? ??
          json['content'] as String? ??
          '',
      image: json['postImageUrl'] as String? ?? json['image'] as String? ?? '',
      likes: (json['likeCount'] as num?)?.toInt() ??
          (json['likes'] as num?)?.toInt() ??
          0,
      comments: (json['commentCount'] as num?)?.toInt() ??
          (json['commentSize'] as num?)?.toInt() ??
          (json['comments'] as num?)?.toInt() ??
          0,
      views: (json['viewCount'] as num?)?.toInt() ??
          (json['views'] as num?)?.toInt() ??
          0,
      tags: parsedTags,
      title: json['postTitle'] as String?,
      petType: json['petType'] as String?,
      likedByMe: json['likedByMe'] as bool? ?? false,
    );
  }

  CommunityPost copyWith({
    int? likes,
    int? comments,
    bool? likedByMe,
    String? title,
    String? petType,
    List<String>? tags,
  }) {
    return CommunityPost(
      id: id,
      userId: userId,
      author: author,
      avatar: avatar,
      category: category,
      timeAgo: timeAgo,
      content: content,
      image: image,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views,
      tags: tags ?? this.tags,
      title: title ?? this.title,
      petType: petType ?? this.petType,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

String _timeAgo(String? value) {
  if (value == null || value.isEmpty) return '방금';
  final createdAt = DateTime.tryParse(value);
  if (createdAt == null) return '방금';
  final diff = DateTime.now().difference(createdAt.toLocal());
  if (diff.inMinutes < 1) return '방금';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
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
    category: '후기',
    author: '멍멍이엄마',
    avatar: '🐕',
    timeAgo: '2시간 전',
    content:
        '오늘 초코한테 닭가슴살 야채 볶음 만들어줬어요! 너무 잘 먹네요 😊',
    image:
        'https://images.unsplash.com/photo-1760445528367-7f0fa0229d19?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBlYXRpbmclMjBoZWFsdGh5JTIwbWVhbHxlbnwxfHx8fDE3NzE0MjIwOTh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    likes: 42,
    comments: 4,
    views: 156,
    tags: ['#닭가슴살', '#야채볶음'],
  ),
  CommunityPost(
    id: 2,
    category: '레시피',
    author: '냥이집사',
    avatar: '🐱',
    timeAgo: '5시간 전',
    content:
        '연어 고구마 믹스 레시피 따라해봤는데 대박입니다! 우리 나비가 평소에 밥을 안 먹는 편인데 이건 진짜 순식간에 다 먹었어요 ㅋㅋㅋ',
    image:
        'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXQlMjBmb29kJTIwaW5ncmVkaWVudHMlMjB2ZWdldGFibGVzfGVufDF8fHx8MTc3MTQyMjA5OXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    likes: 67,
    comments: 4,
    views: 234,
    tags: ['#연어', '#고구마', '#강추'],
  ),
  CommunityPost(
    id: 3,
    category: '질환정보',
    author: '펫푸드마스터',
    avatar: '👨‍🍳',
    timeAgo: '1일 전',
    content:
        '소고기 채소 스튜 만드는 팁 공유할게요! 소고기는 꼭 살짝 데쳐서 기름을 빼주세요. 반려동물 소화에 훨씬 좋답니다 👍',
    image:
        'https://images.unsplash.com/photo-1769947322352-dd6cbdc4ec2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXQlMjBlYXRpbmclMjBmb29kfGVufDF8fHx8MTc3MTM2MDQzMHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    likes: 89,
    comments: 4,
    views: 412,
    tags: ['#소고기', '#채소스튜', '#팁'],
  ),
  CommunityPost(
    id: 4,
    category: '기타',
    author: '초코아빠',
    avatar: '🐾',
    timeAgo: '2일 전',
    content: '요즘 산책 후에 먹이기 좋은 간단한 간식 보관법도 공유해요. 다들 어떤 방식으로 보관하시나요?',
    image:
        'https://images.unsplash.com/photo-1601758125946-6ec2ef64daf8?auto=format&fit=crop&w=1080&q=80',
    likes: 21,
    comments: 4,
    views: 98,
    tags: ['#간식', '#보관법', '#잡담'],
  ),
  CommunityPost(id: 5, category: '자유', author: '펫사랑이', avatar: '🐶', timeAgo: '30분 전', content: '우리 강아지 식단 추천해줄 분 있나요? 요즘 밥을 잘 안 먹어요 ㅠㅠ', image: '', likes: 12, comments: 8, views: 45, tags: ['#식단', '#상담', '#강아지']),
  CommunityPost(id: 6, category: '후기', author: '냥냥이엄마', avatar: '🐱', timeAgo: '1시간 전', content: '새로운 고양이 사료로 바꿨는데 반응이 정말 좋네요! 추천합니다 😍', image: '', likes: 34, comments: 5, views: 112, tags: ['#고양이', '#사료', '#강추']),
  CommunityPost(id: 7, category: '질문', author: '건강걱정', avatar: '👩', timeAgo: '2시간 전', content: '반려동물이 소화를 잘 못 하는 것 같은데 어떤 음식이 좋을까요?', image: '', likes: 8, comments: 6, views: 67, tags: ['#건강', '#소화', '#질문']),
  CommunityPost(id: 8, category: '레시피', author: '요리왕', avatar: '👨‍🍳', timeAgo: '3시간 전', content: '간단한 두부 계란 덮밥 레시피! 우리 애들이 정말 좋아해요 🍚', image: '', likes: 56, comments: 9, views: 203, tags: ['#레시피', '#두부', '#계란']),
  CommunityPost(id: 9, category: '질환정보', author: '의료정보', avatar: '⚕️', timeAgo: '4시간 전', content: '반려동물 비만 예방법과 관리 방법을 알려드립니다. 운동과 식단이 중요합니다!', image: '', likes: 42, comments: 7, views: 156, tags: ['#비만예방', '#건강', '#정보']),
  CommunityPost(id: 10, category: '자유', author: '경험자', avatar: '🐕', timeAgo: '5시간 전', content: '강아지 식사 시간을 일정하게 유지하니까 소화가 훨씬 좋아졌어요!', image: '', likes: 28, comments: 4, views: 89, tags: ['#팁', '#일상', '#경험']),
  CommunityPost(id: 11, category: '후기', author: '행복한집사', avatar: '🐱', timeAgo: '6시간 전', content: '이번 달에 먹인 새 사료, 정말 추천해요! 질도 좋고 가격도 합리적 👍', image: '', likes: 19, comments: 3, views: 76, tags: ['#사료', '#후기', '#추천']),
  CommunityPost(id: 12, category: '질문', author: '초보집사', avatar: '👨', timeAgo: '7시간 전', content: '반려동물 식이알레르기 있는데 뭘 먹여야 하나요? 도와주세요 ㅠ', image: '', likes: 5, comments: 11, views: 134, tags: ['#알레르기', '#도움', '#질문']),
  CommunityPost(id: 13, category: '레시피', author: '셰프강아지', avatar: '👨‍🍳', timeAgo: '8시간 전', content: '호박죽 만드는 법! 건강하고 맛있어요 🎃', image: '', likes: 67, comments: 12, views: 267, tags: ['#호박', '#죽', '#레시피']),
  CommunityPost(id: 14, category: '질환정보', author: '닥터펫', avatar: '⚕️', timeAgo: '9시간 전', content: '반려동물 영양 균형 잡는 방법 - 단백질, 지방, 탄수화물의 비율을 맞춰보세요', image: '', likes: 53, comments: 8, views: 198, tags: ['#영양', '#정보', '#건강']),
  CommunityPost(id: 15, category: '자유', author: '일상공유', avatar: '🐶', timeAgo: '10시간 전', content: '우리 강아지 밥 먹는 모습이 너무 귀여워서 올려봅니다 😂', image: '', likes: 89, comments: 15, views: 345, tags: ['#귀여움', '#일상', '#공유']),
  CommunityPost(id: 16, category: '후기', author: '만족고객', avatar: '🐱', timeAgo: '11시간 전', content: '유기농 사료로 바꿨더니 우리 고양이 모질이 더 부드러워졌어요!', image: '', likes: 41, comments: 6, views: 145, tags: ['#유기농', '#사료', '#후기']),
  CommunityPost(id: 17, category: '질문', author: '식단고민', avatar: '👩', timeAgo: '12시간 전', content: '간헐적 단식이 반려동물에게도 좋을까요?', image: '', likes: 7, comments: 9, views: 112, tags: ['#단식', '#식단', '#질문']),
  CommunityPost(id: 18, category: '레시피', author: '쿠킹마스터', avatar: '👨‍🍳', timeAgo: '13시간 전', content: '소고기 미역국 만드는 방법 - 보양식으로 좋아요!', image: '', likes: 73, comments: 11, views: 289, tags: ['#소고기', '#미역국', '#보양']),
  CommunityPost(id: 19, category: '질환정보', author: '수의사', avatar: '⚕️', timeAgo: '14시간 전', content: '반려동물 비타민 B 결핍증 증상과 대처 방법을 알아봅시다', image: '', likes: 38, comments: 5, views: 167, tags: ['#비타민', '#질환', '#건강']),
  CommunityPost(id: 20, category: '자유', author: '행복기록', avatar: '🐕', timeAgo: '15시간 전', content: '우리 강아지 생일이라 특별한 케이크를 만들어줬어요 🎂', image: '', likes: 112, comments: 18, views: 456, tags: ['#생일', '#축하', '#케이크']),
  CommunityPost(id: 21, category: '후기', author: '믿을만한', avatar: '🐱', timeAgo: '16시간 전', content: '이 사료 진짜 강추! 내 고양이가 처음으로 맛있게 먹었어요', image: '', likes: 55, comments: 8, views: 198, tags: ['#사료', '#강추', '#만족']),
  CommunityPost(id: 22, category: '질문', author: '고민많아', avatar: '👨', timeAgo: '17시간 전', content: '반려동물이 너무 빨리 먹는데 천천히 먹게 하는 법이 있나요?', image: '', likes: 14, comments: 13, views: 178, tags: ['#식습관', '#도움', '#질문']),
  CommunityPost(id: 23, category: '레시피', author: '건강요리', avatar: '👨‍🍳', timeAgo: '18시간 전', content: '닭 가슴살 야채밥 - 다이어트에 최고예요!', image: '', likes: 68, comments: 10, views: 245, tags: ['#다이어트', '#닭가슴살', '#야채']),
  CommunityPost(id: 24, category: '질환정보', author: '전문가', avatar: '⚕️', timeAgo: '19시간 전', content: '반려동물 저혈당증 예방을 위한 올바른 식사 간격', image: '', likes: 31, comments: 4, views: 124, tags: ['#저혈당', '#예방', '#건강']),
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
