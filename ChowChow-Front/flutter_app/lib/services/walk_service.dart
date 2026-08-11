import 'api_client.dart';

class WalkMilestoneModel {
  const WalkMilestoneModel({
    required this.targetMeters,
    required this.rewardCoins,
    required this.achieved,
  });

  final int targetMeters;
  final int rewardCoins;
  final bool achieved;

  factory WalkMilestoneModel.fromJson(Map<String, dynamic> json) {
    return WalkMilestoneModel(
      targetMeters: (json['targetMeters'] as num?)?.toInt() ?? 0,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
      achieved: json['achieved'] as bool? ?? false,
    );
  }
}

class WalkSummaryModel {
  const WalkSummaryModel({
    required this.date,
    required this.todayDistanceMeters,
    required this.todayRewardCoins,
    required this.balance,
    required this.milestones,
  });

  final String date;
  final int todayDistanceMeters;
  final int todayRewardCoins;
  final int balance;
  final List<WalkMilestoneModel> milestones;

  double get todayDistanceKm => todayDistanceMeters / 1000;

  WalkMilestoneModel? get nextMilestone {
    for (final milestone in milestones) {
      if (!milestone.achieved) return milestone;
    }
    return null;
  }

  factory WalkSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as List<dynamic>? ?? [];
    return WalkSummaryModel(
      date: json['date'] as String? ?? '',
      todayDistanceMeters:
          (json['todayDistanceMeters'] as num?)?.toInt() ?? 0,
      todayRewardCoins:
          (json['todayRewardCoins'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      milestones: rawMilestones
          .map(
            (item) => WalkMilestoneModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class WalkRecordModel {
  const WalkRecordModel({
    required this.walkId,
    required this.sessionId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.averageSpeedKmh,
    required this.rewardCoins,
    required this.startedAt,
    required this.endedAt,
  });

  final int walkId;
  final String sessionId;
  final int distanceMeters;
  final int durationSeconds;
  final double averageSpeedKmh;
  final int rewardCoins;
  final DateTime? startedAt;
  final DateTime? endedAt;

  double get distanceKm => distanceMeters / 1000;

  factory WalkRecordModel.fromJson(Map<String, dynamic> json) {
    return WalkRecordModel(
      walkId: (json['walkId'] as num?)?.toInt() ?? 0,
      sessionId: json['sessionId'] as String? ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toDouble() ?? 0,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? ''),
    );
  }
}

class WalkFinishResult {
  const WalkFinishResult({
    required this.walk,
    required this.today,
    required this.earnedCoins,
  });

  final WalkRecordModel walk;
  final WalkSummaryModel today;
  final int earnedCoins;

  factory WalkFinishResult.fromJson(Map<String, dynamic> json) {
    return WalkFinishResult(
      walk: WalkRecordModel.fromJson(json['walk'] as Map<String, dynamic>),
      today: WalkSummaryModel.fromJson(json['today'] as Map<String, dynamic>),
      earnedCoins: (json['earnedCoins'] as num?)?.toInt() ?? 0,
    );
  }
}

class WalkService {
  static Future<WalkSummaryModel> fetchToday() async {
    final response =
        await ApiClient.get('/api/walks/today') as Map<String, dynamic>;
    return WalkSummaryModel.fromJson(response);
  }

  static Future<List<WalkRecordModel>> fetchRecent({int limit = 20}) async {
    final response = await ApiClient.get(
      '/api/walks',
      query: {'limit': '$limit'},
    ) as List<dynamic>;
    return response
        .map(
          (item) => WalkRecordModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<WalkFinishResult> finish({
    required String sessionId,
    required int distanceMeters,
    required int durationSeconds,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final response = await ApiClient.post('/api/walks', {
      'sessionId': sessionId,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'endedAt': endedAt.toUtc().toIso8601String(),
    }) as Map<String, dynamic>;
    return WalkFinishResult.fromJson(response);
  }
}
