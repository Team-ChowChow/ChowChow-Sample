import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/character_service.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  List<CharacterModel> _characters = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CharacterService.fetchCharacters();
      if (!mounted) return;
      setState(() {
        _characters = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(CharacterModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('캐릭터 삭제'),
        content: Text('${c.characterName}을(를) 삭제할까요?\n삭제 후에는 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ChowColors.red500),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await CharacterService.deleteCharacter(c.characterId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캐릭터가 삭제되었습니다.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  void _openRaise(CharacterModel c) {
    debugPrint('🎮 Opening 캐릭터 키우기 page for characterId: ${c.characterId}');
    context.push('/character/${c.characterId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '캐릭터 키우기',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ChowColors.gray800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '캐릭터 관리',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ChowColors.gray700),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '내 캐릭터 ${_characters.length}마리',
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(fontSize: 13, color: ChowColors.gray500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh, color: ChowColors.gray600),
                        tooltip: '새로고침',
                        visualDensity: VisualDensity.compact,
                      ),
                      FilledButton(
                        onPressed: () async {
                          final created = await context.push<bool>('/character/new');
                          if (created == true) _load();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: ChowCozy.stone500,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          visualDensity: VisualDensity.compact,
                          alignment: Alignment.center,
                        ),
                        child: const Text('+ 새 캐릭터 생성', maxLines: 1, softWrap: false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: ChowCozy.stone500))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ChowColors.gray600)),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _load, child: const Text('다시 시도')),
                            ],
                          ),
                        )
                      : _characters.isEmpty
                          ? _EmptyState(
                              onCreate: () async {
                                final created = await context.push<bool>('/character/new');
                                if (created == true) _load();
                              },
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: ChowCozy.stone500,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _characters.length,
                                itemBuilder: (_, i) {
                                  final c = _characters[i];
                                  return _CharacterCard(
                                    character: c,
                                    onTap: () => _openRaise(c),
                                    onRaise: () => _openRaise(c),
                                    onEdit: () async {
                                      final updated = await context.push<bool>('/character/${c.characterId}/edit');
                                      if (updated == true) _load();
                                    },
                                    onDelete: () => _confirmDelete(c),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 64, color: ChowColors.gray300),
            const SizedBox(height: 16),
            const Text(
              '아직 생성된 캐릭터가 없습니다',
              style: TextStyle(fontSize: 16, color: ChowColors.gray600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('새 캐릭터 생성'),
              style: FilledButton.styleFrom(backgroundColor: ChowCozy.stone500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.onRaise,
    required this.onEdit,
    required this.onDelete,
  });

  final CharacterModel character;
  final VoidCallback onTap;
  final VoidCallback onRaise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final img = character.characterImageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ChowColors.gray200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: img != null && img.isNotEmpty
                        ? Transform.scale(
                            scale: character.petType == 'CAT' ? 0.8 : 1.0,
                            child: ClipOval(child: ChowNetworkImage(url: img, fit: BoxFit.cover)),
                          )
                        : const CircleAvatar(
                            radius: 32,
                            backgroundColor: ChowCozy.stone300,
                            child: Icon(Icons.pets, color: ChowCozy.stone500, size: 32),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.characterName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: ChowColors.gray800),
                        ),
                        if (character.typeBreedLine.isNotEmpty)
                          Text(
                            character.typeBreedLine,
                            style: const TextStyle(fontSize: 13, color: ChowColors.gray500),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ChowCozy.stone300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '레벨 ${character.level}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChowCozy.stone700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'EXP ${character.exp} / ${character.requiredExp}',
                    style: const TextStyle(fontSize: 12, color: ChowColors.gray600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: character.expFraction,
                  minHeight: 6,
                  backgroundColor: ChowColors.gray200,
                  color: ChowCozy.stone500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(icon: Icons.favorite, label: '건강', value: character.health, color: ChowColors.red500),
                  _StatChip(icon: Icons.auto_awesome, label: '행복', value: character.happiness, color: ChowColors.yellow500),
                  _StatChip(icon: Icons.restaurant, label: '배고픔', value: character.hunger, color: ChowCozy.stone500),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onRaise,
                      style: FilledButton.styleFrom(
                        backgroundColor: ChowCozy.stone500,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('키우기', maxLines: 1, softWrap: false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('수정', maxLines: 1, softWrap: false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ChowColors.red500,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('삭제', maxLines: 1, softWrap: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$label $value%', style: const TextStyle(fontSize: 12, color: ChowColors.gray600)),
      ],
    );
  }
}
