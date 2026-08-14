import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/shop_service.dart';
import '../theme/chow_theme.dart';
import '../theme/shop_visuals.dart';

class CoinShopPage extends StatefulWidget {
  const CoinShopPage({super.key});

  @override
  State<CoinShopPage> createState() => _CoinShopPageState();
}

class _CoinShopPageState extends State<CoinShopPage> {
  ShopCatalogModel? _catalog;
  _ShopFilter _filter = _ShopFilter.all;
  String? _previewBackgroundKey;
  String? _busyItemKey;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final catalog = await ShopService.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _previewBackgroundKey = catalog.equippedBackgroundKey;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.statusCode == 403
            ? '로그인이 필요하거나 로그인 정보가 만료되었습니다.'
            : error.message;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '상점 정보를 불러오지 못했습니다.');
    }
  }

  Future<void> _handleAction(ShopItemModel item) async {
    if (_busyItemKey != null ||
        item.equipped && item.type != ShopItemType.roomDecor) {
      return;
    }

    if (!item.owned) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('${item.emoji} ${item.name}'),
              content: Text('${item.price} 코인으로 구매하고 바로 장착할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChowCozy.stone500,
                  ),
                  child: const Text('구매'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) return;
    }

    setState(() => _busyItemKey = item.itemKey);
    try {
      final catalog = item.owned
          ? await ShopService.equip(item.itemKey)
          : await ShopService.purchase(item.itemKey);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _previewBackgroundKey = catalog.equippedBackgroundKey;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.owned
                ? (item.equipped
                      ? '${item.name}을(를) 해제했어요.'
                      : '${item.name}을(를) 장착했어요.')
                : '${item.name} 구매 완료!',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('처리하지 못했습니다. 잠시 후 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _busyItemKey = null);
    }
  }

  List<ShopItemModel> get _visibleItems {
    final items = _catalog?.items ?? const <ShopItemModel>[];
    return items.where((item) {
      return switch (_filter) {
        _ShopFilter.all => true,
        _ShopFilter.background => item.type == ShopItemType.roomBackground,
        _ShopFilter.decor => item.type == ShopItemType.roomDecor,
        _ShopFilter.profile => item.type == ShopItemType.profileFrame,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        title: const Text(
          '코인 상점',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (_catalog != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _CoinBadge(balance: _catalog!.balance),
            ),
        ],
      ),
      body: _catalog == null
          ? _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : const Center(
                    child: CircularProgressIndicator(
                      color: ChowCozy.stone500,
                    ),
                  )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _RoomPreview(
                      backgroundKey:
                          _previewBackgroundKey ??
                          _catalog!.equippedBackgroundKey,
                      decorKeys: _catalog!.equippedDecorKeys,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 70,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      children: _ShopFilter.values.map((filter) {
                        final selected = filter == _filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: selected,
                            label: Text(filter.label),
                            avatar: Icon(filter.icon, size: 18),
                            selectedColor: ChowCozy.stone300,
                            side: BorderSide(
                              color: selected
                                  ? ChowCozy.stone300
                                  : ChowColors.gray200,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? ChowCozy.stone700
                                  : ChowColors.gray600,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: _visibleItems.length,
                    itemBuilder: (context, index) {
                      final item = _visibleItems[index];
                      return _ShopItemCard(
                        item: item,
                        busy: _busyItemKey == item.itemKey,
                        onPreview: item.type == ShopItemType.roomBackground
                            ? () => setState(
                                () => _previewBackgroundKey = item.itemKey,
                              )
                            : null,
                        onAction: () => _handleAction(item),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

enum _ShopFilter { all, background, decor, profile }

extension on _ShopFilter {
  String get label => switch (this) {
    _ShopFilter.all => '전체',
    _ShopFilter.background => '배경',
    _ShopFilter.decor => '소품',
    _ShopFilter.profile => '프로필',
  };

  IconData get icon => switch (this) {
    _ShopFilter.all => Icons.grid_view_rounded,
    _ShopFilter.background => Icons.wallpaper_rounded,
    _ShopFilter.decor => Icons.chair_alt_rounded,
    _ShopFilter.profile => Icons.account_circle_outlined,
  };
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFD58A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(
              '$balance',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomPreview extends StatelessWidget {
  const _RoomPreview({required this.backgroundKey, required this.decorKeys});

  final String backgroundKey;
  final Set<String> decorKeys;

  @override
  Widget build(BuildContext context) {
    final style = roomVisualFor(backgroundKey);
    final dark = backgroundKey == 'room_night';

    return Container(
      height: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: style.wallColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 68,
            child: ColoredBox(color: style.floorColor),
          ),
          Positioned(
            top: 18,
            left: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: dark ? 0.16 : 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                style.label,
                style: TextStyle(
                  color: dark ? Colors.white : ChowColors.gray700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 28,
            child: Icon(
              backgroundKey == 'room_night'
                  ? Icons.nightlight_round
                  : Icons.window_rounded,
              size: 58,
              color: style.accentColor.withValues(alpha: 0.75),
            ),
          ),
          if (decorKeys.contains('decor_lamp'))
            const Positioned(
              left: 18,
              bottom: 48,
              child: Text('💡', style: TextStyle(fontSize: 48)),
            ),
          if (decorKeys.contains('decor_plant'))
            const Positioned(
              right: 16,
              bottom: 46,
              child: Text('🪴', style: TextStyle(fontSize: 54)),
            ),
          if (decorKeys.contains('decor_cushion'))
            const Positioned(
              right: 86,
              bottom: 22,
              child: Text('🧸', style: TextStyle(fontSize: 38)),
            ),
          Align(
            alignment: const Alignment(0, 0.58),
            child: Container(
              width: 118,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: const BorderRadius.all(Radius.elliptical(70, 32)),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.2),
            child: Image.asset(
              'assets/images/characters/character_group_1.png',
              width: 116,
              height: 116,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.busy,
    required this.onAction,
    this.onPreview,
  });

  final ShopItemModel item;
  final bool busy;
  final VoidCallback onAction;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final actionLabel = item.equipped
        ? (item.type == ShopItemType.roomDecor ? '해제하기' : '장착 중')
        : item.owned
        ? '장착하기'
        : '${item.price}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPreview,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.equipped ? ChowCozy.stone300 : ChowColors.gray200,
              width: item.equipped ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: item.type == ShopItemType.profileFrame
                            ? ChowCozy.stone100
                            : const Color(0xFFF7F7F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: item.type == ShopItemType.profileFrame
                          ? _FramePreview(itemKey: item.itemKey)
                          : Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 52),
                            ),
                    ),
                    if (item.featured)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ChowColors.pink500,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (item.owned)
                      const Positioned(
                        top: 7,
                        left: 7,
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ChowColors.gray800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: ChowColors.gray500,
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: FilledButton(
                  onPressed:
                      busy ||
                          item.equipped && item.type != ShopItemType.roomDecor
                      ? null
                      : onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: item.owned
                        ? ChowColors.gray700
                        : ChowCozy.stone500,
                    padding: EdgeInsets.zero,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!item.owned) ...[
                              const Text('🪙', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

class _FramePreview extends StatelessWidget {
  const _FramePreview({required this.itemKey});

  final String itemKey;

  @override
  Widget build(BuildContext context) {
    final frame = profileFrameVisualFor(itemKey);
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: frame.colors),
        boxShadow: [BoxShadow(color: frame.shadowColor, blurRadius: 10)],
      ),
      child: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 34, color: ChowColors.gray400),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 58,
              color: ChowColors.gray300,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ChowColors.gray600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
