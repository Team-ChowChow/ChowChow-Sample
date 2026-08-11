import 'api_client.dart';

enum ShopItemType {
  roomBackground,
  roomDecor,
  profileFrame;

  static ShopItemType fromApi(String value) {
    return switch (value) {
      'ROOM_BACKGROUND' => ShopItemType.roomBackground,
      'ROOM_DECOR' => ShopItemType.roomDecor,
      'PROFILE_FRAME' => ShopItemType.profileFrame,
      _ => ShopItemType.roomDecor,
    };
  }
}

class ShopItemModel {
  const ShopItemModel({
    required this.itemKey,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    required this.emoji,
    required this.featured,
    required this.owned,
    required this.equipped,
  });

  final String itemKey;
  final String name;
  final String description;
  final ShopItemType type;
  final int price;
  final String emoji;
  final bool featured;
  final bool owned;
  final bool equipped;

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      itemKey: json['itemKey'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: ShopItemType.fromApi(json['itemType'] as String? ?? ''),
      price: (json['price'] as num?)?.toInt() ?? 0,
      emoji: json['emoji'] as String? ?? '🎁',
      featured: json['featured'] as bool? ?? false,
      owned: json['owned'] as bool? ?? false,
      equipped: json['equipped'] as bool? ?? false,
    );
  }
}

class ShopCatalogModel {
  const ShopCatalogModel({required this.balance, required this.items});

  final int balance;
  final List<ShopItemModel> items;

  String get equippedBackgroundKey =>
      items
          .where(
            (item) => item.type == ShopItemType.roomBackground && item.equipped,
          )
          .map((item) => item.itemKey)
          .firstOrNull ??
      'room_sunrise';

  String get equippedProfileFrameKey =>
      items
          .where(
            (item) => item.type == ShopItemType.profileFrame && item.equipped,
          )
          .map((item) => item.itemKey)
          .firstOrNull ??
      'frame_orange';

  Set<String> get equippedDecorKeys => items
      .where((item) => item.type == ShopItemType.roomDecor && item.equipped)
      .map((item) => item.itemKey)
      .toSet();

  factory ShopCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ShopCatalogModel(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      items: rawItems
          .map((item) => ShopItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShopService {
  static Future<ShopCatalogModel> fetchCatalog() async {
    final response = await ApiClient.get('/api/shop') as Map<String, dynamic>;
    return ShopCatalogModel.fromJson(response);
  }

  static Future<ShopCatalogModel> purchase(String itemKey) async {
    final response =
        await ApiClient.post('/api/shop/$itemKey/purchase', {})
            as Map<String, dynamic>;
    return ShopCatalogModel.fromJson(response);
  }

  static Future<ShopCatalogModel> equip(String itemKey) async {
    final response =
        await ApiClient.post('/api/shop/$itemKey/equip', {})
            as Map<String, dynamic>;
    return ShopCatalogModel.fromJson(response);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
