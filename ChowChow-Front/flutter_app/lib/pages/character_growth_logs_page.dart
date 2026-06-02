import 'package:flutter/material.dart';

import '../services/character_service.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';

class CharacterGrowthLogsPage extends StatefulWidget {
  const CharacterGrowthLogsPage({super.key, required this.characterId});

  final int characterId;

  @override
  State<CharacterGrowthLogsPage> createState() => _CharacterGrowthLogsPageState();
}

class _CharacterGrowthLogsPageState extends State<CharacterGrowthLogsPage> {
  static const _filters = [
    ('ALL', '전체'),
    ('FEED', '밥주기'),
    ('PET', '쓰다듬기'),
    ('EXERCISE', '운동하기'),
    ('BATH', '목욕시키기'),
    ('LEVEL_UP', '레벨업'),
  ];

  String _filter = 'ALL';
  List<GrowthLogModel> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final logs = await CharacterService.fetchGrowthLogs(
        widget.characterId,
        filter: _filter == 'ALL' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('불러오기 실패: $e')));
    }
  }

  static String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}.$m.$day';
  }

  Map<String, List<GrowthLogModel>> _groupByDate() {
    final map = <String, List<GrowthLogModel>>{};
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    for (final log in _logs) {
      final d = log.createdAt;
      if (d == null) continue;
      String key;
      if (d.year == today.year && d.month == today.month && d.day == today.day) {
        key = '${_dateKey(d)} (오늘)';
      } else if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
        key = '${_dateKey(d)} (어제)';
      } else {
        key = _dateKey(d);
      }
      map.putIfAbsent(key, () => []).add(log);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    return Scaffold(
      appBar: AppBar(title: const Text('성장 기록')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _filters[i];
                final selected = _filter == value;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _filter = value);
                    _load();
                  },
                  selectedColor: ChowColors.orange100,
                  checkmarkColor: ChowColors.orange600,
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ChowColors.orange500))
                : _logs.isEmpty
                    ? const Center(
                        child: Text('아직 성장 기록이 없습니다', style: TextStyle(color: ChowColors.gray500, fontSize: 16)),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: ChowColors.orange500,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final entry in grouped.entries) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8, top: 8),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: ChowColors.gray700),
                                ),
                              ),
                              ...entry.value.map((log) => _GrowthLogCard(log: log)),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _GrowthLogCard extends StatelessWidget {
  const _GrowthLogCard({required this.log});

  final GrowthLogModel log;

  IconData get _icon {
    if (log.levelUp) return Icons.star;
    return switch (log.activityType) {
      'FEED' => Icons.restaurant,
      'PET' => Icons.favorite,
      'EXERCISE' => Icons.fitness_center,
      'BATH' => Icons.shower,
      _ => Icons.history,
    };
  }

  String _time() {
    final t = log.createdAt;
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: ChowColors.gray200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: ChowColors.orange50,
              child: Icon(_icon, size: 20, color: ChowColors.orange500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_time(), style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(log.activityLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (!log.levelUp && log.expGained > 0)
                        Text('+${log.expGained} EXP', style: const TextStyle(color: ChowColors.green500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (log.levelUp && log.previousLevel != null && log.newLevel != null)
                    Text('레벨 ${log.previousLevel} → 레벨 ${log.newLevel}', style: const TextStyle(fontSize: 13, color: ChowColors.gray600))
                  else if (log.statusChanges != null && log.statusChanges!.isNotEmpty)
                    Text(log.statusChanges!, style: const TextStyle(fontSize: 13, color: ChowColors.gray500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
