import '../data/sample_data.dart';
import 'api_client.dart';

class CommunityService {
  const CommunityService._();

  static Future<List<CommunityPost>> getPosts({String? category}) async {
    final query = <String, String>{};
    if (category != null && category != '전체') {
      query['category'] = category;
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
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    final lines = content.trim().split('\n');
    final title = lines.first.length > 50
        ? '${lines.first.substring(0, 50)}...'
        : lines.first;
    final res = await ApiClient.post('/api/community/posts', {
      'postTitle': title,
      'postContent': content,
      'postCategory': category ?? '기타',
      'postStatus': 'ACTIVE',
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
    this.parentCommentId,
    required this.author,
    required this.avatar,
    required this.timeAgo,
    required this.content,
    this.likes = 0,
    this.isMine = false,
  });

  final int id;
  final int postId;
  final int? parentCommentId;
  final String author;
  final String avatar;
  final String timeAgo;
  final String content;
  final int likes;
  final bool isMine;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['commentId'] as int? ?? json['id'] as int? ?? 0,
      postId: json['postId'] as int? ?? 0,
      parentCommentId: json['parentCommentId'] as int?,
      author: json['userNickname'] as String? ??
          json['author'] as String? ??
          '사용자 ${json['userId'] ?? ''}'.trim(),
      avatar: json['avatar'] as String? ?? '🙂',
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
