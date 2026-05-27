class RecipeModel {
  final int recipeId;
  final String recipeTitle;
  final String? recipeDescription;
  final String? recipePurpose;
  final String? feedingAmount;
  final String? imageUrl;
  final bool isAiGenerated;
  final String? petType;
  final String? menuName;
  final String? menuCategory;

  RecipeModel({
    required this.recipeId,
    required this.recipeTitle,
    this.recipeDescription,
    this.recipePurpose,
    this.feedingAmount,
    this.imageUrl,
    required this.isAiGenerated,
    this.petType,
    this.menuName,
    this.menuCategory,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> j) => RecipeModel(
        recipeId: j['recipeId'] as int,
        recipeTitle: j['recipeTitle'] as String,
        recipeDescription: j['recipeDescription'] as String?,
        recipePurpose: j['recipePurpose'] as String?,
        feedingAmount: j['feedingAmount'] as String?,
        imageUrl: j['imageUrl'] as String?,
        isAiGenerated: j['isAiGenerated'] as bool? ?? false,
        petType: j['petType'] as String?,
        menuName: j['menuName'] as String?,
        menuCategory: j['menuCategory'] as String?,
      );
}

class PetModel {
  final int petId;
  final String petName;
  final String? petType;
  final String? breedName;
  final String? petGender;
  final String? petBirthdate;
  final double? petWeight;
  final String? petProfileImg;
  final List<int> allergyIds;

  PetModel({
    required this.petId,
    required this.petName,
    this.petType,
    this.breedName,
    this.petGender,
    this.petBirthdate,
    this.petWeight,
    this.petProfileImg,
    required this.allergyIds,
  });

  factory PetModel.fromJson(Map<String, dynamic> j) => PetModel(
        petId: j['petId'] as int,
        petName: j['petName'] as String,
        petType: j['petType'] as String?,
        breedName: j['breedName'] as String?,
        petGender: j['petGender'] as String?,
        petBirthdate: j['petBirthdate'] as String?,
        petWeight: (j['petWeight'] as num?)?.toDouble(),
        petProfileImg: j['petProfileImageUrl'] as String? ?? j['petProfileImg'] as String?,
        allergyIds: (j['allergyIds'] as List<dynamic>?)?.cast<int>() ?? [],
      );

  String get displayType => petType == 'DOG' ? '강아지' : petType == 'CAT' ? '고양이' : petType ?? '';
}

class UserModel {
  final int userId;
  final String? userName;
  final String? userNickname;
  final String? userProfileImg;
  final String? authEmail;

  UserModel({
    required this.userId,
    this.userName,
    this.userNickname,
    this.userProfileImg,
    this.authEmail,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        userId: j['userId'] as int,
        userName: j['userName'] as String?,
        userNickname: j['userNickname'] as String?,
        userProfileImg: j['userProfileImg'] as String?,
        authEmail: j['authEmail'] as String?,
      );

  String get displayName => userNickname ?? userName ?? '사용자';
}

class CharacterModel {
  final int characterId;
  final int petId;
  final String? characterName;
  final String? characterImageUrl;
  final int level;
  final int exp;
  final int maxExp;
  final int? health;
  final int? happiness;
  final int? hunger;

  CharacterModel({
    required this.characterId,
    required this.petId,
    this.characterName,
    this.characterImageUrl,
    required this.level,
    required this.exp,
    required this.maxExp,
    this.health,
    this.happiness,
    this.hunger,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> j) => CharacterModel(
        characterId: j['characterId'] as int,
        petId: j['petId'] as int,
        characterName: j['characterName'] as String?,
        characterImageUrl: j['characterImageUrl'] as String?,
        level: j['level'] as int? ?? 1,
        exp: j['exp'] as int? ?? 0,
        maxExp: j['maxExp'] as int? ?? 1000,
        health: j['health'] as int?,
        happiness: j['happiness'] as int?,
        hunger: j['hunger'] as int?,
      );
}