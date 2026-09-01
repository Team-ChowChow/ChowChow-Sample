import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/chow_theme.dart';

/// Figma "CoinShop.tsx" 그대로 이식: 아이템 구매(장난감/사료/간식 등) + 코인 충전 탭.
/// 코인 잔액/아이템 구매는 기존 코인 API(`/api/coins/balance`, `/api/coins/spend`)에 그대로 연동한다.
/// 코인 충전(실제 결제)은 연동 전이라 버튼을 눌러도 잔액이 늘지 않고 안내만 뜬다.
class CoinShopPage extends StatefulWidget {
  const CoinShopPage({super.key});

  @override
  State<CoinShopPage> createState() => _CoinShopPageState();
}

enum _Tab { items, coins }

class _ShopItem {
  const _ShopItem(this.id, this.emoji, this.name, this.desc, this.price, this.tag);
  final int id;
  final String emoji;
  final String name;
  final String desc;
  final int price;
  final String? tag;
}

class _CoinPack {
  const _CoinPack(this.id, this.coins, this.won, this.bonus, this.tag);
  final int id;
  final int coins;
  final String won;
  final int? bonus;
  final String? tag;

  int get total => coins + (bonus ?? 0);
}

const _shopItems = [
  _ShopItem(1, '🎾', '장난감', '놀아주기 1회', 100, null),
  _ShopItem(2, '🎾', '장난감 ×3', '놀아주기 3회', 270, '할인'),
  _ShopItem(3, '⭐', '스페셜 장난감', '특별 놀이 효과', 500, '인기'),
  _ShopItem(4, '🥩', '사료', '밥주기 1회', 50, null),
  _ShopItem(5, '🥩', '사료 ×5', '밥주기 5회', 220, '할인'),
  _ShopItem(6, '🥩', '프리미엄 사료', '에너지 +100', 150, null),
  _ShopItem(7, '🍗', '간식', '경험치 +3', 30, null),
  _ShopItem(8, '🍰', '생일 케이크', '경험치 대폭 상승', 200, '한정'),
  _ShopItem(9, '🛁', '목욕 키트', '목욕하기 3회', 180, null),
];

const _coinPacks = [
  _CoinPack(1, 100, '₩1,100', null, null),
  _CoinPack(2, 330, '₩2,900', 30, '인기'),
  _CoinPack(3, 1100, '₩8,900', 100, '추천'),
  _CoinPack(4, 3600, '₩22,900', 600, '최고'),
];

class _CoinShopPageState extends State<CoinShopPage> {
  _Tab _tab = _Tab.items;
  int? _balance;
  bool _loading = true;
  String? _error;
  int? _busyItemId;
  String? _toast;
  Timer? _toastTimer;
  bool _grantingTestCoins = false; // TODO(임시): 테스트 코인 지급용 — 사용 후 제거할 것.

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await ApiClient.get('/api/coins/balance') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _balance = (res['balance'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.statusCode == 403
            ? '로그인이 필요하거나 로그인 정보가 만료되었습니다.'
            : error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '코인 정보를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _buyItem(_ShopItem item) async {
    if (_busyItemId != null) return;
    final balance = _balance;
    if (balance == null) return;
    if (balance < item.price) {
      _showToast('코인이 부족해요!');
      return;
    }
    setState(() => _busyItemId = item.id);
    try {
      final res =
          await ApiClient.post('/api/coins/spend', {
                'amount': item.price,
                'reason': '아이템 구매: ${item.name}',
              })
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _balance = (res['balance'] as num?)?.toInt() ?? (balance - item.price);
        _busyItemId = null;
      });
      _showToast('${item.name} 구매 완료! ✅');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busyItemId = null);
      _showToast(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyItemId = null);
      _showToast('구매에 실패했어요.');
    }
  }

  void _buyCoinPack(_CoinPack pack) {
    // 실제 결제 연동 전 — 잔액은 바꾸지 않고 안내만 표시한다.
    _showToast('실제 결제 연동은 준비 중이에요.');
  }

  // TODO(임시): 테스트 코인 지급용 — 사용 후 이 메서드와 위 버튼을 제거할 것.
  // '/api/coins/earn'이 아직 배포 서버에 없어서(404), 이미 배포된 '/api/coins/spend'에
  // 음수 amount를 보내 balance -= (-2000)이 되게 하는 임시 편법을 쓴다.
  Future<void> _handleGrantTestCoins() async {
    if (_grantingTestCoins) return;
    setState(() => _grantingTestCoins = true);
    try {
      final res =
          await ApiClient.post('/api/coins/spend', {
                'amount': -2000,
                'reason': '테스트 코인 지급',
              })
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _balance = (res['balance'] as num?)?.toInt() ?? _balance;
        _grantingTestCoins = false;
      });
      _showToast('🪙 2000코인 지급 완료!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _grantingTestCoins = false);
      _showToast('코인 지급 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowCozy.stone50,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: ChowCozy.stone500),
                        )
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _loadBalance)
                          : _tab == _Tab.items
                              ? _buildItemsTab()
                              : _buildCoinsTab(),
                ),
              ],
            ),
            if (_toast != null)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: ChowCozy.stone900.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      _toast!,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ChowCozy.stone200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Material(
                color: ChowCozy.stone100,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, size: 20, color: ChowCozy.stone700),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                '코인상점',
                style: ChowPageStyles.title,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 보유 코인 카드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: ChowCozy.stone900,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('🪙', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보유 코인',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_balance ?? 0}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white, height: 1),
                    ),
                  ],
                ),
                const Spacer(),
                // TODO(임시): 테스트 코인 지급용 — 사용 후 제거할 것.
                Material(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _grantingTestCoins ? null : _handleGrantTestCoins,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: _grantingTestCoins
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: ChowCozy.stone900),
                            )
                          : const Text(
                              '+2000 (테스트)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ChowCozy.stone900),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 탭
          Row(
            children: [
              Expanded(child: _TabButton(label: '아이템 구매', selected: _tab == _Tab.items, onTap: () => setState(() => _tab = _Tab.items))),
              const SizedBox(width: 4),
              Expanded(child: _TabButton(label: '코인 충전', selected: _tab == _Tab.coins, onTap: () => setState(() => _tab = _Tab.coins))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _shopItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _shopItems[index];
        return _ShopItemRow(
          item: item,
          busy: _busyItemId == item.id,
          disabled: _busyItemId != null && _busyItemId != item.id,
          onTap: () => _buyItem(item),
        );
      },
    );
  }

  Widget _buildCoinsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text(
          '코인을 충전하고 다양한 아이템을 구매하세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: ChowCozy.mutedForeground),
        ),
        const SizedBox(height: 12),
        for (final pack in _coinPacks) ...[
          _CoinPackRow(pack: pack, onTap: () => _buyCoinPack(pack)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        const Text(
          '구매 금액은 부가세 포함 · 실제 결제는 연동 후 활성화',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: ChowCozy.stone300),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ChowCozy.stone900 : ChowCozy.stone100,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : ChowCozy.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// 태그별 배경/글자색 — 인기(빨강)/할인(초록)/한정(보라)/추천(황토)/최고(남색).
(Color bg, Color fg) _tagColors(String tag) => switch (tag) {
  '인기' => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
  '할인' => (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
  '한정' => (const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
  '추천' => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
  '최고' => (const Color(0xFFE0E7FF), const Color(0xFF4F46E5)),
  _ => (ChowCozy.stone100, ChowCozy.stone600),
};

class _ShopItemRow extends StatelessWidget {
  const _ShopItemRow({required this.item, required this.busy, required this.disabled, required this.onTap});
  final _ShopItem item;
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: ChowCozy.stone50, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ChowCozy.stone900),
                      ),
                    ),
                    if (item.tag != null) ...[
                      const SizedBox(width: 6),
                      _Tag(text: item.tag!),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.desc, style: const TextStyle(fontSize: 11, color: ChowCozy.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: ChowCozy.stone900,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: disabled || busy ? null : onTap,
              child: Container(
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 10)),
                          const SizedBox(height: 1),
                          Text(
                            '${item.price}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tagColors(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

class _CoinPackRow extends StatelessWidget {
  const _CoinPackRow({required this.pack, required this.onTap});
  final _CoinPack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final featured = pack.tag == '추천';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: featured ? ChowCozy.stone900 : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: featured ? const Color(0xFFFBBF24) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('🪙', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${pack.total}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: featured ? Colors.white : ChowCozy.stone900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('코인', style: TextStyle(fontSize: 11, color: featured ? Colors.white70 : ChowCozy.mutedForeground)),
                      ],
                    ),
                    if (pack.bonus != null)
                      Text(
                        '+${pack.bonus} 보너스 포함',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF22C55E)),
                      ),
                  ],
                ),
              ),
              Material(
                color: featured ? const Color(0xFFFBBF24) : ChowCozy.stone900,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      pack.won,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: featured ? ChowCozy.stone900 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (pack.tag != null)
          Positioned(
            top: -10,
            left: 20,
            child: Builder(
              builder: (context) {
                final (bg, fg) = switch (pack.tag) {
                  '추천' => (const Color(0xFFFBBF24), ChowCozy.stone900),
                  '인기' => (const Color(0xFFEF4444), Colors.white),
                  '최고' => (const Color(0xFF6366F1), Colors.white),
                  _ => (ChowCozy.stone300, ChowCozy.stone700),
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    pack.tag!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
                  ),
                );
              },
            ),
          ),
      ],
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
            const Icon(Icons.storefront_outlined, size: 58, color: ChowCozy.stone300),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: ChowCozy.mutedForeground)),
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
