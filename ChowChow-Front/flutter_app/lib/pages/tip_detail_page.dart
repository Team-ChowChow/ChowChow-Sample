import 'package:flutter/material.dart';
import '../theme/chow_theme.dart';

class TipDetailPage extends StatelessWidget {
  const TipDetailPage({super.key, required this.tip, required this.detail});

  final String tip;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ChowColors.gray800),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('오늘의 팁', style: TextStyle(color: ChowColors.gray800, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [ChowColors.blue500, ChowColors.purple500],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 건강 정보', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(
                    tip,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('상세 내용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ChowColors.gray800)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Text(
                detail,
                style: const TextStyle(fontSize: 15, color: ChowColors.gray700, height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
