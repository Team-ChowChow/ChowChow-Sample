import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import 'chow_network_image.dart';

/// 재료명으로 쿠팡 최저가를 검색해 보여주는 바텀시트.
void showLowestPriceSheet(BuildContext context, String ingredientName) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _LowestPriceSheet(ingredientName: ingredientName),
  );
}

class _LowestPriceSheet extends StatefulWidget {
  const _LowestPriceSheet({required this.ingredientName});

  final String ingredientName;

  @override
  State<_LowestPriceSheet> createState() => _LowestPriceSheetState();
}

enum _SheetStatus { loading, result, empty, error }

class _LowestPriceSheetState extends State<_LowestPriceSheet> {
  _SheetStatus _status = _SheetStatus.loading;
  LowestPriceModel? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _SheetStatus.loading);
    try {
      final res = await ApiClient.get(
        '/api/v1/ingredients/lowest-price',
        auth: false,
        query: {'name': widget.ingredientName},
      ) as Map<String, dynamic>;
      final model = LowestPriceModel.fromJson(res);
      if (!mounted) return;
      setState(() {
        _result = model;
        _status = model.found ? _SheetStatus.result : _SheetStatus.empty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _SheetStatus.error);
    }
  }

  Future<void> _openProductUrl() async {
    final url = _result?.productUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ChowColors.gray300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.ingredientName} 최저가',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ChowColors.gray900),
          ),
          const SizedBox(height: 4),
          const Text(
            '여러 쇼핑몰 가격을 비교한 최저가예요',
            style: TextStyle(fontSize: 12, color: ChowColors.gray500),
          ),
          const SizedBox(height: 20),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _SheetStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(color: ChowColors.orange500)),
        );
      case _SheetStatus.result:
        return _buildResult();
      case _SheetStatus.empty:
        return _buildMessage(
          icon: Icons.search_off,
          message: '검색 결과를 찾지 못했어요',
        );
      case _SheetStatus.error:
        return _buildMessage(
          icon: Icons.error_outline,
          message: '최저가 조회에 실패했어요',
          showRetry: true,
        );
    }
  }

  Widget _buildResult() {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChowColors.gray50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ChowNetworkImage(
                  url: result.imageUrl ?? '',
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.productName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: ChowColors.gray700, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(result.price ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ChowColors.gray900),
                    ),
                    if (result.mallName != null && result.mallName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          result.mallName!,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ChowColors.orange500,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _openProductUrl,
              child: const Text('구매하러 가기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({required IconData icon, required String message, bool showRetry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: ChowColors.gray400),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(fontSize: 13, color: ChowColors.gray500)),
            if (showRetry) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _load,
                style: TextButton.styleFrom(foregroundColor: ChowColors.orange500),
                child: const Text('다시 시도', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
