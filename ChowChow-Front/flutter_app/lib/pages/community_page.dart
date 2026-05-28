import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/sample_data.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Text('커뮤니티', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ChowColors.gray800)),
                    const Text(
                      '반려동물 식단에 대한 이야기를 나눠보세요',
                      style: TextStyle(fontSize: 13, color: ChowColors.gray500, fontWeight: FontWeight.normal),
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
                          Icon(Icons.trending_up, color: ChowColors.orange500, size: 22),
                          SizedBox(width: 6),
                          Text('인기 토픽', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
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
                            final t = kTrendingTopics[i];
                            return Material(
                              color: ChowColors.orange50,
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: t.name, style: const TextStyle(fontSize: 13, color: ChowColors.orange600)),
                                        TextSpan(
                                          text: ' (${t.count})',
                                          style: const TextStyle(fontSize: 11, color: ChowColors.orange500),
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
                  child: Row(
                    children: [
                      _TabChip(label: '전체', selected: true, onTap: () {}),
                      _TabChip(label: '레시피', selected: false, onTap: () {}),
                      _TabChip(label: '질문', selected: false, onTap: () {}),
                      _TabChip(label: '후기', selected: false, onTap: () {}),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList.separated(
                  itemCount: kCommunityPosts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _PostCard(post: kCommunityPosts[i]),
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
  const _TabChip({required this.label, required this.selected, required this.onTap});

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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
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
                      Text(post.author, style: const TextStyle(fontWeight: FontWeight.w600, color: ChowColors.gray800)),
                      Text(post.timeAgo, style: const TextStyle(fontSize: 11, color: ChowColors.gray500)),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz, color: ChowColors.gray400)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.content, style: const TextStyle(color: ChowColors.gray700, height: 1.4)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: post.tags.map((t) => Text(t, style: const TextStyle(fontSize: 12, color: ChowColors.orange500))).toList(),
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
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, size: 22, color: ChowColors.gray600),
                  label: Text('${post.likes}', style: const TextStyle(color: ChowColors.gray600)),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 20, color: ChowColors.gray600),
                  label: Text('${post.comments}', style: const TextStyle(color: ChowColors.gray600)),
                ),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 22, color: ChowColors.gray500),
                    const SizedBox(width: 4),
                    Text('${post.views}', style: const TextStyle(color: ChowColors.gray600)),
                  ],
                ),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: ChowColors.gray400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
