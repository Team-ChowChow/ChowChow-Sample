class CommunityPost {
  const CommunityPost({
    required this.id,
    this.userId,
    required this.author,
    required this.avatar,
    this.profileImageUrl,
    required this.category,
    required this.timeAgo,
    required this.content,
    required this.image,
    required this.likes,
    required this.comments,
    required this.views,
    required this.tags,
    this.title,
    this.recipeId,
    this.petType,
    this.likedByMe = false,
    this.bookmarkedByMe = false,
  });
  final int id;
  final int? userId; // 서버에서 받은 게시글 작성자 ID
  final String author;
  final String avatar;
  final String? profileImageUrl;
  final String category;
  final String timeAgo;
  final String content;
  final String image;
  final int likes;
  final int comments;
  final int views;
  final List<String> tags;
  final int? recipeId;
  final String? title; // 게시글 제목
  final String? petType; // 'DOG' 또는 'CAT'
  final bool likedByMe;
  final bool bookmarkedByMe;

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
      profileImageUrl: json['userProfileImg'] as String? ??
          json['profileImageUrl'] as String?,
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
      recipeId: json['recipeId'] as int?,
      petType: json['petType'] as String?,
      likedByMe: json['likedByMe'] as bool? ?? false,
      bookmarkedByMe: json['bookmarkedByMe'] as bool? ?? false,
    );
  }

  CommunityPost copyWith({
    int? likes,
    int? comments,
    bool? likedByMe,
    bool? bookmarkedByMe,
    String? title,
    int? recipeId,
    String? petType,
    List<String>? tags,
    String? profileImageUrl,
  }) {
    return CommunityPost(
      id: id,
      userId: userId,
      author: author,
      avatar: avatar,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      category: category,
      timeAgo: timeAgo,
      content: content,
      image: image,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views,
      tags: tags ?? this.tags,
      title: title ?? this.title,
      recipeId: recipeId ?? this.recipeId,
      petType: petType ?? this.petType,
      likedByMe: likedByMe ?? this.likedByMe,
      bookmarkedByMe: bookmarkedByMe ?? this.bookmarkedByMe,
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

const kAiQuickQuestions = [
  '알러지 있는 강아지 레시피 추천해줘',
  '다이어트 식단 알려줘',
  '고양이 건강식 레시피',
  '강아지 간식 만들기',
];
