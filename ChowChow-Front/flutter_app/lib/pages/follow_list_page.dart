import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/follow_service.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key, required this.type});

  final FollowListType type;

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  List<FollowUserModel> _users = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await FollowService.fetchUsers(widget.type);
      if (!mounted) return;
      setState(() {
        _users = result.users;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '${widget.type.pageTitle} 목록을 불러오지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: Text(widget.type.pageTitle),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ChowCozy.stone500),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 44, color: ChowColors.gray400),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: ChowColors.gray600),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadUsers, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(
              widget.type == FollowListType.followers
                  ? Icons.group_outlined
                  : Icons.person_add_alt_outlined,
              size: 48,
              color: ChowColors.gray400,
            ),
            const SizedBox(height: 12),
            Text(
              widget.type == FollowListType.followers
                  ? '아직 팔로워가 없습니다.'
                  : '아직 팔로우한 사용자가 없습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ChowColors.gray500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _FollowUserTile(user: _users[index]),
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({required this.user});

  final FollowUserModel user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.userProfileImg?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ChowNetworkImage(url: imageUrl, fit: BoxFit.cover)
                    : const ColoredBox(
                        color: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 26,
                          color: ChowCozy.stone500,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: ChowColors.gray900,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (user.userName?.trim().isNotEmpty == true &&
                      user.userName!.trim() != user.displayName) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.userName!.trim(),
                      style: const TextStyle(
                        color: ChowColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
