import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  bool _searchFocused = false;
  String _query = '';
  String? _petTypeFilter; // 'DOG' | 'CAT' | null

  List<RecipeModel> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _searchFocused = _focusNode.hasFocus));
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text;
      setState(() => _query = q);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), _search);
    });
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final query = <String, String>{'size': '30', 'page': '0'};
      if (_query.isNotEmpty) query['keyword'] = _query;
      if (_petTypeFilter != null) query['petType'] = _petTypeFilter!;

      final res = await ApiClient.get('/api/v1/recipes/search', query: query) as Map<String, dynamic>;
      final list = (res['data'] as List<dynamic>? ?? [])
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _results = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFilter() {
    showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(current: _petTypeFilter),
    ).then((selected) {
      if (selected != null) {
        setState(() => _petTypeFilter = selected == 'ALL' ? null : selected);
        _search();
      }
    });
  }

  bool get _showPopular => _searchFocused && _query.isEmpty;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('레시피 검색', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: '레시피 이름으로 검색...',
                        filled: true,
                        fillColor: ChowColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search, color: ChowColors.gray400),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: ChowColors.gray400),
                                onPressed: () { _searchCtrl.clear(); _search(); },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 필터 버튼 + 펫타입 칩
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(colors: [ChowColors.orange400, ChowColors.orange500]),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _openFilter,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.tune, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('필터', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(label: '전체', active: _petTypeFilter == null, onTap: () { setState(() => _petTypeFilter = null); _search(); }),
                        const SizedBox(width: 6),
                        _FilterChip(label: '🐶 강아지', active: _petTypeFilter == 'DOG', onTap: () { setState(() => _petTypeFilter = 'DOG'); _search(); }),
                        const SizedBox(width: 6),
                        _FilterChip(label: '🐱 고양이', active: _petTypeFilter == 'CAT', onTap: () { setState(() => _petTypeFilter = 'CAT'); _search(); }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _showPopular
                ? _PopularSearches(onPick: (t) { _searchCtrl.text = t; _focusNode.unfocus(); })
                : _SearchResults(results: _results, loading: _loading),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ChowColors.orange500 : ChowColors.gray100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: active ? Colors.white : ChowColors.gray600, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.loading});

  final List<RecipeModel> results;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text('총 ${results.length}개의 레시피', style: const TextStyle(fontSize: 13, color: ChowColors.gray600)),
        const SizedBox(height: 8),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('검색 결과가 없습니다.', style: TextStyle(color: ChowColors.gray500))),
          )
        else
          ...results.map((r) => _RecipeRow(recipe: r)),
      ],
    );
  }
}

class _PopularSearches extends StatelessWidget {
  const _PopularSearches({required this.onPick});

  final void Function(String) onPick;

  static const _terms = ['닭가슴살 레시피', '다이어트 펫푸드', '알레르기 대응식', '강아지 간식', '연어 고구마', '생식 레시피', '저지방 식단', '시니어 건강식'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text('인기 검색어', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._terms.asMap().entries.map((e) => ListTile(
              dense: true,
              leading: Text(
                '${e.key + 1}',
                style: TextStyle(fontWeight: FontWeight.bold, color: e.key < 3 ? ChowColors.orange500 : ChowColors.gray400, fontSize: 13),
              ),
              title: Text(e.value, style: const TextStyle(fontSize: 14, color: ChowColors.gray700)),
              onTap: () => onPick(e.value),
            )),
      ],
    );
  }
}

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe});

  final RecipeModel recipe;

  static const _placeholder =
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=600&q=80';

  @override
  Widget build(BuildContext context) {
    final tags = [
      if (recipe.petType == 'DOG') '🐶 강아지',
      if (recipe.petType == 'CAT') '🐱 고양이',
      if (recipe.menuCategory != null) recipe.menuCategory!,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ChowColors.gray200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: ChowNetworkImage(url: recipe.imageUrl ?? _placeholder),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.recipeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ChowColors.gray900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.recipePurpose ?? recipe.recipeDescription ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: ChowColors.gray500),
                      ),
                      const SizedBox(height: 6),
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ChowColors.orange50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(t, style: const TextStyle(fontSize: 10, color: ChowColors.orange600)),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({this.current});
  final String? current;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: ChowColors.gray200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('맞춤 필터', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('반려동물 종류', style: TextStyle(fontSize: 13, color: ChowColors.gray700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (label, value) in [('전체', null), ('강아지', 'DOG'), ('고양이', 'CAT')])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _selected = value),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _selected == value ? ChowColors.orange500 : null,
                            foregroundColor: _selected == value ? Colors.white : ChowColors.gray700,
                            side: BorderSide(color: _selected == value ? ChowColors.orange500 : ChowColors.gray300),
                          ),
                          child: Text(label, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, 'ALL'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('초기화'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _selected ?? 'ALL'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ChowColors.orange500,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('적용하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
