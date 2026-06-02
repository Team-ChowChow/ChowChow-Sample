import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../theme/chow_theme.dart';

enum MyPostsMode { myPosts, savedPosts }

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key, required this.mode});
  final MyPostsMode mode;

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  List<CommunityPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.mode == MyPostsMode.myPosts) {
        await _loadMyPosts();
      } else {
        await _loadSavedPosts();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMyPosts() async {
    final res = await ApiClient.get('/api/community/posts/my');
    final items = (res is Map && res['content'] != null)
        ? res['content'] as List<dynamic>
        : res is List
            ? res as List<dynamic>
            : <dynamic>[];
    if (mounted) {
      setState(() {
        _posts = items
            .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _loadSavedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('bookmarkedPostIds') ?? [];
    if (ids.isEmpty) {
      if (mounted) setState(() => _posts = []);
      return;
    }
    final results = await Future.wait(
      ids.map((id) async {
        try {
          final res = await ApiClient.get('/api/community/posts/$id');
          return CommunityPost.fromJson(res as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }),
    );
    if (mounted) {
      setState(() {
        _posts = results.whereType<CommunityPost>().toList();
      });
    }
  }

  String get _title =>
      widget.mode == MyPostsMode.myPosts ? '내가 작성한 글' : '저장한 글';

  String get _emptyMessage =>
      widget.mode == MyPostsMode.myPosts ? '작성한 글이 없습니다.' : '저장한 글이 없습니다.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: ChowColors.gray400),
                      const SizedBox(height: 12),
                      const Text('불러오는 중 오류가 발생했습니다.', style: TextStyle(color: ChowColors.gray500)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: ChowColors.orange500),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.mode == MyPostsMode.myPosts
                                ? Icons.edit_note
                                : Icons.bookmark_border,
                            size: 56,
                            color: ChowColors.gray300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _emptyMessage,
                            style: const TextStyle(color: ChowColors.gray500, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: ChowColors.orange500,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        itemCount: _posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return _PostListItem(
                            post: post,
                            onTap: () {
                              context
                                  .push('/community/posts/${post.id}', extra: post)
                                  .then((_) => _load());
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _PostListItem extends StatelessWidget {
  const _PostListItem({required this.post, required this.onTap});
  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 + 날짜
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ChowColors.orange100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ChowColors.orange500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    post.timeAgo,
                    style: const TextStyle(fontSize: 12, color: ChowColors.gray400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 제목 역할 (첫 줄)
              Text(
                post.content.split('\n').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              if (post.content.split('\n').length > 1 ||
                  post.content.length > 60) ...[
                const SizedBox(height: 4),
                Text(
                  post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ChowColors.gray500,
                    height: 1.4,
                  ),
                ),
              ],
              // 이미지 썸네일
              if (post.image.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    post.image,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // 좋아요·댓글 카운트
              Row(
                children: [
                  const Icon(Icons.favorite_border, size: 14, color: ChowColors.gray400),
                  const SizedBox(width: 3),
                  Text(
                    '${post.likes}',
                    style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chat_bubble_outline, size: 14, color: ChowColors.gray400),
                  const SizedBox(width: 3),
                  Text(
                    '${post.comments}',
                    style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
