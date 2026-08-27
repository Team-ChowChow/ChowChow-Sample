import '../data/sample_data.dart';
import 'api_client.dart';

class CommunityService {
  const CommunityService._();

  static Future<List<CommunityPost>> getPosts({
    String? category,
    String? petType,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, String>{};
    if (category != null && category != '전체') {
      query['category'] = category;
    }
    if (petType != null) {
      query['petType'] = petType;
    }
    // 정렬 파라미터 추가 (예: 'likes,desc', 'createdAt,desc')
    if (sortBy != null) {
      query['sort'] = '$sortBy,${sortOrder ?? 'desc'}';
    }

    final res = await ApiClient.get(
      '/api/community/posts',
      query: query.isEmpty ? null : query,
    );
    final items = res is Map<String, dynamic> ? res['content'] : res;
    return (items as List<dynamic>)
        .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<CommunityPost> getPost(int postId) async {
    final res = await ApiClient.get('/api/community/posts/$postId');
    return CommunityPost.fromJson(res as Map<String, dynamic>);
  }

  static Future<List<CommunityPost>> getLikedPosts() async {
    try {
      final res = await ApiClient.get('/api/community/posts/liked');
      final items = res is Map<String, dynamic> ? res['content'] : res;
      return (items as List<dynamic>)
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 새 API가 아직 배포되지 않은 서버에서는 기존 목록의 likedByMe를 사용한다.
      final res = await ApiClient.get(
        '/api/community/posts',
        query: {'page': '0', 'size': '1000'},
      );
      final items = res is Map<String, dynamic> ? res['content'] : res;
      return (items as List<dynamic>)
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
          .where((post) => post.likedByMe)
          .toList();
    }
  }

  static Future<void> toggleLike(int postId) async {
    await ApiClient.post('/api/community/posts/$postId/like', {});
  }

  static Future<List<CommunityComment>> getComments(int postId) async {
    final res = await ApiClient.get('/api/community/posts/$postId/comments');
    return (res as List<dynamic>)
        .map((item) => CommunityComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<CommunityComment> createComment(
    int postId,
    String content,
  ) async {
    final res = await ApiClient.post(
      '/api/community/posts/$postId/comments',
      {
        'commentContent': content,
        'commentStatus': 'ACTIVE',
      },
    );
    return CommunityComment.fromJson(res as Map<String, dynamic>);
  }

  static Future<CommunityPost> createPost({
    required String content,
    String? category,
    int? petId,
    int? recipeId,
    List<String> tags = const [],
    String? imageUrl,
    String? title,
    String? petType,
  }) async {
    // 사용자가 제목을 입력했으면 그것을 사용, 아니면 자동 생성
    final finalTitle = title?.isNotEmpty == true
        ? title
        : (content.isEmpty
            ? ''
            : (content.split('\n').first.length > 50
                ? '${content.split('\n').first.substring(0, 50)}...'
                : content.split('\n').first));

    final res = await ApiClient.post('/api/community/posts', {
      'postTitle': finalTitle,
      'postContent': content,
      'postCategory': category ?? '자유',
      'postStatus': 'ACTIVE',
      if (petId != null) 'petId': petId,
      if (recipeId != null) 'recipeId': recipeId,
      if (imageUrl != null) 'postImageUrl': imageUrl,
      if (tags.isNotEmpty) 'tagNames': tags,
      if (petType != null) 'petType': petType,
    });
    return CommunityPost.fromJson(res as Map<String, dynamic>);
  }

  static Future<CommunityPost> updatePost({
    required int postId,
    required String content,
    String? category,
    String? petType,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    final lines = content.trim().split('\n');
    final title = lines.first.length > 50
        ? '${lines.first.substring(0, 50)}...'
        : lines.first;
    final res = await ApiClient.patch('/api/community/posts/$postId', {
      'postTitle': title,
      'postContent': content,
      'postCategory': category ?? '자유',
      if (petType != null) 'petType': petType,
      if (imageUrl != null) 'postImageUrl': imageUrl,
      if (tags.isNotEmpty) 'tagNames': tags,
    });
    return CommunityPost.fromJson(res as Map<String, dynamic>);
  }

  static Future<void> deletePost(int postId) async {
    await ApiClient.delete('/api/community/posts/$postId');
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    this.userId,
    this.parentCommentId,
    required this.author,
    required this.avatar,
    this.profileImageUrl,
    required this.timeAgo,
    required this.content,
    this.likes = 0,
    this.isMine = false,
  });

  final int id;
  final int postId;
  final int? userId;
  final int? parentCommentId;
  final String author;
  final String avatar;
  final String? profileImageUrl;
  final String timeAgo;
  final String content;
  final int likes;
  final bool isMine;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['commentId'] as int? ?? json['id'] as int? ?? 0,
      postId: json['postId'] as int? ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      parentCommentId: json['parentCommentId'] as int?,
      author: json['userNickname'] as String? ??
          json['author'] as String? ??
          '사용자 ${json['userId'] ?? ''}'.trim(),
      avatar: json['avatar'] as String? ?? '🙂',
      profileImageUrl: json['userProfileImg'] as String? ??
          json['profileImageUrl'] as String?,
      timeAgo: _timeAgo(json['createdAt'] as String?),
      content: json['commentContent'] as String? ??
          json['content'] as String? ??
          '',
      likes: (json['likeCount'] as num?)?.toInt() ??
          (json['likes'] as num?)?.toInt() ??
          0,
      isMine: json['isMine'] as bool? ?? false,
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
