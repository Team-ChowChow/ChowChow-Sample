import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';

enum MyPostsMode { myPosts, savedPosts, likedPosts, savedRecipes }

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key, required this.mode});
  final MyPostsMode mode;

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  List<CommunityPost> _posts = [];
  List<RecipeModel> _savedRecipes = [];
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
      switch (widget.mode) {
        case MyPostsMode.myPosts:
          await _loadMyPosts();
        case MyPostsMode.savedPosts:
          await _loadSavedPosts();
        case MyPostsMode.likedPosts:
          await _loadLikedPosts();
        case MyPostsMode.savedRecipes:
          await _loadSavedRecipes();
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
            ? res
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
    // 커뮤니티 저장 글 (로컬)
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('bookmarkedPostIds') ?? [];
    final postResults = await Future.wait(
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
        _posts = postResults.whereType<CommunityPost>().toList();
        _savedRecipes = [];
      });
    }
  }

  Future<void> _loadSavedRecipes() async {
    final recipes = await _fetchSavedRecipes();
    if (!mounted) return;
    setState(() => _savedRecipes = recipes);
  }

  Future<void> _loadLikedPosts() async {
    final posts = await CommunityService.getLikedPosts();
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _savedRecipes = [];
    });
  }

  Future<List<RecipeModel>> _fetchSavedRecipes() async {
    final res = await ApiClient.get('/api/v1/recipes/me/bookmarks')
        as Map<String, dynamic>;
    final list = res['bookmarks'] as List<dynamic>? ?? [];
    return list
        .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String get _title => switch (widget.mode) {
        MyPostsMode.myPosts => '내가 작성한 글',
        MyPostsMode.savedPosts => '저장한 글',
        MyPostsMode.likedPosts => '좋아한 글',
        MyPostsMode.savedRecipes => '저장한 레시피',
      };

  String get _emptyMessage => switch (widget.mode) {
        MyPostsMode.myPosts => '작성한 글이 없습니다.',
        MyPostsMode.savedPosts => '저장한 글이 없습니다.',
        MyPostsMode.likedPosts => '좋아한 글이 없습니다.',
        MyPostsMode.savedRecipes => '저장한 레시피가 없습니다.',
      };

  bool get _isEmpty => switch (widget.mode) {
        MyPostsMode.myPosts => _posts.isEmpty,
        MyPostsMode.savedPosts => _posts.isEmpty,
        MyPostsMode.likedPosts => _posts.isEmpty,
        MyPostsMode.savedRecipes => _savedRecipes.isEmpty,
      };

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
            fontWeight: FontWeight.w500,
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
                        style: ElevatedButton.styleFrom(backgroundColor: ChowCozy.stone500),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            switch (widget.mode) {
                              MyPostsMode.myPosts => Icons.edit_note,
                              MyPostsMode.likedPosts => Icons.favorite_border,
                              _ => Icons.bookmark_border,
                            },
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
                      color: ChowCozy.stone500,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        children: [
                          // 저장한 레시피 화면에서만 레시피 목록 표시
                          if (widget.mode == MyPostsMode.savedRecipes &&
                              _savedRecipes.isNotEmpty) ...[
                            ..._savedRecipes.map((recipe) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecipeListItem(
                                recipe: recipe,
                                onTap: () => context.push('/recipes/${recipe.recipeId}').then((_) => _load()),
                              ),
                            )),
                          ],
                          if (widget.mode != MyPostsMode.savedRecipes)
                            ..._posts.map((post) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _PostListItem(
                                    post: post,
                                    onTap: () => context
                                        .push('/community/posts/${post.id}', extra: post)
                                        .then((_) => _load()),
                                  ),
                                )),
                        ],
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
                      color: ChowCozy.stone300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: ChowCozy.stone500,
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
                  fontWeight: FontWeight.w500,
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
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
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

class _RecipeListItem extends StatelessWidget {
  const _RecipeListItem({required this.recipe, required this.onTap});

  final RecipeModel recipe;
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
          child: Row(
            children: [
              if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    recipe.imageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(width: 72, height: 72),
                  ),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: ChowCozy.stone100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant, color: ChowCozy.stone300, size: 32),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recipe.menuName != null)
                      Text(
                        recipe.menuName!,
                        style: const TextStyle(fontSize: 11, color: ChowCozy.stone500, fontWeight: FontWeight.w500),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      recipe.recipeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.bookmark_rounded, size: 13, color: ChowCozy.stone500),
                        const SizedBox(width: 3),
                        const Text('저장됨', style: TextStyle(fontSize: 12, color: ChowColors.gray500)),
                        const SizedBox(width: 10),
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 3),
                        Text(recipe.averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ChowColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
