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

  String _query = '';

  String? _petTypeFilter; // DOG | CAT | ETC | null
  String? _purposeFilter;
  String? _ingredientFilter;

  List<RecipeModel> _results = [];
  bool _loading = false;
  Timer? _debounce;

  final List<String> _popularCategories = const [
    '#트렌드',
    '#저지방',
    '#알러지프리',
    '#시니어',
    '#피부/키트',
    '#다이어트',
    '#치아건강',
    '#면역력',
  ];

  @override
  void initState() {
    super.initState();

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
      final query = <String, String>{
        'size': '30',
        'page': '0',
      };

      if (_query.trim().isNotEmpty) {
        query['keyword'] = _query.trim();
      }

      if (_petTypeFilter != null) {
        query['petType'] = _petTypeFilter!;
      }

      if (_purposeFilter != null) {
        query['purpose'] = _purposeFilter!;
      }

      if (_ingredientFilter != null) {
        query['ingredient'] = _ingredientFilter!;
      }

      final res = await ApiClient.get(
        '/api/v1/recipes/search',
        query: query,
      ) as Map<String, dynamic>;

      final list = (res['data'] as List<dynamic>? ?? [])
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openFilter() {
    showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        return _FilterBottomSheet(
          petType: _petTypeFilter,
          purpose: _purposeFilter,
          ingredient: _ingredientFilter,
        );
      },
    ).then((result) {
      if (result == null) return;

      setState(() {
        _petTypeFilter = result.petType;
        _purposeFilter = result.purpose;
        _ingredientFilter = result.ingredient;
      });

      _search();
    });
  }

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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '레시피 검색',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: ChowColors.gray900,
                          ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ChowColors.gray800,
                        ),
                        decoration: InputDecoration(
                          hintText: '오리 이름으로도 검색...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: ChowColors.gray500,
                          ),
                          filled: true,
                          fillColor: ChowColors.gray50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: ChowColors.gray400,
                            size: 20,
                          ),
                          contentPadding: EdgeInsets.zero,
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: ChowColors.gray400,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _search();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF8A00),
                              Color(0xFFFF6B00),
                            ],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _openFilter,
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_alt_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '우리 아이 맞춤 필터',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: ChowColors.gray200,
                      ),
                    ),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '인기 카테고리',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ChowColors.gray900,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: _popularCategories
                          .map(
                            (label) => _PopularCategoryChip(
                              label: label,
                              onTap: () {
                                final keyword = label.replaceFirst('#', '');
                                _searchCtrl.text = keyword;
                                setState(() => _query = keyword);
                                _search();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _SearchResults(
              results: _results,
              loading: _loading,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularCategoryChip extends StatelessWidget {
  const _PopularCategoryChip({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: ChowColors.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: const TextStyle(
              color: ChowColors.gray600,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.loading,
  });

  final List<RecipeModel> results;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
      children: [
        Row(
          children: [
            Text(
              '총 ${results.length}개의 레시피',
              style: const TextStyle(
                fontSize: 12,
                color: ChowColors.gray700,
              ),
            ),
            const Spacer(),
            const Text(
              '인기순',
              style: TextStyle(
                fontSize: 12,
                color: ChowColors.orange500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '|',
              style: TextStyle(
                fontSize: 12,
                color: ChowColors.gray300,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '최신순',
              style: TextStyle(
                fontSize: 12,
                color: ChowColors.gray500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                '검색 결과가 없습니다.',
                style: TextStyle(color: ChowColors.gray500),
              ),
            ),
          )
        else
          ...results.map((recipe) => _RecipeRow(recipe: recipe)),
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
      if (recipe.petType == 'DOG') '#강아지',
      if (recipe.petType == 'CAT') '#고양이',
      if (recipe.menuCategory != null) '#${recipe.menuCategory!}',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: ChowNetworkImage(
                      url: recipe.imageUrl ?? _placeholder,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 78,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.recipeTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: ChowColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.recipePurpose ??
                              recipe.recipeDescription ??
                              '주재료: 닭가슴살, 고구마, ...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: ChowColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (tags.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: tags
                                .take(2)
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ChowColors.orange50,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: ChowColors.orange600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 13,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 10,
                                color: ChowColors.gray700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              '(234)',
                              style: TextStyle(
                                fontSize: 10,
                                color: ChowColors.gray500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.person,
                              size: 13,
                              color: ChowColors.gray500,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '멍랑이엄마',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: ChowColors.gray600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _FilterResult {
  const _FilterResult({
    this.petType,
    this.purpose,
    this.ingredient,
  });

  final String? petType;
  final String? purpose;
  final String? ingredient;
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    this.petType,
    this.purpose,
    this.ingredient,
  });

  final String? petType;
  final String? purpose;
  final String? ingredient;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _petType;
  late String? _purpose;
  late String? _ingredient;

  @override
  void initState() {
    super.initState();
    _petType = widget.petType;
    _purpose = widget.purpose;
    _ingredient = widget.ingredient;
  }

  void _reset() {
    setState(() {
      _petType = null;
      _purpose = null;
      _ingredient = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _FilterResult(
        petType: _petType,
        purpose: _purpose,
        ingredient: _ingredient,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '맞춤 필터',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: ChowColors.gray900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color: ChowColors.gray500,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              _buildFilterTitle('반려동물 종류'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _FilterChoiceButton(
                      label: '강아지',
                      selected: _petType == 'DOG',
                      onTap: () => setState(() => _petType = 'DOG'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _FilterChoiceButton(
                      label: '고양이',
                      selected: _petType == 'CAT',
                      onTap: () => setState(() => _petType = 'CAT'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _FilterChoiceButton(
                      label: '기타',
                      selected: _petType == 'ETC',
                      onTap: () => setState(() => _petType = 'ETC'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _buildFilterTitle('식단 목적'),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterPill(
                    label: '다이어트',
                    selected: _purpose == '다이어트',
                    onTap: () => setState(() => _purpose = '다이어트'),
                  ),
                  _FilterPill(
                    label: '알러지',
                    selected: _purpose == '알러지',
                    onTap: () => setState(() => _purpose = '알러지'),
                  ),
                  _FilterPill(
                    label: '시니어',
                    selected: _purpose == '시니어',
                    onTap: () => setState(() => _purpose = '시니어'),
                  ),
                  _FilterPill(
                    label: '성장기',
                    selected: _purpose == '성장기',
                    onTap: () => setState(() => _purpose = '성장기'),
                  ),
                  _FilterPill(
                    label: '면역력',
                    selected: _purpose == '면역력',
                    onTap: () => setState(() => _purpose = '면역력'),
                  ),
                  _FilterPill(
                    label: '피부/털',
                    selected: _purpose == '피부/털',
                    onTap: () => setState(() => _purpose = '피부/털'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _buildFilterTitle('주재료'),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterPill(
                    label: '닭고기',
                    selected: _ingredient == '닭고기',
                    onTap: () => setState(() => _ingredient = '닭고기'),
                  ),
                  _FilterPill(
                    label: '소고기',
                    selected: _ingredient == '소고기',
                    onTap: () => setState(() => _ingredient = '소고기'),
                  ),
                  _FilterPill(
                    label: '연어',
                    selected: _ingredient == '연어',
                    onTap: () => setState(() => _ingredient = '연어'),
                  ),
                  _FilterPill(
                    label: '참치',
                    selected: _ingredient == '참치',
                    onTap: () => setState(() => _ingredient = '참치'),
                  ),
                  _FilterPill(
                    label: '오리',
                    selected: _ingredient == '오리',
                    onTap: () => setState(() => _ingredient = '오리'),
                  ),
                  _FilterPill(
                    label: '양고기',
                    selected: _ingredient == '양고기',
                    onTap: () => setState(() => _ingredient = '양고기'),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ChowColors.gray700,
                          side: const BorderSide(
                            color: ChowColors.gray300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '초기화',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '적용하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

  Widget _buildFilterTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ChowColors.gray700,
      ),
    );
  }
}

class _FilterChoiceButton extends StatelessWidget {
  const _FilterChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? ChowColors.orange50 : Colors.white,
          foregroundColor: selected ? ChowColors.orange600 : ChowColors.gray700,
          side: BorderSide(
            color: selected ? ChowColors.orange500 : ChowColors.gray300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? ChowColors.orange50 : Colors.white,
          foregroundColor: selected ? ChowColors.orange600 : ChowColors.gray700,
          side: BorderSide(
            color: selected ? ChowColors.orange500 : ChowColors.gray300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}