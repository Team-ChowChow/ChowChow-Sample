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
  final double averageRating;
  final int reviewCount;
  final int likeCount;
  final String authorNickname;
  final DateTime? createdAt;

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
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.likeCount = 0,
    this.authorNickname = '관리자',
    this.createdAt,
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
        averageRating: (j['averageRating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        authorNickname: j['authorNickname'] as String? ?? '관리자',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

class DietIngredientModel {
  final String name;
  final String? amount;

  DietIngredientModel({required this.name, this.amount});

  factory DietIngredientModel.fromJson(Map<String, dynamic> j) => DietIngredientModel(
        name: j['name'] as String? ?? '',
        amount: j['amount'] as String?,
      );
}

class DietGenerateModel {
  final int? recipeId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? feedingAmount;
  final List<DietIngredientModel> ingredients;
  final List<String> steps;
  final List<String> warnings;

  DietGenerateModel({
    this.recipeId,
    required this.title,
    this.description,
    this.imageUrl,
    this.feedingAmount,
    required this.ingredients,
    required this.steps,
    required this.warnings,
  });

  factory DietGenerateModel.fromJson(Map<String, dynamic> j) => DietGenerateModel(
        recipeId: j['recipeId'] as int?,
        title: j['title'] as String? ?? 'AI 맞춤 레시피',
        description: j['description'] as String?,
        imageUrl: j['imageUrl'] as String?,
        feedingAmount: j['feedingAmount'] as String?,
        ingredients: (j['ingredients'] as List<dynamic>?)
                ?.map((e) => DietIngredientModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        steps: (j['steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        warnings: (j['warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class PetModel {
  final int petId;
  final String petName;
  final String? petType;
  final String? breedName;
  final String? groupName;
  final String? petGender;
  final String? petBirthdate;
  final double? petWeight;
  final String? petProfileImg;
  final List<int> allergyIds;
  final int? petBodyConditionScore;
  final int? petActivityLevel;
  final List<String> healthFocusAreas;

  PetModel({
    required this.petId,
    required this.petName,
    this.petType,
    this.breedName,
    this.groupName,
    this.petGender,
    this.petBirthdate,
    this.petWeight,
    this.petProfileImg,
    required this.allergyIds,
    this.petBodyConditionScore,
    this.petActivityLevel,
    this.healthFocusAreas = const [],
  });

  factory PetModel.fromJson(Map<String, dynamic> j) => PetModel(
        petId: j['petId'] as int,
        petName: j['petName'] as String,
        petType: j['petType'] as String?,
        breedName: j['breedName'] as String?,
        groupName: j['groupName'] as String?,
        petGender: j['petGender'] as String?,
        petBirthdate: j['petBirthdate'] as String?,
        petWeight: (j['petWeight'] as num?)?.toDouble(),
        petProfileImg: j['petProfileImageUrl'] as String? ?? j['petProfileImg'] as String?,
        allergyIds: (j['allergyIds'] as List<dynamic>?)?.cast<int>() ?? [],
        petBodyConditionScore: (j['petBodyConditionScore'] as num?)?.toInt(),
        petActivityLevel: (j['petActivityLevel'] as num?)?.toInt(),
        healthFocusAreas: (j['healthFocusAreas'] as List<dynamic>?)?.cast<String>() ?? const [],
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

class BreedModel {
  final int breedId;
  final String breedName;
  final String breedNameKo;
  final String petType;

  BreedModel({
    required this.breedId,
    required this.breedName,
    required this.breedNameKo,
    required this.petType,
  });

  factory BreedModel.fromJson(Map<String, dynamic> j) => BreedModel(
        breedId: j['breedId'] as int,
        breedName: j['breedName'] as String? ?? '',
        breedNameKo: j['breedNameKo'] as String? ?? j['breedName'] as String? ?? '',
        petType: j['petType'] as String? ?? '',
      );

  String get displayName => breedNameKo.isNotEmpty ? breedNameKo : breedName;
}

class CharacterModel {
  final int characterId;
  final int petId;
  final String characterName;
  final String? characterImageUrl;
  final String? description;
  final String? petType;
  final String? petTypeLabel;
  final int? breedId;
  final String? breedName;
  final String? groupName;
  final int level;
  final int exp;
  final int requiredExp;
  final int expToNextLevel;
  final int health;
  final int happiness;
  final int hunger;

  CharacterModel({
    required this.characterId,
    required this.petId,
    required this.characterName,
    this.characterImageUrl,
    this.description,
    this.petType,
    this.petTypeLabel,
    this.breedId,
    this.breedName,
    this.groupName,
    required this.level,
    required this.exp,
    required this.requiredExp,
    required this.expToNextLevel,
    required this.health,
    required this.happiness,
    required this.hunger,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> j) => CharacterModel(
        characterId: j['characterId'] as int,
        petId: j['petId'] as int,
        characterName: j['characterName'] as String? ?? '',
        characterImageUrl: j['characterImageUrl'] as String?,
        description: j['description'] as String?,
        petType: j['petType'] as String?,
        petTypeLabel: j['petTypeLabel'] as String?,
        breedId: j['breedId'] as int?,
        breedName: j['breedName'] as String?,
        groupName: j['groupName'] as String?,
        level: j['characterLevel'] as int? ?? j['level'] as int? ?? 1,
        exp: j['currentExp'] as int? ?? j['exp'] as int? ?? 0,
        requiredExp: j['requiredExp'] as int? ?? 100,
        expToNextLevel: j['expToNextLevel'] as int? ?? 0,
        health: j['health'] as int? ?? 80,
        happiness: j['happiness'] as int? ?? 80,
        hunger: j['hunger'] as int? ?? 50,
      );

  String get typeBreedLine {
    final type = petTypeLabel ?? '';
    final breed = breedName ?? '';
    if (type.isEmpty && breed.isEmpty) return '';
    if (breed.isEmpty) return type;
    return '$type · $breed';
  }

  double get expFraction =>
      requiredExp > 0 ? (exp / requiredExp).clamp(0.0, 1.0) : 0.0;
}

class GrowthLogModel {
  final int growthLogId;
  final String activityType;
  final String activityLabel;
  final int expGained;
  final String? statusChanges;
  final bool levelUp;
  final int? previousLevel;
  final int? newLevel;
  final DateTime? createdAt;

  GrowthLogModel({
    required this.growthLogId,
    required this.activityType,
    required this.activityLabel,
    required this.expGained,
    this.statusChanges,
    required this.levelUp,
    this.previousLevel,
    this.newLevel,
    this.createdAt,
  });

  factory GrowthLogModel.fromJson(Map<String, dynamic> j) => GrowthLogModel(
        growthLogId: j['growthLogId'] as int,
        activityType: j['activityType'] as String? ?? '',
        activityLabel: j['activityLabel'] as String? ?? j['activityType'] as String? ?? '',
        expGained: j['expGained'] as int? ?? j['growthValue'] as int? ?? 0,
        statusChanges: j['statusChanges'] as String? ?? j['description'] as String?,
        levelUp: j['levelUp'] as bool? ?? false,
        previousLevel: j['previousLevel'] as int?,
        newLevel: j['newLevel'] as int?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );
}

class FeedingGuidelineModel {
  final double petWeightKg;
  final String ageCategory;
  final double activityFactor;
  final double restingEnergyKcal;
  final double dailyEnergyKcal;
  final double? recommendedGrams;
  final String? status;
  final String? message;

  FeedingGuidelineModel({
    required this.petWeightKg,
    required this.ageCategory,
    required this.activityFactor,
    required this.restingEnergyKcal,
    required this.dailyEnergyKcal,
    this.recommendedGrams,
    this.status,
    this.message,
  });

  factory FeedingGuidelineModel.fromJson(Map<String, dynamic> j) => FeedingGuidelineModel(
        petWeightKg: (j['petWeightKg'] as num).toDouble(),
        ageCategory: j['ageCategory'] as String,
        activityFactor: (j['activityFactor'] as num).toDouble(),
        restingEnergyKcal: (j['restingEnergyKcal'] as num).toDouble(),
        dailyEnergyKcal: (j['dailyEnergyKcal'] as num).toDouble(),
        recommendedGrams: (j['recommendedGrams'] as num?)?.toDouble(),
        status: j['status'] as String?,
        message: j['message'] as String?,
      );
}

class CommercialFoodModel {
  final int foodId;
  final String brandName;
  final String productName;
  final String? petType;
  final double? caloriesPer100g;
  final double? proteinG;
  final double? fatG;
  final double? carbohydrateG;
  final String? features;
  final String? imageUrl;
  /// true면 공식 카탈로그가 아니라 사용자가 직접 등록한 사료(`UserFoods`)다.
  final bool isUserFood;

  CommercialFoodModel({
    required this.foodId,
    required this.brandName,
    required this.productName,
    this.petType,
    this.caloriesPer100g,
    this.proteinG,
    this.fatG,
    this.carbohydrateG,
    this.features,
    this.imageUrl,
    this.isUserFood = false,
  });

  factory CommercialFoodModel.fromJson(Map<String, dynamic> j) => CommercialFoodModel(
        foodId: j['foodId'] as int,
        brandName: j['brandName'] as String,
        productName: j['productName'] as String,
        petType: j['petType'] as String?,
        caloriesPer100g: (j['caloriesPer100g'] as num?)?.toDouble(),
        proteinG: (j['proteinG'] as num?)?.toDouble(),
        fatG: (j['fatG'] as num?)?.toDouble(),
        carbohydrateG: (j['carbohydrateG'] as num?)?.toDouble(),
        features: j['features'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );

  factory CommercialFoodModel.fromUserFoodJson(Map<String, dynamic> j) => CommercialFoodModel(
        foodId: j['userFoodId'] as int,
        brandName: (j['brandName'] as String?) ?? '직접 등록',
        productName: j['productName'] as String,
        petType: j['petType'] as String?,
        caloriesPer100g: (j['caloriesPer100g'] as num?)?.toDouble(),
        proteinG: (j['proteinG'] as num?)?.toDouble(),
        fatG: (j['fatG'] as num?)?.toDouble(),
        carbohydrateG: (j['carbohydrateG'] as num?)?.toDouble(),
        isUserFood: true,
      );
}

class MealRecordModel {
  final int mealId;
  final int? petId;
  final String mealTitle;
  final String? mealNote;
  final String? imageUrl;
  final String? mealDate;
  final double? feedingAmountG;
  final int? recipeId;
  final int? commercialFoodId;
  final int? userFoodId;
  final String? recipeTitle;
  final String? foodBrandName;
  final String? foodProductName;
  final String? foodImageUrl;
  final bool isUserFood;

  bool get isCompletedRecipe =>
      recipeId != null && (mealNote?.contains('조리 완료') ?? false);

  MealRecordModel({
    required this.mealId,
    this.petId,
    required this.mealTitle,
    this.mealNote,
    this.imageUrl,
    this.mealDate,
    this.feedingAmountG,
    this.recipeId,
    this.commercialFoodId,
    this.userFoodId,
    this.recipeTitle,
    this.foodBrandName,
    this.foodProductName,
    this.foodImageUrl,
    this.isUserFood = false,
  });

  factory MealRecordModel.fromJson(Map<String, dynamic> j) => MealRecordModel(
        mealId: j['mealId'] as int,
        petId: j['petId'] as int?,
        mealTitle: j['mealTitle'] as String,
        mealNote: j['mealNote'] as String?,
        imageUrl: j['imageUrl'] as String?,
        mealDate: j['mealDate'] as String?,
        feedingAmountG: (j['feedingAmountG'] as num?)?.toDouble(),
        recipeId: j['recipeId'] as int?,
        commercialFoodId: j['commercialFoodId'] as int?,
        userFoodId: j['userFoodId'] as int?,
        recipeTitle: j['recipeTitle'] as String?,
        foodBrandName: j['foodBrandName'] as String?,
        foodProductName: j['foodProductName'] as String?,
        foodImageUrl: j['foodImageUrl'] as String?,
        isUserFood: j['isUserFood'] as bool? ?? false,
      );
}

class FoodTransitionStepModel {
  final String dayRange;
  final int currentFoodPercent;
  final int newFoodPercent;
  final String? note;

  FoodTransitionStepModel({
    required this.dayRange,
    required this.currentFoodPercent,
    required this.newFoodPercent,
    this.note,
  });

  factory FoodTransitionStepModel.fromJson(Map<String, dynamic> j) => FoodTransitionStepModel(
        dayRange: j['dayRange'] as String? ?? '',
        currentFoodPercent: (j['currentFoodPercent'] as num?)?.toInt() ?? 0,
        newFoodPercent: (j['newFoodPercent'] as num?)?.toInt() ?? 0,
        note: j['note'] as String?,
      );
}

class FoodTransitionModel {
  final String summary;
  final int? totalDays;
  final List<FoodTransitionStepModel> schedule;
  final List<String> warnings;

  FoodTransitionModel({
    required this.summary,
    this.totalDays,
    required this.schedule,
    required this.warnings,
  });

  factory FoodTransitionModel.fromJson(Map<String, dynamic> j) => FoodTransitionModel(
        summary: j['summary'] as String? ?? '',
        totalDays: (j['totalDays'] as num?)?.toInt(),
        schedule: (j['schedule'] as List<dynamic>? ?? [])
            .map((e) => FoodTransitionStepModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        warnings: (j['warnings'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}

class AllergyModel {
  final int allergyId;
  final String allergyName;
  final String allergyDescription;

  AllergyModel({
    required this.allergyId,
    required this.allergyName,
    required this.allergyDescription,
  });

  factory AllergyModel.fromJson(Map<String, dynamic> j) => AllergyModel(
        allergyId: j['allergyId'] as int,
        allergyName: j['allergyName'] as String,
        allergyDescription: j['allergyDescription'] as String? ?? '',
      );
}
