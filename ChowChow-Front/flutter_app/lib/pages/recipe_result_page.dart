import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';
import '../widgets/chow_network_image.dart';

class RecipeResultPage extends StatefulWidget {
  const RecipeResultPage({super.key});

  @override
  State<RecipeResultPage> createState() => _RecipeResultPageState();
}

class _RecipeResultPageState extends State<RecipeResultPage>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;

  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  final _RecipeData recipe = const _RecipeData(
    title: '초코를 위한 닭가슴살 고구마 영양밥',
    subtitle: '저지방, 고단백 건강 레시피',
    image:
        'https://images.unsplash.com/photo-1588378898429-6950f6b4f72a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixlib=rb-4.1.0&q=80&w=1080',
    cookTime: '25분',
    servings: '2인분',
    difficulty: '쉬움',
    calories: '180kcal',
    tags: ['저지방', '다이어트', '알러지 프리'],
    petName: '초코',
    petWeight: '28kg',
    petAllergies: ['닭고기', '밀'],
    nutrition: [
      _NutritionItem(label: '단백질', value: '25g', percent: 85),
      _NutritionItem(label: '탄수화물', value: '15g', percent: 50),
      _NutritionItem(label: '지방', value: '5g', percent: 25),
      _NutritionItem(label: '섬유질', value: '3g', percent: 60),
    ],
    ingredients: [
      _IngredientItem(name: '닭가슴살', amount: '200g', category: '단백질'),
      _IngredientItem(name: '고구마', amount: '150g', category: '탄수화물'),
      _IngredientItem(name: '당근', amount: '50g', category: '채소'),
      _IngredientItem(name: '브로콜리', amount: '50g', category: '채소'),
      _IngredientItem(name: '현미', amount: '100g', category: '탄수화물'),
      _IngredientItem(name: '올리브 오일', amount: '1 tsp', category: '지방'),
    ],
    instructions: [
      _InstructionItem(
        step: 1,
        title: '재료 준비',
        description: '닭가슴살은 깨끗이 씻어 한입 크기로 자르고, 고구마와 당근은 1cm 큐브로 썰어주세요.',
      ),
      _InstructionItem(
        step: 2,
        title: '현미 조리',
        description: '현미는 미리 불려서 압력솥에 넣고 부드럽게 익혀주세요. (약 20분)',
      ),
      _InstructionItem(
        step: 3,
        title: '채소 익히기',
        description: '고구마와 당근을 찜기에 넣고 부드러워질 때까지 쪄주세요. (약 10분)',
      ),
      _InstructionItem(
        step: 4,
        title: '닭가슴살 조리',
        description: '팬에 올리브 오일을 두르고 닭가슴살을 완전히 익을 때까지 볶아주세요.',
      ),
      _InstructionItem(
        step: 5,
        title: '브로콜리 데치기',
        description: '브로콜리는 끓는 물에 2분간 데쳐서 부드럽게 만들어주세요.',
      ),
      _InstructionItem(
        step: 6,
        title: '혼합 및 완성',
        description: '모든 재료를 골고루 섞고 식힌 후 반려동물에게 급여하세요.',
      ),
    ],
    tips: [
      '처음 급여 시에는 소량으로 시작해서 반응을 관찰해주세요.',
      '한 끼 분량씩 소분해서 냉동 보관하면 최대 2주까지 보관 가능합니다.',
      '닭가슴살 대신 다른 단백질(소고기, 연어 등)로 대체 가능합니다.',
      '강아지의 체중에 따라 양을 조절해주세요.',
    ],
    warnings: [
      '양파, 마늘, 포도는 절대 사용하지 마세요.',
      '간을 하지 않은 음식을 급여해주세요.',
      '뜨거운 음식은 충분히 식혀서 제공하세요.',
    ],
  );

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleSaved() {
    setState(() => _isSaved = !_isSaved);
    _heartController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSuccessBanner(),
                        _buildRecipeImage(),
                        _buildTitleSection(),
                        _buildPetInfoSection(),
                        _buildNutritionSection(),
                        _buildIngredientsSection(),
                        _buildInstructionsSection(),
                        _buildTipsSection(),
                        _buildWarningsSection(),
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back,
            size: 24,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                '레시피 결과',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.share_outlined,
                size: 20,
                onTap: () {},
              ),
              _HeaderIconButton(
                icon: Icons.print_outlined,
                size: 20,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF22C55E),
            Color(0xFF4ADE80),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '레시피가 완성되었어요!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${recipe.petName}를 위한 맞춤 레시피',
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: 256,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Colors.white),
      child: ChowNetworkImage(url: recipe.image),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ScaleTransition(
                scale: _heartScale,
                child: Material(
                  color: _isSaved
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF3F4F6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggleSaved,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        _isSaved ? Icons.favorite : Icons.favorite_border,
                        color: _isSaved
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF4B5563),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipe.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Color(0xFFEA580C),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF3F4F6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoStat(
                  icon: Icons.schedule,
                  label: '조리시간',
                  value: recipe.cookTime,
                ),
              ),
              Expanded(
                child: _InfoStat(
                  icon: Icons.group_outlined,
                  label: '분량',
                  value: recipe.servings,
                ),
              ),
              Expanded(
                child: _InfoStat(
                  icon: Icons.restaurant_menu,
                  label: '난이도',
                  value: recipe.difficulty,
                ),
              ),
              Expanded(
                child: _InfoStat(
                  emoji: '🔥',
                  label: '칼로리',
                  value: recipe.calories,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        border: Border(
          left: BorderSide(
            color: Color(0xFFF97316),
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🐕 ${recipe.petName}의 정보',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '체중: ${recipe.petWeight}',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
              ),
              Text(
                '알러지: ${recipe.petAllergies.join(", ")}',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    return _WhiteSection(
      marginTop: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('영양 정보'),
          const SizedBox(height: 16),
          ...recipe.nutrition.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NutritionBar(item: item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return _WhiteSection(
      marginTop: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('재료 (${recipe.ingredients.length}가지)'),
          const SizedBox(height: 12),
          ...recipe.ingredients.asMap().entries.map((entry) {
            final index = entry.key;
            final ingredient = entry.value;
            final isLast = index == recipe.ingredients.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: Color(0xFFF3F4F6),
                          width: 1,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Text(
                    _ingredientEmoji(ingredient.category),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ),
                  Text(
                    ingredient.amount,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return _WhiteSection(
      marginTop: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('조리 방법'),
          const SizedBox(height: 16),
          ...recipe.instructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFB923C),
                          Color(0xFFF97316),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${instruction.step}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instruction.title,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            instruction.description,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return _WhiteSection(
      marginTop: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '💡',
                style: TextStyle(fontSize: 18, height: 1.0),
              ),
              SizedBox(width: 8),
              Text(
                '조리 팁',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recipe.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFFF97316),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFECACA),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFF991B1B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '주의사항',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recipe.warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(
                    color: Color(0xFFD1D5DB),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '다시 생성',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFB923C),
                      Color(0xFFF97316),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22F97316),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go('/'),
                    child: const Center(
                      child: Text(
                        '홈으로 가기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ingredientEmoji(String category) {
    switch (category) {
      case '단백질':
        return '🍖';
      case '탄수화물':
        return '🌾';
      case '채소':
        return '🥕';
      case '지방':
        return '🫒';
      default:
        return '🥣';
    }
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: const Color(0xFF374151),
            size: size,
          ),
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({
    required this.label,
    required this.value,
    this.icon,
    this.emoji,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Icon(
            icon,
            color: const Color(0xFFF97316),
            size: 20,
          )
        else
          Text(
            emoji ?? '',
            style: const TextStyle(fontSize: 18, height: 1.0),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _WhiteSection extends StatelessWidget {
  const _WhiteSection({
    required this.child,
    this.marginTop = 0,
  });

  final Widget child;
  final double marginTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: marginTop),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    );
  }
}

class _NutritionBar extends StatefulWidget {
  const _NutritionBar({required this.item});

  final _NutritionItem item;

  @override
  State<_NutritionBar> createState() => _NutritionBarState();
}

class _NutritionBarState extends State<_NutritionBar> {
  double _widthFactor = 0;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;

      setState(() {
        _widthFactor = widget.item.percent / 100;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              widget.item.label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Text(
              widget.item.value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: const Color(0xFFE5E7EB),
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              widthFactor: _widthFactor,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFB923C),
                      Color(0xFFF97316),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipeData {
  const _RecipeData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.calories,
    required this.tags,
    required this.petName,
    required this.petWeight,
    required this.petAllergies,
    required this.nutrition,
    required this.ingredients,
    required this.instructions,
    required this.tips,
    required this.warnings,
  });

  final String title;
  final String subtitle;
  final String image;
  final String cookTime;
  final String servings;
  final String difficulty;
  final String calories;
  final List<String> tags;
  final String petName;
  final String petWeight;
  final List<String> petAllergies;
  final List<_NutritionItem> nutrition;
  final List<_IngredientItem> ingredients;
  final List<_InstructionItem> instructions;
  final List<String> tips;
  final List<String> warnings;
}

class _NutritionItem {
  const _NutritionItem({
    required this.label,
    required this.value,
    required this.percent,
  });

  final String label;
  final String value;
  final int percent;
}

class _IngredientItem {
  const _IngredientItem({
    required this.name,
    required this.amount,
    required this.category,
  });

  final String name;
  final String amount;
  final String category;
}

class _InstructionItem {
  const _InstructionItem({
    required this.step,
    required this.title,
    required this.description,
  });

  final int step;
  final String title;
  final String description;
}
