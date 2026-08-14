import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/chow_theme.dart';

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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ChowCozy.stone900),
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
        decoration: BoxDecoration(color: ChowCozy.stone200, borderRadius: BorderRadius.circular(999)),
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
  static const _rewards = ['🍖', '🪙', '🎾', '🪙', '🍖', '✨', '🎁'];
  static const _rewardLabels = ['사료x2', '50코인', '장난감x1', '200코인', '사료x5', '스페셜', '스크래처'];

  bool _giftDrawn = false;
  String? _giftResult;

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday; // 1=월 ... 7=일
    final streak = todayWeekday - 1 + (widget.claimedToday ? 1 : 0);

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
                Text('$streak일 연속 출석 중', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ChowCozy.stone800)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Center(
                    child: Text(_labels[i], style: const TextStyle(fontSize: 11, color: ChowCozy.mutedForeground)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(7, (i) {
                final day = i + 1;
                final isPast = day < todayWeekday;
                final isToday = day == todayWeekday;
                final checked = isPast || (isToday && widget.claimedToday);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayBox(
                      checked: checked,
                      isToday: isToday,
                      emoji: _rewards[i],
                      label: checked ? '완료' : _rewardLabels[i],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: ChowCozy.stone50, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('오늘의 선물 뽑기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ChowCozy.stone800)),
                        Text(
                          _giftResult ?? '하루 1번 랜덤 선물',
                          style: const TextStyle(fontSize: 11, color: ChowCozy.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: _giftDrawn ? ChowCozy.stone200 : ChowCozy.stone700,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _giftDrawn ? null : _drawGift,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Text(
                          _giftDrawn ? '완료' : '뽑기',
                          style: TextStyle(color: _giftDrawn ? ChowCozy.mutedForeground : Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _drawGift() {
    const prizes = ['🍖 사료 x1', '🪙 코인 +20', '🎾 장난감 x1', '✨ 경험치 +10'];
    setState(() {
      _giftDrawn = true;
      _giftResult = '${prizes[DateTime.now().millisecond % prizes.length]} 획득!';
    });
  }
}

class _DayBox extends StatelessWidget {
  const _DayBox({required this.checked, required this.isToday, required this.emoji, required this.label});
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
        border: isToday && !checked ? Border.all(color: ChowCozy.stone400, width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(checked ? '✅' : emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, color: checked ? Colors.white : ChowCozy.mutedForeground, fontWeight: FontWeight.w600),
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
    required this.feedCount,
    required this.petCount,
    required this.playCount,
    required this.walkKm,
    required this.walkLoading,
  });

  final int feedCount;
  final int petCount;
  final int playCount;
  final double walkKm;
  final bool walkLoading;

  @override
  Widget build(BuildContext context) {
    final missions = [
      _Mission('🍽️', '밥주기 3회', '오늘 사료를 3번 줘요', feedCount, 3, '🪙 150P'),
      _Mission('💗', '쓰다듬기 5회', '애정을 듬뿍 표현해요', petCount, 5, '🪙 100P'),
      _Mission('🎾', '놀아주기 2회', '장난감으로 신나게 놀아요', playCount, 2, '🎾 장난감x1'),
      _Mission('🐕', '산책 1km', '반려견과 함께 걸어요', (walkKm * 10).round(), 10, '🪙 100P'),
    ];

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
            ...missions.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MissionRow(mission: m, loading: m.label == '산책 1km' && walkLoading),
                )),
          ],
        ),
      ),
    );
  }
}

class _Mission {
  const _Mission(this.emoji, this.label, this.sub, this.progress, this.total, this.reward);
  final String emoji;
  final String label;
  final String sub;
  final int progress;
  final int total;
  final String reward;
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission, this.loading = false});
  final _Mission mission;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final done = mission.progress >= mission.total;
    final frac = mission.total == 0 ? 0.0 : (mission.progress / mission.total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: done ? ChowCozy.stone50.withValues(alpha: 0.6) : ChowCozy.stone50, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mission.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mission.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ChowCozy.stone800)),
                    Text(mission.sub, style: const TextStyle(fontSize: 11, color: ChowCozy.mutedForeground)),
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
                  done ? '완료' : mission.reward,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: done ? Colors.white : ChowCozy.stone700),
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
                        ? const LinearProgressIndicator(backgroundColor: ChowCozy.stone200, color: ChowCozy.stone400)
                        : Stack(
                            children: [
                              Container(color: ChowCozy.stone200),
                              FractionallySizedBox(widthFactor: frac, child: Container(color: ChowCozy.stone500)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${mission.progress}/${mission.total}회', style: const TextStyle(fontSize: 10, color: ChowCozy.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────── 꾸미기 상점 ───────────────────────────────
/// 백엔드에 모자/얼굴/옷/배경 아이템 체계가 없어서(코인 상점은 방/프로필 전용),
/// 이 화면은 로컬 미리보기로 동작한다 — 실제 코인 차감 없이 장착 상태만 바꾼다.
class DecorateSheet extends StatefulWidget {
  const DecorateSheet({super.key, required this.coins, this.equippedHat, this.onHatChanged});

  final int coins;
  final String? equippedHat;
  final ValueChanged<String?>? onHatChanged;

  @override
  State<DecorateSheet> createState() => _DecorateSheetState();
}

class _CosmeticItem {
  _CosmeticItem(this.emoji, this.name, this.price, {this.owned = false});
  final String emoji;
  final String name;
  final int price;
  bool owned;
}

class _DecorateSheetState extends State<DecorateSheet> {
  int _tab = 0;
  static const _tabs = ['모자', '얼굴', '옷', '배경'];

  late final Map<int, List<_CosmeticItem>> _catalog = {
    0: [
      _CosmeticItem('🎩', '탑햇', 0, owned: true),
      _CosmeticItem('🪖', '군모', 400),
      _CosmeticItem('👒', '밀짚모자', 400),
      _CosmeticItem('🎓', '졸업모', 800),
      _CosmeticItem('👑', '왕관', 1200),
      _CosmeticItem('🎅', '산타모', 800, owned: true),
    ],
    1: [
      _CosmeticItem('🕶️', '선글라스', 400),
      _CosmeticItem('👓', '안경', 600, owned: true),
      _CosmeticItem('🥽', '수경', 600),
      _CosmeticItem('🌸', '꽃장식', 600),
    ],
    2: [
      _CosmeticItem('🦺', '조끼', 600),
      _CosmeticItem('👗', '드레스', 800),
      _CosmeticItem('🏃', '운동복', 1000, owned: true),
      _CosmeticItem('🧥', '코트', 1000),
    ],
    3: [
      _CosmeticItem('🏖️', '해변', 400),
      _CosmeticItem('🌲', '숲속', 800, owned: true),
      _CosmeticItem('🌸', '벚꽃', 800),
      _CosmeticItem('🌈', '무지개', 1200),
    ],
  };

  late String? _equippedName = widget.equippedHat;

  @override
  Widget build(BuildContext context) {
    final items = _catalog[_tab]!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SheetHeader(emoji: '✨', title: '꾸미기 상점'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('보유 코인', style: TextStyle(fontSize: 12, color: ChowCozy.mutedForeground)),
                const Spacer(),
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text('${widget.coins}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ChowCozy.stone800)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = i == _tab;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? ChowCozy.stone800 : ChowCozy.stone50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[i],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : ChowCozy.mutedForeground),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
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
              itemBuilder: (context, i) => _CosmeticTile(
                item: items[i],
                equipped: _tab == 0 && items[i].name == _equippedName,
                onTap: () => _handleTap(items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(_CosmeticItem item) {
    setState(() {
      if (!item.owned) {
        item.owned = true; // 로컬 미리보기 — 실제 코인 차감 없음
      }
      if (_tab == 0) {
        _equippedName = _equippedName == item.name ? null : item.name;
        widget.onHatChanged?.call(_equippedName);
      }
    });
  }
}

class _CosmeticTile extends StatelessWidget {
  const _CosmeticTile({required this.item, required this.equipped, required this.onTap});
  final _CosmeticItem item;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: equipped ? ChowCozy.stone100 : ChowCozy.stone50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ChowCozy.stone800)),
                  const SizedBox(height: 3),
                  if (equipped)
                    const Text('착용중', style: TextStyle(fontSize: 9, color: ChowCozy.stone600, fontWeight: FontWeight.w700))
                  else if (item.owned)
                    const Text('보유', style: TextStyle(fontSize: 9, color: ChowCozy.mutedForeground))
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 9)),
                        Text(' ${item.price}', style: const TextStyle(fontSize: 9, color: ChowCozy.mutedForeground)),
                      ],
                    ),
                ],
              ),
            ),
            if (equipped)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle, size: 14, color: ChowCozy.stone600),
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
                gradient: const LinearGradient(colors: [ChowCozy.stone200, ChowCozy.stone400]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                    child: const Text('24H', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ChowCozy.stone800)),
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
                Text('제작 중인 아이템', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ChowCozy.stone800)),
                Spacer(),
                Icon(Icons.info_outline, size: 13, color: ChowCozy.mutedForeground),
                SizedBox(width: 3),
                Text('안내', style: TextStyle(fontSize: 11, color: ChowCozy.mutedForeground)),
              ],
            ),
            const SizedBox(height: 10),
            ..._items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: ChowCozy.stone50, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ChowCozy.stone800))),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: item.remainSec <= 0
                                        ? null
                                        : () => setState(() => item.remainSec = (item.remainSec - 3600).clamp(0, item.totalSec)),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(border: Border.all(color: ChowCozy.stone300), borderRadius: BorderRadius.circular(999)),
                                      child: const Text('1시간 줄이기', style: TextStyle(fontSize: 9, color: ChowCozy.stone700)),
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
                                      widthFactor: (1 - item.remainSec / item.totalSec).clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [ChowCozy.stone400, ChowCozy.stone700])),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.remainSec <= 0 ? '완료!' : '${_fmt(item.remainSec)} 남음',
                              style: const TextStyle(fontSize: 10, color: ChowCozy.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
