import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/character_service.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class CharacterRaisePage extends StatefulWidget {
  const CharacterRaisePage({super.key, required this.characterId});

  final int characterId;

  @override
  State<CharacterRaisePage> createState() => _CharacterRaisePageState();
}

class _CharacterRaisePageState extends State<CharacterRaisePage> {
  CharacterModel? _character;
  List<GrowthLogModel> _recentLogs = [];
  bool _loading = true;
  bool _acting = false;

  static const _activities = [
    _Act('FEED', Icons.restaurant, '밥주기', '+20 EXP', ChowColors.orange500),
    _Act('PET', Icons.favorite, '쓰다듬기', '+5 EXP', ChowColors.pink500),
    _Act('EXERCISE', Icons.fitness_center, '운동하기', '+10 EXP', Color(0xFF3B82F6)),
    _Act('BATH', Icons.shower, '목욕시키기', '+15 EXP', ChowColors.purple500),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        CharacterService.fetchCharacter(widget.characterId),
        CharacterService.fetchGrowthLogs(widget.characterId),
      ]);
      final c = results[0] as CharacterModel;
      final logs = results[1] as List<GrowthLogModel>;
      if (!mounted) return;
      setState(() {
        _character = c;
        _recentLogs = logs.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('불러오기 실패: $e')));
    }
  }

  Future<void> _doActivity(String type) async {
    if (_acting || _character == null) return;
    setState(() => _acting = true);
    final prevLevel = _character!.level;
    try {
      final updated = await CharacterService.performActivity(widget.characterId, type);
      final logs = await CharacterService.fetchGrowthLogs(widget.characterId);
      if (!mounted) return;
      setState(() {
        _character = updated;
        _recentLogs = logs.take(5).toList();
        _acting = false;
      });
      if (updated.level > prevLevel) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 레벨 업! Lv.${updated.level}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('활동 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _character;
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      appBar: AppBar(
        title: Text(c?.characterName ?? '캐릭터 키우기'),
        actions: [
          if (c != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final ok = await context.push<bool>('/character/${c.characterId}/edit');
                if (ok == true) _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ChowColors.orange500))
          : c == null
              ? const Center(child: Text('캐릭터를 찾을 수 없습니다.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: ChowColors.orange500,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileCard(character: c),
                        const SizedBox(height: 16),
                        const Text('활동', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ChowColors.gray800)),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          children: _activities.map((a) {
                            return _ActivityButton(
                              act: a,
                              disabled: _acting,
                              onTap: () => _doActivity(a.type),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '최근 성장 기록',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ChowColors.gray800),
                            ),
                            TextButton(
                              onPressed: () => context.push('/character/${c.characterId}/logs'),
                              child: const Text('더 보기 >'),
                            ),
                          ],
                        ),
                        if (_recentLogs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('아직 성장 기록이 없습니다', style: TextStyle(color: ChowColors.gray500)),
                            ),
                          )
                        else
                          ..._recentLogs.map((log) => _LogTile(log: log)),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.character});

  final CharacterModel character;

  @override
  Widget build(BuildContext context) {
    final img = character.characterImageUrl;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: ChowColors.gray200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (img != null && img.isNotEmpty)
              ClipOval(
                child: SizedBox(width: 120, height: 120, child: ChowNetworkImage(url: img, fit: BoxFit.cover)),
              )
            else
              const CircleAvatar(radius: 60, child: Icon(Icons.pets, size: 48)),
            const SizedBox(height: 12),
            Text(character.characterName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (character.typeBreedLine.isNotEmpty)
              Text(character.typeBreedLine, style: const TextStyle(color: ChowColors.gray500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: ChowColors.orange100, borderRadius: BorderRadius.circular(8)),
              child: Text('레벨 ${character.level}', style: const TextStyle(color: ChowColors.orange600, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EXP ${character.exp} / ${character.requiredExp}'),
                Text('다음 레벨까지 ${character.expToNextLevel} EXP',
                    style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: character.expFraction,
                minHeight: 8,
                backgroundColor: ChowColors.gray200,
                color: ChowColors.orange500,
              ),
            ),
            const SizedBox(height: 16),
            _GaugeRow(label: '건강', value: character.health, color: ChowColors.red500),
            const SizedBox(height: 8),
            _GaugeRow(label: '행복', value: character.happiness, color: ChowColors.yellow500),
            const SizedBox(height: 8),
            _GaugeRow(label: '배고픔', value: character.hunger, color: ChowColors.orange500),
          ],
        ),
      ),
    );
  }
}

class _GaugeRow extends StatelessWidget {
  const _GaugeRow({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: value / 100, minHeight: 8, backgroundColor: ChowColors.gray200, color: color),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value%', style: const TextStyle(fontSize: 12, color: ChowColors.gray600)),
      ],
    );
  }
}

class _Act {
  const _Act(this.type, this.icon, this.label, this.expLabel, this.color);
  final String type;
  final IconData icon;
  final String label;
  final String expLabel;
  final Color color;
}

class _ActivityButton extends StatelessWidget {
  const _ActivityButton({required this.act, required this.onTap, required this.disabled});

  final _Act act;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChowColors.gray200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(act.icon, color: act.color, size: 32),
              const SizedBox(height: 8),
              Text(act.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(act.expLabel, style: TextStyle(fontSize: 12, color: act.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final GrowthLogModel log;

  String _timeStr() {
    final t = log.createdAt;
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_timeStr(), style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(log.activityLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (log.levelUp) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 16, color: ChowColors.yellow500),
                    ],
                    if (!log.levelUp && log.expGained > 0) ...[
                      const SizedBox(width: 8),
                      Text('+${log.expGained} EXP', style: const TextStyle(color: ChowColors.green500, fontSize: 12)),
                    ],
                  ],
                ),
                if (log.levelUp && log.previousLevel != null && log.newLevel != null)
                  Text('레벨 ${log.previousLevel} → 레벨 ${log.newLevel}', style: const TextStyle(fontSize: 12, color: ChowColors.gray600))
                else if (log.statusChanges != null && log.statusChanges!.isNotEmpty)
                  Text(log.statusChanges!, style: const TextStyle(fontSize: 12, color: ChowColors.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
