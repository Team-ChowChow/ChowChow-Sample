import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/sample_data.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
  });

  final int postId;
  final CommunityPost? initialPost;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  late final CommunityPost _post;
  late List<_PostComment> _comments;
  late int _commentCount;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost ??
        kCommunityPosts.firstWhere(
          (post) => post.id == widget.postId,
          orElse: () => kCommunityPosts.first,
    );
    _comments = _initialComments();
    _commentCount = _countComments(_comments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/community');
  }

  void _toggleCommentLike(int id) {
    setState(() {
      _comments = _comments.map((comment) {
        if (comment.id == id) return comment.toggledLike();
        return comment.copyWith(
          replies: comment.replies
              .map((reply) => reply.id == id ? reply.toggledLike() : reply)
              .toList(),
        );
      }).toList();
    });
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.add(
        _PostComment(
          id: DateTime.now().millisecondsSinceEpoch,
          author: '나',
          avatar: '🙂',
          timeAgo: '방금',
          content: text,
          likes: 0,
        ),
      );
      _commentCount++;
      _commentController.clear();
    });
  }

  int _countComments(List<_PostComment> comments) {
    return comments.fold<int>(
      0,
      (total, comment) => total + 1 + _countComments(comment.replies),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(onBack: _goBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 18),
                children: [
                  _PostContentSection(
                    post: _post,
                    isLiked: _isLiked,
                    likes: _isLiked ? _post.likes + 1 : _post.likes,
                    commentCount: _commentCount,
                    onToggleLike: () => setState(() => _isLiked = !_isLiked),
                  ),
                  _CommentsSection(
                    comments: _comments,
                    commentCount: _commentCount,
                    onToggleLike: _toggleCommentLike,
                  ),
                ],
              ),
            ),
            _CommentInputBar(
              controller: _commentController,
              onSubmit: _submitComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ChowColors.gray200)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: ChowColors.gray700),
            ),
            const Expanded(
              child: Text(
                '게시글',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChowColors.gray900,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.ios_share, color: ChowColors.gray700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostContentSection extends StatelessWidget {
  const _PostContentSection({
    required this.post,
    required this.isLiked,
    required this.likes,
    required this.commentCount,
    required this.onToggleLike,
  });

  final CommunityPost post;
  final bool isLiked;
  final int likes;
  final int commentCount;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ChowColors.orange100,
                  child: Text(post.avatar, style: const TextStyle(fontSize: 23)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          color: ChowColors.gray900,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                          color: ChowColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: ChowColors.orange500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text('팔로우'),
                ),
                _PostMenuButton(isOwner: isCurrentUserPost(post)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              _detailContent(post),
              style: const TextStyle(
                color: ChowColors.gray800,
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: post.tags
                  .map(
                    (tag) => Text(
                      tag,
                      style: const TextStyle(
                        color: ChowColors.orange500,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          _PostImageGrid(images: [
            post.image,
            'https://images.unsplash.com/photo-1588378898429-6950f6b4f72a?w=600',
            'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=600',
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                _PostStatButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '$likes',
                  color: isLiked ? ChowColors.red500 : ChowColors.gray600,
                  onTap: onToggleLike,
                ),
                const SizedBox(width: 16),
                _PostStatButton(
                  icon: Icons.chat_bubble_outline,
                  label: '$commentCount',
                  color: ChowColors.gray600,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PostMenuAction { save, share, edit, delete }

class _PostMenuButton extends StatelessWidget {
  const _PostMenuButton({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PostMenuAction>(
      tooltip: '게시글 메뉴',
      icon: const Icon(Icons.more_vert, color: ChowColors.gray600),
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

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return AspectRatio(
        aspectRatio: 1,
        child: ChowNetworkImage(url: images.first),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        return AspectRatio(
          aspectRatio: 1,
          child: ChowNetworkImage(url: images[index]),
        );
      },
    );
  }
}

class _PostStatButton extends StatelessWidget {
  const _PostStatButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.commentCount,
    required this.onToggleLike,
  });

  final List<_PostComment> comments;
  final int commentCount;
  final ValueChanged<int> onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Text.rich(
              TextSpan(
                text: '댓글 ',
                style: const TextStyle(
                  color: ChowColors.gray900,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: '$commentCount',
                    style: const TextStyle(color: ChowColors.orange500),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: ChowColors.gray100),
          ...comments.map(
            (comment) => _CommentThread(
              comment: comment,
              onToggleLike: onToggleLike,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentThread extends StatelessWidget {
  const _CommentThread({
    required this.comment,
    required this.onToggleLike,
  });

  final _PostComment comment;
  final ValueChanged<int> onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CommentTile(comment: comment, onToggleLike: onToggleLike),
        ...comment.replies.map(
          (reply) => ColoredBox(
            color: ChowColors.gray50,
            child: Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _CommentTile(
                comment: reply,
                onToggleLike: onToggleLike,
                compact: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onToggleLike,
    this.compact = false,
  });

  final _PostComment comment;
  final ValueChanged<int> onToggleLike;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 18 : 20, 14, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: compact ? 16 : 18,
            backgroundColor: compact ? ChowColors.gray200 : ChowColors.gray100,
            child: Text(comment.avatar),
          ),
          const SizedBox(width: 10),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        color: ChowColors.gray500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: ChowColors.gray700,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => onToggleLike(comment.id),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            size: 15,
                            color: comment.isLiked
                                ? ChowColors.orange500
                                : ChowColors.gray500,
                          ),
                          const SizedBox(width: 4),
                          if (comment.likes > 0)
                            Text(
                              '${comment.likes}',
                              style: TextStyle(
                                color: comment.isLiked
                                    ? ChowColors.orange500
                                    : ChowColors.gray500,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 16),
                      const Text(
                        '답글',
                        style: TextStyle(
                          color: ChowColors.gray500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

class _CommentInputBar extends StatefulWidget {
  const _CommentInputBar({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  State<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<_CommentInputBar> {
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

    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSubmit(),
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    filled: true,
                    fillColor: ChowColors.gray100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                  onTap: enabled ? widget.onSubmit : null,
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.send, color: Colors.white, size: 21),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostComment {
  const _PostComment({
    required this.id,
    required this.author,
    required this.avatar,
    required this.timeAgo,
    required this.content,
    required this.likes,
    this.isLiked = false,
    this.replies = const [],
  });

  final int id;
  final String author;
  final String avatar;
  final String timeAgo;
  final String content;
  final int likes;
  final bool isLiked;
  final List<_PostComment> replies;

  _PostComment toggledLike() {
    return copyWith(
      likes: isLiked ? likes - 1 : likes + 1,
      isLiked: !isLiked,
    );
  }

  _PostComment copyWith({
    int? likes,
    bool? isLiked,
    List<_PostComment>? replies,
  }) {
    return _PostComment(
      id: id,
      author: author,
      avatar: avatar,
      timeAgo: timeAgo,
      content: content,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }
}

List<_PostComment> _initialComments() {
  return const [
    _PostComment(
      id: 1,
      author: '나비아빠',
      avatar: '🐕',
      timeAgo: '1시간 전',
      content: '사진만 봐도 정말 맛있어 보여요! 저희 강아지도 시도해볼게요.',
      likes: 5,
    ),
    _PostComment(
      id: 2,
      author: '코코엄마',
      avatar: '🐶',
      timeAgo: '30분 전',
      content: '닭가슴살은 어디서 구매하셨나요? 추천 부탁드려요!',
      likes: 2,
      replies: [
        _PostComment(
          id: 3,
          author: '멍멍이엄마',
          avatar: '🐕',
          timeAgo: '20분 전',
          content: '동네 마트 무항생제 닭가슴살 사용했어요. 가격도 괜찮더라고요.',
          likes: 3,
        ),
      ],
    ),
    _PostComment(
      id: 4,
      author: '보리집사',
      avatar: '🐱',
      timeAgo: '10분 전',
      content: '레시피 링크 공유 가능할까요? 저도 만들어보고 싶네요.',
      likes: 1,
    ),
  ];
}

String _detailContent(CommunityPost post) {
  return '''${post.content}

레시피는 정말 간단해요.
1. 닭가슴살을 삶아서 작게 찢기
2. 고구마, 브로콜리, 당근을 찜기에 찌기
3. 올리브 오일을 아주 조금만 더해서 섞기

완전한 꿀팁은 올리브 오일을 많이 넣지 않는 거예요. 너무 많이 넣으면 소화가 부담될 수 있어요.

우리 아이가 평소보다 밥을 더 잘 먹어서 여러분도 한번 시도해보셨으면 좋겠어요!''';
}
