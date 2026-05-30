import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum _SearchSort { popular, latest }

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';
  bool _searchFocused = false;

  String? _petTypeFilter; // DOG | CAT | ETC | null
  List<String> _purposeFilters = [];
  String? _ingredientFilter;
  _SearchSort _sort = _SearchSort.popular;

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

  final List<_PopularSearchTerm> _popularSearchTerms = const [
    _PopularSearchTerm(rank: 1, keyword: '닭가슴살 레시피'),
    _PopularSearchTerm(rank: 2, keyword: '다이어트 펫푸드', isNew: true),
    _PopularSearchTerm(rank: 3, keyword: '알레르기 대응식'),
    _PopularSearchTerm(rank: 4, keyword: '강아지 간식'),
    _PopularSearchTerm(rank: 5, keyword: '연어 고구마', isNew: true),
    _PopularSearchTerm(rank: 6, keyword: '생식 레시피'),
    _PopularSearchTerm(rank: 7, keyword: '저지방 식단'),
    _PopularSearchTerm(rank: 8, keyword: '시니어 건강식', isNew: true),
    _PopularSearchTerm(rank: 9, keyword: '치킨 야채볼'),
    _PopularSearchTerm(rank: 10, keyword: '면역력 강화'),
  ];

  final List<String> _suggestionSeeds = const [
    '닭고기',
    '소고기',
    '연어',
    '참치',
    '오리',
    '양고기',
    '다이어트',
    '알러지',
    '시니어',
    '면역력',
    '치아건강',
    '강아지',
    '고양이',
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

    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _searchFocused = _focusNode.hasFocus);
      }
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

      if (_purposeFilters.isNotEmpty) {
        query['purpose'] = _purposeFilters.join(',');
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

  List<String> get _popularKeywords {
    return _popularSearchTerms
        .map((term) => term.keyword.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  List<String> get _searchSuggestions {
    final keyword = _query.trim().toLowerCase();
    final pool = <String>{
      ..._popularKeywords,
      ..._suggestionSeeds,
      ..._results.map((recipe) => recipe.recipeTitle),
      ..._results.map((recipe) => recipe.menuCategory ?? ''),
      ..._results.map((recipe) => recipe.recipePurpose ?? ''),
    }.where((item) => item.trim().isNotEmpty).toList();

    if (keyword.isEmpty) {
      return pool.take(8).toList();
    }

    return pool
        .where((item) => item.toLowerCase().contains(keyword))
        .take(8)
        .toList();
  }

  List<RecipeModel> get _sortedResults {
    final sorted = List<RecipeModel>.of(_results);
    if (_sort == _SearchSort.latest) {
      sorted.sort((a, b) => b.recipeId.compareTo(a.recipeId));
    }
    return sorted;
  }

  void _selectKeyword(String keyword) {
    _searchCtrl.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    setState(() => _query = keyword);
    _search();
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
          purposes: _purposeFilters,
          ingredient: _ingredientFilter,
        );
      },
    ).then((result) {
      if (result == null) return;

      setState(() {
        _petTypeFilter = result.petType;
        _purposeFilters = result.purposes;
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

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      height: _searchFocused ? 52 : 43,
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontSize: _searchFocused ? 15 : 13,
                          color: ChowColors.gray800,
                        ),
                        decoration: InputDecoration(
                          hintText: '오리 이름으로도 검색...',
                          hintStyle: TextStyle(
                            fontSize: _searchFocused ? 14 : 13,
                            color: ChowColors.gray500,
                          ),
                          filled: true,
                          fillColor: _searchFocused
                              ? Colors.white
                              : ChowColors.gray50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              _searchFocused ? 15 : 11,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              _searchFocused ? 15 : 11,
                            ),
                            borderSide: BorderSide(
                              color: _searchFocused
                                  ? ChowColors.orange500
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: ChowColors.orange500,
                              width: 1.5,
                            ),
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

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _searchFocused
                          ? _SearchSuggestionPanel(
                              key: ValueKey(_query.trim().isEmpty),
                              title: _query.trim().isEmpty
                                  ? '인기 검색어'
                                  : '자동완성',
                              popularTerms: _popularSearchTerms,
                              suggestions: _searchSuggestions,
                              query: _query,
                              onSelect: _selectKeyword,
                              onClose: () => _focusNode.unfocus(),
                            )
                          : const SizedBox.shrink(),
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

                    if (!_searchFocused) ...[
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
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _SearchResults(
              results: _sortedResults,
              loading: _loading,
              sort: _sort,
              onSortChanged: (sort) {
                setState(() => _sort = sort);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSuggestionPanel extends StatelessWidget {
  const _SearchSuggestionPanel({
    super.key,
    required this.title,
    required this.popularTerms,
    required this.suggestions,
    required this.query,
    required this.onSelect,
    required this.onClose,
  });

  final String title;
  final List<_PopularSearchTerm> popularTerms;
  final List<String> suggestions;
  final String query;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChowColors.orange100),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 4),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasQuery ? Icons.manage_search : Icons.local_fire_department,
                size: 17,
                color: ChowColors.orange500,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ChowColors.gray800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: ChowColors.gray500,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(34, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '닫기',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasQuery)
            _PopularSearchGrid(
              terms: popularTerms,
              onSelect: onSelect,
            )
          else if (suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '추천 검색어가 없습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: ChowColors.gray500,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map(
                    (keyword) => _SuggestionChip(
                      keyword: keyword,
                      hasQuery: hasQuery,
                      onTap: () => onSelect(keyword),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PopularSearchGrid extends StatelessWidget {
  const _PopularSearchGrid({
    required this.terms,
    required this.onSelect,
  });

  final List<_PopularSearchTerm> terms;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: terms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3.5,
      ),
      itemBuilder: (context, index) {
        final term = terms[index];
        return _PopularSearchTile(
          term: term,
          onTap: () => onSelect(term.keyword),
        );
      },
    );
  }
}

class _PopularSearchTile extends StatelessWidget {
  const _PopularSearchTile({
    required this.term,
    required this.onTap,
  });

  final _PopularSearchTerm term;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChowColors.gray50,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '${term.rank}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: term.rank <= 3
                        ? ChowColors.orange500
                        : ChowColors.gray400,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  term.keyword,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChowColors.gray800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              if (term.isNew) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ChowColors.red500,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.keyword,
    required this.hasQuery,
    required this.onTap,
  });

  final String keyword;
  final bool hasQuery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasQuery ? ChowColors.orange50 : ChowColors.gray50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: hasQuery ? ChowColors.orange100 : ChowColors.gray200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasQuery ? Icons.north_west : Icons.tag,
                size: 13,
                color: hasQuery ? ChowColors.orange600 : ChowColors.gray500,
              ),
              const SizedBox(width: 5),
              Text(
                keyword,
                style: TextStyle(
                  color: hasQuery ? ChowColors.orange600 : ChowColors.gray700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularSearchTerm {
  const _PopularSearchTerm({
    required this.rank,
    required this.keyword,
    this.isNew = false,
  });

  final int rank;
  final String keyword;
  final bool isNew;
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
    required this.sort,
    required this.onSortChanged,
  });

  final List<RecipeModel> results;
  final bool loading;
  final _SearchSort sort;
  final ValueChanged<_SearchSort> onSortChanged;

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
            _SortTextButton(
              label: '인기순',
              selected: sort == _SearchSort.popular,
              onTap: () => onSortChanged(_SearchSort.popular),
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
            _SortTextButton(
              label: '최신순',
              selected: sort == _SearchSort.latest,
              onTap: () => onSortChanged(_SearchSort.latest),
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

class _SortTextButton extends StatelessWidget {
  const _SortTextButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? ChowColors.orange500 : ChowColors.gray500,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
          onTap: () => context.push(
            '/recipes/${recipe.recipeId}',
            extra: recipe,
          ),
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
    this.purposes = const [],
    this.ingredient,
  });

  final String? petType;
  final List<String> purposes;
  final String? ingredient;
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    this.petType,
    this.purposes = const [],
    this.ingredient,
  });

  final String? petType;
  final List<String> purposes;
  final String? ingredient;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _petType;
  late Set<String> _purposes;
  late String? _ingredient;

  @override
  void initState() {
    super.initState();
    _petType = widget.petType;
    _purposes = widget.purposes.toSet();
    _ingredient = widget.ingredient;
  }

  void _togglePurpose(String purpose) {
    setState(() {
      if (_purposes.contains(purpose)) {
        _purposes.remove(purpose);
      } else {
        _purposes.add(purpose);
      }
    });
  }

  void _reset() {
    setState(() {
      _petType = null;
      _purposes.clear();
      _ingredient = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _FilterResult(
        petType: _petType,
        purposes: _purposes.toList(),
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
                    selected: _purposes.contains('다이어트'),
                    onTap: () => _togglePurpose('다이어트'),
                  ),
                  _FilterPill(
                    label: '알러지',
                    selected: _purposes.contains('알러지'),
                    onTap: () => _togglePurpose('알러지'),
                  ),
                  _FilterPill(
                    label: '시니어',
                    selected: _purposes.contains('시니어'),
                    onTap: () => _togglePurpose('시니어'),
                  ),
                  _FilterPill(
                    label: '성장기',
                    selected: _purposes.contains('성장기'),
                    onTap: () => _togglePurpose('성장기'),
                  ),
                  _FilterPill(
                    label: '면역력',
                    selected: _purposes.contains('면역력'),
                    onTap: () => _togglePurpose('면역력'),
                  ),
                  _FilterPill(
                    label: '피부/털',
                    selected: _purposes.contains('피부/털'),
                    onTap: () => _togglePurpose('피부/털'),
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
