import 'dart:async';

import 'package:flutter/material.dart';

import '../services/character_service.dart';
import '../services/shop_service.dart';
import '../theme/chow_theme.dart';
import '../theme/shop_visuals.dart';

/// 캐릭터 키우기 화면의 하단 팝업(바텀시트) 4종:
/// 출석체크 / 성장미션 / 꾸미기 상점 / 제작소.
/// 코인·스탯처럼 실제 백엔드가 있는 값은 부모(character_page.dart)에서 그대로 받아서 보여주고,
/// 백엔드가 없는 부분(주간 출석 이력, 미션 진행도 일부, 제작 타이머)은 로컬 상태로 동작한다.

/// 공통 시트 헤더 (이모지+제목, 닫기 버튼)
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.emoji, required this.title});
  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$emoji $title',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ChowCozy.stone900,
            ),
          ),
        ),
        Material(
          color: ChowCozy.stone100,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 16, color: ChowCozy.stone600),
            ),
          ),
        ),
      ],
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: ChowCozy.stone200,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// ─────────────────────────────── 출석체크 ───────────────────────────────
class AttendanceSheet extends StatefulWidget {
  const AttendanceSheet({super.key, required this.claimedToday});

  /// 오늘 출석 보상을 이미 받았는지 (실제 /api/coins/daily-login 결과)
  final bool claimedToday;

  @override
  State<AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<AttendanceSheet> {
  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _rewards = ['🪙', '🪙', '🪙', '🪙', '🪙', '🪙', '🪙'];

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday; // 1=월 ... 7=일
    final streak = widget.claimedToday ? 1 : 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SheetHeader(emoji: '📅', title: '출석체크'),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '$streak일 연속 출석 중',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ChowCozy.stone800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: const TextStyle(
                        fontSize: 11,
                        color: ChowCozy.mutedForeground,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(7, (i) {
                final day = i + 1;
                final isToday = day == todayWeekday;
                final checked = isToday && widget.claimedToday;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayBox(
                      checked: checked,
                      isToday: isToday,
                      emoji: _rewards[i],
                      label: checked ? '+5 완료' : '매일 +5',
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            const Text(
              '출석 보상은 하루 한 번 자동으로 5코인 지급됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: ChowCozy.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBox extends StatelessWidget {
  const _DayBox({
    required this.checked,
    required this.isToday,
    required this.emoji,
    required this.label,
  });
  final bool checked;
  final bool isToday;
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: checked ? ChowCozy.stone600 : ChowCozy.stone50,
        borderRadius: BorderRadius.circular(16),
        border: isToday && !checked
            ? Border.all(color: ChowCozy.stone400, width: 2)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(checked ? '✅' : emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              color: checked ? Colors.white : ChowCozy.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────── 성장미션 ───────────────────────────────
class MissionSheet extends StatelessWidget {
  const MissionSheet({
    super.key,
    required this.missions,
    required this.loading,
  });

  final List<DailyMissionModel> missions;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SheetHeader(emoji: '🎯', title: '성장미션'),
            const SizedBox(height: 16),
            ...missions.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MissionRow(mission: m, loading: loading),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission, this.loading = false});
  final DailyMissionModel mission;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final done = mission.claimed;
    final frac = mission.target == 0
        ? 0.0
        : (mission.progress / mission.target).clamp(0.0, 1.0);
    final isWalk = mission.key == 'walk_1km';
    final emoji = switch (mission.key) {
      'feed_3' => '🍽️',
      'pet_5' => '💗',
      'walk_1km' => '🐕',
      _ => '🎯',
    };
    final sub = switch (mission.key) {
      'feed_3' => '오늘 사료를 3번 줘요',
      'pet_5' => '애정을 듬뿍 표현해요',
      'walk_1km' => '반려견과 함께 걸어요',
      _ => '오늘의 미션을 완료해요',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done
            ? ChowCozy.stone50.withValues(alpha: 0.6)
            : ChowCozy.stone50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ChowCozy.stone800,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ChowCozy.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: done ? ChowCozy.stone600 : ChowCozy.stone200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  done ? '지급 완료' : '🪙 ${mission.rewardCoins}P',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: done ? Colors.white : ChowCozy.stone700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: loading
                        ? const LinearProgressIndicator(
                            backgroundColor: ChowCozy.stone200,
                            color: ChowCozy.stone400,
                          )
                        : Stack(
                            children: [
                              Container(color: ChowCozy.stone200),
                              FractionallySizedBox(
                                widthFactor: frac,
                                child: Container(color: ChowCozy.stone500),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isWalk
                    ? '${(mission.progress / 1000).toStringAsFixed(1)}/${(mission.target / 1000).toStringAsFixed(1)}km'
                    : '${mission.progress}/${mission.target}회',
                style: const TextStyle(
                  fontSize: 10,
                  color: ChowCozy.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────── 꾸미기(테마) ───────────────────────────────
/// 모자/얼굴/옷/배경 4개 로컬 미리보기 탭 대신, 실제 코인 상점 백엔드(ShopService)의
/// 방 배경 테마 하나만 남긴다 — 여기서 구매/장착하면 캐릭터 화면 배경에 바로 반영된다.
class ThemeSheet extends StatefulWidget {
  const ThemeSheet({super.key, required this.onChanged});

  /// 테마 구매/장착이 성공할 때마다 최신 카탈로그(코인 잔액 포함)를 부모로 올려준다.
  final ValueChanged<ShopCatalogModel> onChanged;

  @override
  State<ThemeSheet> createState() => _ThemeSheetState();
}

class _ThemeSheetState extends State<ThemeSheet> {
  ShopCatalogModel? _catalog;
  String? _busyKey;
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
      setState(() => _catalog = catalog);
    } catch (_) {
      if (mounted) setState(() => _error = '테마 정보를 불러오지 못했습니다.');
    }
  }

  Future<void> _handleTap(ShopItemModel item) async {
    if (_busyKey != null || item.equipped) return;
    setState(() => _busyKey = item.itemKey);
    try {
      final catalog = item.owned
          ? await ShopService.equip(item.itemKey)
          : await ShopService.purchase(item.itemKey);
      if (!mounted) return;
      setState(() => _catalog = catalog);
      widget.onChanged(catalog);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('처리하지 못했습니다: $e')));
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_catalog?.items ?? const <ShopItemModel>[])
        .where((item) => item.type == ShopItemType.roomBackground)
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SheetHeader(emoji: '🎨', title: '테마'),
            const SizedBox(height: 12),
            if (_catalog != null)
              Row(
                children: [
                  const Text(
                    '보유 코인',
                    style: TextStyle(
                      fontSize: 12,
                      color: ChowCozy.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${_catalog!.balance}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ChowCozy.stone800,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            if (_catalog == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: _error != null
                      ? Text(
                          _error!,
                          style: const TextStyle(
                            color: ChowCozy.mutedForeground,
                          ),
                        )
                      : const CircularProgressIndicator(
                          color: ChowCozy.stone500,
                        ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, i) => _ThemeTile(
                  item: items[i],
                  busy: _busyKey == items[i].itemKey,
                  onTap: () => _handleTap(items[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.item,
    required this.busy,
    required this.onTap,
  });
  final ShopItemModel item;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = roomVisualFor(item.itemKey);
    return Material(
      color: item.equipped ? ChowCozy.stone100 : ChowCozy.stone50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: busy ? null : onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: style.wallColors,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ChowCozy.stone800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (busy)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: ChowCozy.stone500,
                      ),
                    )
                  else if (item.equipped)
                    const Text(
                      '적용중',
                      style: TextStyle(
                        fontSize: 9,
                        color: ChowCozy.stone600,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (item.owned)
                    const Text(
                      '보유',
                      style: TextStyle(
                        fontSize: 9,
                        color: ChowCozy.mutedForeground,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 9)),
                        Text(
                          ' ${item.price}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: ChowCozy.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (item.equipped)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: ChowCozy.stone600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────── 제작소 ───────────────────────────────
class CraftSheet extends StatefulWidget {
  const CraftSheet({super.key});

  @override
  State<CraftSheet> createState() => _CraftSheetState();
}

class _CraftItem {
  _CraftItem(this.emoji, this.name, this.totalSec, this.remainSec);
  final String emoji;
  final String name;
  final int totalSec;
  int remainSec;
}

class _CraftSheetState extends State<CraftSheet> {
  late final List<_CraftItem> _items = [
    _CraftItem('🥩', '수제 사료', 10800, 1850),
    _CraftItem('🍗', '간식 팩', 54000, 52580),
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          if (item.remainSec > 0) item.remainSec--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SheetHeader(emoji: '🏭', title: '제작소'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ChowCozy.stone200, ChowCozy.stone400],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '24H',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ChowCozy.stone800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('🏪', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🍖', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('🍗', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('🦴', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('🐟', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Text(
                  '제작 중인 아이템',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChowCozy.stone800,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: ChowCozy.mutedForeground,
                ),
                SizedBox(width: 3),
                Text(
                  '안내',
                  style: TextStyle(
                    fontSize: 11,
                    color: ChowCozy.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ChowCozy.stone50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ChowCozy.stone800,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: item.remainSec <= 0
                                      ? null
                                      : () => setState(
                                          () => item.remainSec =
                                              (item.remainSec - 3600).clamp(
                                                0,
                                                item.totalSec,
                                              ),
                                        ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: ChowCozy.stone300,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      '1시간 줄이기',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: ChowCozy.stone700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              height: 5,
                              child: Stack(
                                children: [
                                  Container(color: ChowCozy.stone200),
                                  FractionallySizedBox(
                                    widthFactor:
                                        (1 - item.remainSec / item.totalSec)
                                            .clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            ChowCozy.stone400,
                                            ChowCozy.stone700,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.remainSec <= 0
                                ? '완료!'
                                : '${_fmt(item.remainSec)} 남음',
                            style: const TextStyle(
                              fontSize: 10,
                              color: ChowCozy.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
