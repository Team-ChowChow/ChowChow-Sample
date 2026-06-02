import 'api_client.dart';
import 'models.dart';

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
      if (breedId != null) 'breedId': breedId,
      if (characterImageUrl != null) 'characterImageUrl': characterImageUrl,
      if (description != null) 'description': description,
      if (petId != null) 'petId': petId,
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
      if (characterName != null) 'characterName': characterName,
      if (breedId != null) 'breedId': breedId,
      if (characterImageUrl != null) 'characterImageUrl': characterImageUrl,
      if (description != null) 'description': description,
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
