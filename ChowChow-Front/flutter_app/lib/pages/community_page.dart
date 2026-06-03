import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';
import '../router/app_router.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with RouteAware {
  static const _categories = ['전체', '자유', '질문', '후기', '질환정보'];
  static const _petTypes = ['전체', '강아지', '고양이'];
  static const _sortOptions = [
    ('createdAt', 'desc', '최신순 ↓'),
    ('createdAt', 'asc', '최신순 ↑'),
    ('likes', 'desc', '인기순 ↓'),
    ('likes', 'asc', '인기순 ↑'),
  ];

  String _selectedCategory = '전체';
  String _selectedPetType = '전체';
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  String _searchKeyword = '';
  List<CommunityPost> _posts = kCommunityPosts;
  bool _isLoading = true;
  Set<int> _bookmarkedIds = {};
  int? _currentUserId;

  List<CommunityPost> get _filteredAndSortedPosts {
    var result = _posts;

    // 1. 카테고리 필터링
    if (_selectedCategory != '전체') {
      result = result.where((post) => post.category == _selectedCategory).toList();
    }

    // 2. 강아지/고양이 필터링
    if (_selectedPetType != '전체') {
      final petTypeValue = _selectedPetType == '강아지' ? 'DOG' : 'CAT';
      print('[Filter] ${_selectedPetType} 필터: 찾는 petType=$petTypeValue');
      final beforeCount = result.length;
      result = result.where((post) {
        print('[Filter] Post ${post.id}: petType=${post.petType}');
        return post.petType == petTypeValue;
      }).toList();
      print('[Filter] 필터 후: $beforeCount -> ${result.length}');
    }

    // 3. 검색 필터링 (태그명 또는 제목/내용)
    if (_searchKeyword.isNotEmpty) {
      final keyword = _searchKeyword.toLowerCase().trim();
      final cleanKeyword = keyword.replaceAll('#', '');

      result = result.where((post) {
        // 태그로 검색
        final matchesTag = post.tags.isNotEmpty && post.tags.any((tag) {
          final cleanTag = tag.toLowerCase().replaceAll('#', '');
          return cleanTag.contains(cleanKeyword);
        });

        // 제목 또는 내용으로도 검색
        final matchesTitle = post.title?.toLowerCase().contains(cleanKeyword) ?? false;
        final matchesContent = post.content.toLowerCase().contains(cleanKeyword);

        return matchesTag || matchesTitle || matchesContent;
      }).toList();
    }

    // 4. 정렬
    if (_sortBy == 'likes') {
      result.sort((a, b) => _sortOrder == 'desc'
          ? b.likes.compareTo(a.likes)
          : a.likes.compareTo(b.likes));
    } else if (_sortBy == 'createdAt') {
      // timeAgo는 상대 시간이므로 직접 비교 불가능
      // 백엔드에서 정렬된 순서를 받거나, 다른 필드 필요
      // 일단 백엔드에서 처리된다고 가정
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    print('[CommunityPage] initState - kCommunityPosts count: ${kCommunityPosts.length}');
    _loadPosts();
    _loadBookmarks();
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteObserver에 등록
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // RouteObserver에서 등록 해제
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 다른 페이지에서 돌아올 때 - 최신 데이터 로드
    _loadPosts();
  }

  @override
  void didPushNext() {
    // 새 페이지로 갈 때 - 특별한 처리 없음
  }

  Future<void> _loadCurrentUser() async {
    try {
      final res = await ApiClient.get('/api/users/me');
      final id = (res as Map<String, dynamic>)['userId'] as int?;
      if (!mounted) return;
      setState(() => _currentUserId = id);
    } catch (_) {}
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('bookmarkedPostIds') ?? [];
    if (!mounted) return;
    setState(() {
      _bookmarkedIds = ids.map(int.parse).toSet();
    });
  }

  Future<void> _toggleBookmark(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarkedIds.contains(postId)) {
        _bookmarkedIds.remove(postId);
      } else {
        _bookmarkedIds.add(postId);
      }
    });
    await prefs.setStringList(
      'bookmarkedPostIds',
      _bookmarkedIds.map((id) => id.toString()).toList(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_bookmarkedIds.contains(postId) ? '게시글을 저장했습니다.' : '저장을 취소했습니다.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      var posts = await CommunityService.getPosts(
        category: _selectedCategory != '전체' ? _selectedCategory : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      print('[CommunityPage] API returned ${posts.length} posts');

      // API가 데이터를 적게 반환하면, kCommunityPosts에서 추가로 가져오기
      if (posts.length < 5) {
        print('[CommunityPage] API data insufficient, adding kCommunityPosts');
        // 이미 있는 post ID를 제외하고 kCommunityPosts에서 추가
        final existingIds = posts.map((p) => p.id).toSet();
        final additional = kCommunityPosts
            .where((p) => !existingIds.contains(p.id))
            .take(24 - posts.length)
            .toList();
        posts = [...posts, ...additional];
        print('[CommunityPage] Total posts after adding: ${posts.length}');
      }

      // 백엔드가 tagNames를 응답에 포함하지 않으면,
      // SharedPreferences에서 저장된 tags를 복원
      final prefs = await SharedPreferences.getInstance();
      final postsWithTags = posts.map((post) {
        if (post.tags.isEmpty) {
          final savedTags = prefs.getStringList('post_${post.id}_tags');
          if (savedTags != null && savedTags.isNotEmpty) {
            return post.copyWith(tags: savedTags);
          }
        }
        return post;
      }).toList();

      if (!mounted) return;
      setState(() {
        _posts = postsWithTags;
        _isLoading = false;
      });
    } catch (e) {
      print('[CommunityPage] _loadPosts error: $e');
      if (!mounted) return;
      setState(() {
        print('[CommunityPage] Using kCommunityPosts: ${kCommunityPosts.length} posts');
        _posts = kCommunityPosts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredAndSortedPosts;

    return Stack(
      children: [
        ColoredBox(
          color: ChowColors.gray50,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '커뮤니티',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: ChowColors.gray800),
                    ),
                    const Text(
                      '반려동물 식단에 대한 이야기를 나눠보세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: ChowColors.gray500,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // 검색창
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchKeyword = value);
                    },
                    decoration: InputDecoration(
                      hintText: '태그 검색...',
                      hintStyle: const TextStyle(
                        color: ChowColors.gray400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: ChowColors.gray400, size: 20),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: ChowColors.gray400),
                              onPressed: () => setState(() => _searchKeyword = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: ChowColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              // 카테고리 필터
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories
                          .map(
                            (category) => _TabChip(
                              label: category,
                              selected: _selectedCategory == category,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              // 강아지/고양이 필터 + 정렬
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      // 강아지/고양이 필터
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _petTypes
                                .map(
                                  (petType) => _TabChip(
                                    label: petType,
                                    selected: _selectedPetType == petType,
                                    onTap: () {
                                      setState(() {
                                        _selectedPetType = petType;
                                      });
                                    },
                                    size: 'small',
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 정렬 드롭다운
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: ChowColors.gray200),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          value: '$_sortBy:$_sortOrder',
                          underline: const SizedBox(),
                          icon: const Icon(Icons.unfold_more, size: 18, color: ChowColors.gray600),
                          onChanged: (value) {
                            if (value == null) return;
                            final parts = value.split(':');
                            setState(() {
                              _sortBy = parts[0];
                              _sortOrder = parts[1];
                              _loadPosts();
                            });
                          },
                          items: _sortOptions
                              .map((option) => DropdownMenuItem(
                                    value: '${option.$1}:${option.$2}',
                                    child: Text(
                                      option.$3,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ChowColors.orange500,
                      ),
                    ),
                  ),
                )
              else if (posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        '게시글이 없습니다.',
                        style: TextStyle(color: ChowColors.gray500),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final post = posts[i];
                      return _PostCard(
                        key: ValueKey(post.id),
                        post: post,
                        currentUserId: _currentUserId,
                        isBookmarked: _bookmarkedIds.contains(post.id),
                        onBookmarkToggle: () => _toggleBookmark(post.id),
                        onDeleted: () => setState(
                          () => _posts.removeWhere((p) => p.id == post.id),
                        ),
                        onTagTap: (tag) {
                          // 태그에서 "#" 제거해서 검색
                          final searchTag = tag.replaceAll('#', '');
                          setState(() => _searchKeyword = searchTag);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 22,
          bottom: 100,
          child: Material(
            elevation: 6,
            color: ChowColors.orange500,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push<CommunityPost>('/create-post').then((result) {
                // tags가 포함된 post가 반환되면, _posts의 맨 앞에 추가
                if (result != null && mounted) {
                  setState(() {
                    _posts.insert(0, result);
                  });
                } else {
                  // post가 없으면 전체 새로고침
                  _loadPosts();
                }
              }),
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.size = 'default',
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String size; // 'default' or 'small'

  @override
  Widget build(BuildContext context) {
    final isSmall = size == 'small';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? ChowColors.orange500 : ChowColors.gray100,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 10 : 14,
              vertical: isSmall ? 4 : 8,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 11 : 13,
                color: selected ? Colors.white : ChowColors.gray600,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.isBookmarked = false,
    this.onBookmarkToggle,
    this.onDeleted,
    this.onTagTap,
  });

  final CommunityPost post;
  final int? currentUserId;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onDeleted;
  final Function(String)? onTagTap; // 태그 클릭 콜백

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late CommunityPost _post;
  late List<_SheetComment> _comments;
  bool _likeBusy = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _comments = const [];
  }

  @override
  void didUpdateWidget(_PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 부모에서 새로운 post 데이터가 오면 반영
    if (oldWidget.post.id != widget.post.id) {
      // 다른 post로 바뀜 - 전체 업데이트
      _post = widget.post;
    } else {
      // 같은 post - 서버 상태와 동기화
      // 낙관적 업데이트 중이 아니면 서버 상태를 반영
      if (!_likeBusy) {
        // 좋아요 진행 중이 아니면 서버 상태로 동기화
        if (oldWidget.post.likedByMe != widget.post.likedByMe ||
            oldWidget.post.likes != widget.post.likes) {
          _post = _post.copyWith(
            likedByMe: widget.post.likedByMe,
            likes: widget.post.likes,
          );
        }
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;

    final previous = _post;
    final newLikeState = !previous.likedByMe;

    // 낙관적 업데이트 (UI 즉시 반영)
    setState(() {
      _likeBusy = true;
      _post = previous.copyWith(
        likedByMe: newLikeState,
        likes: newLikeState
            ? previous.likes + 1
            : (previous.likes > 0 ? previous.likes - 1 : 0),
      );
    });

    try {
      await CommunityService.toggleLike(previous.id);
      // 서버에서 최신 post 데이터 다시 받기
      final updated = await CommunityService.getPost(previous.id);
      if (mounted) {
        setState(() => _post = updated);
      }
    } catch (e) {
      // 에러 발생 시 이전 상태로 롤백
      if (mounted) {
        setState(() => _post = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _handleEdit() async {
    final result = await context.push<CommunityPost>(
      '/create-post',
      extra: _post,
    );
    if (result != null && mounted) {
      setState(() => _post = result);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠습니까?\n삭제 후 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: ChowColors.red500),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await CommunityService.deletePost(_post.id);
      widget.onDeleted?.call();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다.')),
        );
      }
    }
  }

  void _addComment(_SheetComment comment) {
    setState(() {
      _comments.add(comment);
      _post = _post.copyWith(comments: _post.comments + 1);
    });
  }

  void _replaceComments(List<_SheetComment> comments) {
    setState(() {
      _comments = comments;
      _post = _post.copyWith(comments: comments.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 좋아요 상태는 로컬 상태에서, 다른 데이터는 최신 widget.post에서 가져옴
    final post = widget.post.copyWith(
      likedByMe: _post.likedByMe,
      likes: _post.likes,
    );
    final likeColor = post.likedByMe ? ChowColors.red500 : ChowColors.gray600;
    final commentCount = post.comments;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/community/posts/${post.id}', extra: post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ChowColors.orange100,
                    child: Text(post.avatar, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ChowColors.gray800,
                          ),
                        ),
                        Text(
                          post.timeAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ChowColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CategoryBadge(category: post.category),
                  _PostMenuButton(
                    isOwner: widget.currentUserId != null &&
                        post.userId == widget.currentUserId,
                    isBookmarked: widget.isBookmarked,
                    onBookmark: widget.onBookmarkToggle,
                    onEdit: _handleEdit,
                    onDelete: _handleDelete,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 표시
                  if (post.title != null && post.title!.isNotEmpty) ...[
                    Text(
                      post.title!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ChowColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    post.content,
                    style: const TextStyle(
                      color: ChowColors.gray700,
                      height: 1.4,
                    ),
                  ),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '태그',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ChowColors.gray600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: post.tags
                          .map(
                            (tag) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onTagTap?.call(tag),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ChowColors.orange50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: ChowColors.orange100,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ChowColors.orange600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ] else
                    const SizedBox(height: 0),
                ],
              ),
            ),
            if (post.image.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: ChowNetworkImage(url: post.image),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _toggleLike,
                    icon: Icon(
                      post.likedByMe ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: likeColor,
                    ),
                    label: Text(
                      '${post.likes}',
                      style: TextStyle(
                        color: likeColor,
                        fontWeight:
                            post.likedByMe ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showPostCommentsSheet(
                      context,
                      post.id,
                      _comments,
                      _replaceComments,
                      _addComment,
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: ChowColors.gray600,
                    ),
                    label: Text(
                      '$commentCount',
                      style: const TextStyle(color: ChowColors.gray600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showPostCommentsSheet(
  BuildContext context,
  int postId,
  List<_SheetComment> comments,
  ValueChanged<List<_SheetComment>> onCommentsLoaded,
  ValueChanged<_SheetComment> onCommentAdded,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: _PostCommentsSheet(
          postId: postId,
          comments: comments,
          onCommentsLoaded: onCommentsLoaded,
          onCommentAdded: onCommentAdded,
        ),
      ),
    ),
  );
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({
    required this.postId,
    required this.comments,
    required this.onCommentsLoaded,
    required this.onCommentAdded,
  });

  final int postId;
  final List<_SheetComment> comments;
  final ValueChanged<List<_SheetComment>> onCommentsLoaded;
  final ValueChanged<_SheetComment> onCommentAdded;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final _controller = TextEditingController();
  late final List<_SheetComment> _comments;
  bool _loading = true;

  List<_SheetCommentThreadData> get _commentThreads {
    final ids = _comments.map((comment) => comment.id).toSet();
    final parents = _comments
        .where((comment) =>
            comment.parentId == null || !ids.contains(comment.parentId))
        .toList();

    return parents.map((comment) {
      final replies = _comments
          .where((reply) => reply.parentId == comment.id)
          .toList();
      return _SheetCommentThreadData(comment: comment, replies: replies);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _comments = List<_SheetComment>.of(widget.comments);
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await CommunityService.getComments(widget.postId);
      final sheetComments = comments.map(_SheetComment.fromCommunity).toList();
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(sheetComments);
        _loading = false;
      });
      widget.onCommentsLoaded(sheetComments);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_comments.isEmpty) {
          _comments.addAll(_sampleSheetComments);
        }
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    late final _SheetComment comment;
    try {
      final created = await CommunityService.createComment(widget.postId, text);
      comment = _SheetComment.fromCommunity(created);
    } catch (_) {
      comment = _SheetComment(
        id: DateTime.now().millisecondsSinceEpoch,
        author: '나',
        avatar: '🙂',
        timeAgo: '방금',
        content: text,
        likes: 0,
      );
    }

    setState(() {
      _comments.add(comment);
    });
    widget.onCommentAdded(comment);
  }

  @override
  Widget build(BuildContext context) {
    final threads = _commentThreads;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: ChowColors.gray300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '댓글',
              style: TextStyle(
                color: ChowColors.gray900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: ChowColors.gray100),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ChowColors.orange500,
                      ),
                    )
                  : threads.isEmpty
                      ? const _EmptyComments()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          itemCount: threads.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            return _SheetCommentThread(
                              thread: threads[index],
                            );
                          },
                        ),
            ),
            _SheetCommentInput(
              controller: _controller,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '아직 댓글이 없습니다',
            style: TextStyle(
              color: ChowColors.gray900,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '댓글을 남겨보세요.',
            style: TextStyle(
              color: ChowColors.gray500,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCommentThread extends StatelessWidget {
  const _SheetCommentThread({required this.thread});

  final _SheetCommentThreadData thread;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetCommentTile(comment: thread.comment),
        ...thread.replies.map(
          (reply) => ColoredBox(
            color: ChowColors.gray50,
            child: Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _SheetCommentTile(comment: reply, compact: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetCommentTile extends StatelessWidget {
  const _SheetCommentTile({
    required this.comment,
    this.compact = false,
  });

  final _SheetComment comment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 0, 12, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: compact ? 16 : 18,
            backgroundColor: compact ? ChowColors.gray200 : ChowColors.orange50,
            child: Text(comment.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        color: ChowColors.gray900,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        color: ChowColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: ChowColors.gray700,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 15,
                      color: ChowColors.gray500,
                    ),
                    if (comment.likes > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likes}',
                        style: const TextStyle(
                          color: ChowColors.gray500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (!compact) ...[
                      const SizedBox(width: 16),
                      const Text(
                        '답글',
                        style: TextStyle(
                          color: ChowColors.gray500,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCommentInput extends StatefulWidget {
  const _SheetCommentInput({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final Future<void> Function() onSubmit;

  @override
  State<_SheetCommentInput> createState() => _SheetCommentInputState();
}

class _SheetCommentInputState extends State<_SheetCommentInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final enabled = widget.controller.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ChowColors.gray100)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                widget.onSubmit();
              },
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                hintStyle: const TextStyle(color: ChowColors.gray500),
                filled: true,
                fillColor: ChowColors.gray50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: ChowColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: ChowColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: ChowColors.orange400),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: enabled ? ChowColors.orange500 : ChowColors.gray300,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? () => widget.onSubmit() : null,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetComment {
  const _SheetComment({
    required this.id,
    this.parentId,
    required this.author,
    required this.avatar,
    required this.timeAgo,
    required this.content,
    required this.likes,
  });

  final int id;
  final int? parentId;
  final String author;
  final String avatar;
  final String timeAgo;
  final String content;
  final int likes;

  factory _SheetComment.fromCommunity(CommunityComment comment) {
    return _SheetComment(
      id: comment.id,
      parentId: comment.parentCommentId,
      author: comment.author,
      avatar: comment.avatar,
      timeAgo: comment.timeAgo,
      content: comment.content,
      likes: comment.likes,
    );
  }
}

const _sampleSheetComments = [
  _SheetComment(
    id: 1,
    author: '나비아빠',
    avatar: '🐕',
    timeAgo: '1시간 전',
    content: '사진만 봐도 정말 맛있어 보여요! 저희 강아지도 시도해볼게요.',
    likes: 5,
  ),
  _SheetComment(
    id: 2,
    author: '코코엄마',
    avatar: '🐶',
    timeAgo: '30분 전',
    content: '닭가슴살은 어디서 구매하셨나요? 추천 부탁드려요!',
    likes: 2,
  ),
  _SheetComment(
    id: 3,
    parentId: 2,
    author: '멍멍이엄마',
    avatar: '🐕',
    timeAgo: '20분 전',
    content: '동네 마트 무항생제 닭가슴살 사용했어요. 가격도 괜찮더라고요.',
    likes: 3,
  ),
  _SheetComment(
    id: 4,
    author: '보리집사',
    avatar: '🐱',
    timeAgo: '10분 전',
    content: '레시피 링크 공유 가능할까요? 저도 만들어보고 싶네요.',
    likes: 1,
  ),
];

class _SheetCommentThreadData {
  const _SheetCommentThreadData({
    required this.comment,
    required this.replies,
  });

  final _SheetComment comment;
  final List<_SheetComment> replies;
}

enum _PostMenuAction { save, share, edit, delete }

class _PostMenuButton extends StatelessWidget {
  const _PostMenuButton({
    required this.isOwner,
    this.isBookmarked = false,
    this.onBookmark,
    this.onEdit,
    this.onDelete,
  });

  final bool isOwner;
  final bool isBookmarked;
  final VoidCallback? onBookmark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PostMenuAction>(
      tooltip: '게시글 메뉴',
      icon: const Icon(Icons.more_horiz, color: ChowColors.gray400),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _PostMenuAction.save,
          child: _PostMenuItem(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: isBookmarked ? '저장 취소' : '저장하기',
            color: isBookmarked ? ChowColors.orange500 : ChowColors.gray800,
          ),
        ),
        const PopupMenuItem(
          value: _PostMenuAction.share,
          child: _PostMenuItem(icon: Icons.ios_share, label: '공유하기'),
        ),
        if (isOwner)
          const PopupMenuItem(
            value: _PostMenuAction.edit,
            child: _PostMenuItem(icon: Icons.edit_outlined, label: '수정하기'),
          ),
        if (isOwner)
          const PopupMenuItem(
            value: _PostMenuAction.delete,
            child: _PostMenuItem(
              icon: Icons.delete_outline,
              label: '삭제하기',
              color: ChowColors.red500,
            ),
          ),
      ],
      onSelected: (action) {
        switch (action) {
          case _PostMenuAction.save:
            onBookmark?.call();
          case _PostMenuAction.edit:
            onEdit?.call();
          case _PostMenuAction.delete:
            onDelete?.call();
          case _PostMenuAction.share:
            break;
        }
      },
    );
  }
}

class _PostMenuItem extends StatelessWidget {
  const _PostMenuItem({
    required this.icon,
    required this.label,
    this.color = ChowColors.gray800,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ChowColors.orange50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: ChowColors.orange600,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
