import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../services/models.dart';
import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class DietLogPage extends StatefulWidget {
  const DietLogPage({super.key});

  @override
  State<DietLogPage> createState() => _DietLogPageState();
}

class _DietLogPageState extends State<DietLogPage> {
  bool _loadingPets = true;
  List<PetModel> _pets = [];
  PetModel? _selectedPet;

  bool _loadingRecipes = false;
  List<RecipeModel> _recipes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final res = await ApiClient.get('/api/pets') as List<dynamic>;
      if (!mounted) return;
      final pets = res.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _pets = pets;
        _selectedPet = pets.isNotEmpty ? pets.first : null;
        _loadingPets = false;
      });
      if (_selectedPet != null) await _loadRecipes(_selectedPet!.petId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPets = false);
    }
  }

  Future<void> _loadRecipes(int petId) async {
    setState(() {
      _loadingRecipes = true;
      _error = null;
    });
    try {
      final res = await ApiClient.get('/api/v1/recipes/by-pet/$petId') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _recipes = res.map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList();
        _loadingRecipes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '식단 기록을 불러오지 못했어요.';
        _loadingRecipes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('식단 기록')),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? const Center(
                  child: Text('등록된 반려동물이 없어요', style: TextStyle(color: ChowColors.gray500)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<PetModel>(
                        initialValue: _selectedPet,
                        items: _pets
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.petName)))
                            .toList(),
                        onChanged: (p) {
                          if (p == null) return;
                          setState(() => _selectedPet = p);
                          _loadRecipes(p.petId);
                        },
                      ),
                    ),
                    Expanded(
                      child: _loadingRecipes
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(child: Text(_error!, style: const TextStyle(color: ChowColors.red500)))
                              : _recipes.isEmpty
                                  ? const Center(
                                      child: Text(
                                        '아직 만든 식단이 없어요.\nAI 셰프에게 맞춤 레시피를 받아보세요!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: ChowColors.gray500),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      itemCount: _recipes.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                                      itemBuilder: (_, i) {
                                        final recipe = _recipes[i];
                                        return _DietLogCard(
                                          recipe: recipe,
                                          onTap: () => context.push(
                                            '/recipes/${recipe.recipeId}',
                                            extra: recipe,
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
    );
  }
}

class _DietLogCard extends StatelessWidget {
  const _DietLogCard({required this.recipe, required this.onTap});
  final RecipeModel recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ChowCozy.stone300),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: recipe.imageUrl != null
                      ? ChowNetworkImage(url: recipe.imageUrl!, fit: BoxFit.cover)
                      : Container(color: ChowCozy.stone100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.recipeTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe.recipeDescription != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        recipe.recipeDescription!,
                        style: const TextStyle(fontSize: 12, color: ChowColors.gray500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ChowColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
