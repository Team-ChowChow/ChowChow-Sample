import 'api_client.dart';

enum FollowListType {
  followers,
  following;

  String get apiPath => switch (this) {
        FollowListType.followers => '/api/users/me/followers',
        FollowListType.following => '/api/users/me/following',
      };

  String get pageTitle => switch (this) {
        FollowListType.followers => '팔로워',
        FollowListType.following => '팔로잉',
      };
}

class FollowUserModel {
  const FollowUserModel({
    required this.userId,
    this.userName,
    this.userNickname,
    this.userProfileImg,
    this.isFollowing = false,
  });

  final int userId;
  final String? userName;
  final String? userNickname;
  final String? userProfileImg;
  final bool isFollowing;

  String get displayName {
    final nickname = userNickname?.trim();
    if (nickname != null && nickname.isNotEmpty) return nickname;
    final name = userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '사용자';
  }

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    return FollowUserModel(
      userId: (json['userId'] as num).toInt(),
      userName: json['userName'] as String?,
      userNickname: json['userNickname'] as String?,
      userProfileImg: json['userProfileImg'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
}

class FollowUserPage {
  const FollowUserPage({
    required this.users,
    required this.totalElements,
    required this.page,
    required this.isLast,
  });

  final List<FollowUserModel> users;
  final int totalElements;
  final int page;
  final bool isLast;
}

class FollowService {
  FollowService._();

  static Future<FollowUserPage> fetchUsers(
    FollowListType type, {
    int page = 0,
    int size = 50,
  }) async {
    final response = await ApiClient.get(
      type.apiPath,
      query: {'page': '$page', 'size': '$size'},
    );

    if (response is List<dynamic>) {
      final users = _parseUsers(response);
      return FollowUserPage(
        users: users,
        totalElements: users.length,
        page: page,
        isLast: true,
      );
    }

    final body = response as Map<String, dynamic>;
    final rawUsers = body['content'] as List<dynamic>? ??
        body['users'] as List<dynamic>? ??
        body['items'] as List<dynamic>? ??
        const <dynamic>[];
    final users = _parseUsers(rawUsers);

    return FollowUserPage(
      users: users,
      totalElements:
          (body['totalElements'] as num?)?.toInt() ?? users.length,
      page: (body['number'] as num?)?.toInt() ?? page,
      isLast: body['last'] as bool? ?? true,
    );
  }

  static Future<void> follow(int userId) async {
    await ApiClient.post('/api/users/$userId/follow', {});
  }

  static Future<void> unfollow(int userId) async {
    await ApiClient.delete('/api/users/$userId/follow');
  }

  static List<FollowUserModel> _parseUsers(List<dynamic> rawUsers) {
    return rawUsers
        .map(
          (user) => FollowUserModel.fromJson(user as Map<String, dynamic>),
        )
        .toList();
  }
}
