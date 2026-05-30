import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/sample_data.dart';
import '../services/community_service.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const _categories = ['전체', '레시피', '질문', '후기', '정보공유', '기타'];

  String _selectedCategory = '전체';
  List<CommunityPost> _posts = kCommunityPosts;
  bool _isLoading = true;

  List<CommunityPost> get _filteredPosts {
    if (_selectedCategory == '전체') return _posts;

    return _posts
        .where((post) => _normalizeCategory(post.category) == _selectedCategory)
        .toList();
  }

  String _normalizeCategory(String category) {
    if (_categories.contains(category) && category != '전체') {
      return category;
    }
    return '기타';
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await CommunityService.getPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posts = kCommunityPosts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;

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
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: ChowColors.orange500,
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '인기 토픽',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ChowColors.gray800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: kTrendingTopics.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final topic = kTrendingTopics[i];
                            return Material(
                              color: ChowColors.orange50,
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: topic.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: ChowColors.orange600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' (${topic.count})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: ChowColors.orange500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                    itemBuilder: (context, i) => _PostCard(post: posts[i]),
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
              onTap: () => context.push('/create-post'),
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? ChowColors.orange500 : ChowColors.gray100,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
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
  const _PostCard({required this.post});

  final CommunityPost post;

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

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    final previous = _post;
    final liked = !previous.likedByMe;
    setState(() {
      _likeBusy = true;
      _post = previous.copyWith(
        likedByMe: liked,
        likes: liked
            ? previous.likes + 1
            : (previous.likes > 0 ? previous.likes - 1 : 0),
      );
    });

    try {
      await CommunityService.toggleLike(previous.id);
      final freshPost = await CommunityService.getPost(previous.id);
      if (!mounted) return;
      setState(() => _post = freshPost);
    } catch (_) {
      if (!mounted) return;
      setState(() => _post = previous);
    } finally {
      if (mounted) {
        setState(() => _likeBusy = false);
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
    final post = _post;
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
                  _PostMenuButton(isOwner: isCurrentUserPost(post)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    style: const TextStyle(
                      color: ChowColors.gray700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: post.tags
                        .map(
                          (tag) => Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ChowColors.orange500,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
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
  const _PostMenuButton({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PostMenuAction>(
      tooltip: '게시글 메뉴',
      icon: const Icon(Icons.more_horiz, color: ChowColors.gray400),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PostMenuAction.save,
          child: _PostMenuItem(icon: Icons.bookmark_border, label: '저장하기'),
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
      onSelected: (_) {},
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
