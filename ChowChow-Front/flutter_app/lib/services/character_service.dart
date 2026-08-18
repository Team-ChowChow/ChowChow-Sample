import 'api_client.dart';
import 'models.dart';

class DailyMissionModel {
  const DailyMissionModel({
    required this.key,
    required this.label,
    required this.progress,
    required this.target,
    required this.rewardCoins,
    required this.completed,
    required this.claimed,
  });

  final String key;
  final String label;
  final int progress;
  final int target;
  final int rewardCoins;
  final bool completed;
  final bool claimed;

  factory DailyMissionModel.fromJson(Map<String, dynamic> json) {
    return DailyMissionModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}

class DailyMissionSummaryModel {
  const DailyMissionSummaryModel({
    required this.balance,
    required this.missions,
  });

  final int balance;
  final List<DailyMissionModel> missions;

  factory DailyMissionSummaryModel.fromJson(Map<String, dynamic> json) {
    final missions = json['missions'] as List<dynamic>? ?? [];
    return DailyMissionSummaryModel(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      missions: missions
          .map((item) => DailyMissionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CharacterService {
  static Future<List<CharacterModel>> fetchCharacters() async {
    final res = await ApiClient.get('/api/characters') as List<dynamic>;
    return res.map((e) => CharacterModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<CharacterModel> fetchCharacter(int characterId) async {
    final res = await ApiClient.get('/api/characters/$characterId') as Map<String, dynamic>;
    return CharacterModel.fromJson(res);
  }

  static Future<CharacterModel> createCharacter({
    required String characterName,
    required String petType,
    int? breedId,
    String? characterImageUrl,
    String? description,
    int? petId,
  }) async {
    final res = await ApiClient.post('/api/characters', {
      'characterName': characterName,
      'petType': petType,
      'breedId': ?breedId,
      'characterImageUrl': ?characterImageUrl,
      'description': ?description,
      'petId': ?petId,
    }) as Map<String, dynamic>;
    return CharacterModel.fromJson(res);
  }

  static Future<CharacterModel> updateCharacter(
    int characterId, {
    String? characterName,
    int? breedId,
    String? characterImageUrl,
    String? description,
  }) async {
    final res = await ApiClient.patch('/api/characters/$characterId', {
      'characterName': ?characterName,
      'breedId': ?breedId,
      'characterImageUrl': ?characterImageUrl,
      'description': ?description,
    }) as Map<String, dynamic>;
    return CharacterModel.fromJson(res);
  }

  static Future<void> deleteCharacter(int characterId) async {
    await ApiClient.delete('/api/characters/$characterId');
  }

  static Future<CharacterModel> performActivity(int characterId, String activityType) async {
    final res = await ApiClient.post('/api/characters/$characterId/activity', {
      'activityType': activityType,
    }) as Map<String, dynamic>;
    return CharacterModel.fromJson(res);
  }

  static Future<DailyMissionSummaryModel> fetchDailyMissions() async {
    final res = await ApiClient.get('/api/coins/missions/today')
        as Map<String, dynamic>;
    return DailyMissionSummaryModel.fromJson(res);
  }

  static Future<List<GrowthLogModel>> fetchGrowthLogs(
    int characterId, {
    String? filter,
  }) async {
    final res = await ApiClient.get(
      '/api/characters/$characterId/growth-logs',
      query: filter != null && filter.isNotEmpty ? {'filter': filter} : null,
    ) as List<dynamic>;
    return res.map((e) => GrowthLogModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<BreedModel>> fetchBreeds(String petType) async {
    final res = await ApiClient.get('/api/pets/breeds', query: {'petType': petType}) as List<dynamic>;
    return res.map((e) => BreedModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
