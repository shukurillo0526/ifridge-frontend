// I-Fridge — Recipe Detail Screen
// =================================
// Full recipe view with hero header, ingredient checklist,
// and step-by-step cooking instructions.
// Fetches recipe_ingredients and recipe_steps from Supabase.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/core/widgets/shimmer_loading.dart';
import 'package:ifridge_app/core/widgets/slide_in_item.dart';
import 'package:ifridge_app/features/cook/presentation/screens/cooking_run_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final String? description;
  final String? cuisine;
  final int? difficulty;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final double matchPct;
  final Color tierColor;
  final Set<String> ownedIngredientIds;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.title,
    this.description,
    this.cuisine,
    this.difficulty,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.matchPct = 0,
    required this.tierColor,
    required this.ownedIngredientIds,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch ingredients with their display names
      final ingredientRows = await supabase
          .from('recipe_ingredients')
          .select('*, ingredients(id, display_name_en, category)')
          .eq('recipe_id', widget.recipeId)
          .order('is_optional', ascending: true);

      // Fetch cooking steps
      final stepRows = await supabase
          .from('recipe_steps')
          .select()
          .eq('recipe_id', widget.recipeId)
          .order('step_number', ascending: true);

      setState(() {
        _ingredients = List<Map<String, dynamic>>.from(ingredientRows);
        _steps = List<Map<String, dynamic>>.from(stepRows);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int get _totalTime => (widget.prepTime ?? 0) + (widget.cookTime ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.tierColor.withValues(alpha: 0.4),
                      AppTheme.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 16, 20, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Match badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.tierColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.tierColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${(widget.matchPct * 100).toInt()}% Match',
                            style: TextStyle(
                              color: widget.tierColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        if (widget.description != null &&
                            widget.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Quick Info Chips ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (widget.cuisine != null && widget.cuisine!.isNotEmpty)
                    _QuickChip(icon: Icons.public, label: widget.cuisine!),
                  if (_totalTime > 0)
                    _QuickChip(icon: Icons.timer, label: '$_totalTime min'),
                  if (widget.servings != null)
                    _QuickChip(
                      icon: Icons.people,
                      label: '${widget.servings} servings',
                    ),
                  if (widget.difficulty != null)
                    _QuickChip(
                      icon: Icons.signal_cellular_alt,
                      label: '${'⚡' * widget.difficulty!} Difficulty',
                    ),
                ],
              ),
            ),
          ),

          // ── Loading / Content ────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(child: RecipeListSkeleton())
          else ...[
            // ── Ingredients Section ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.checklist,
                      color: IFridgeTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ingredients (${_ingredients.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ing = _ingredients[index];
                  final ingData = ing['ingredients'] as Map<String, dynamic>?;
                  final name = ingData?['display_name_en'] ?? 'Unknown';
                  final ingId = ingData?['id'] ?? '';
                  final qty = ing['quantity'];
                  final unit = ing['unit'] ?? '';
                  final isOptional = ing['is_optional'] == true;
                  final prepNote = ing['prep_note'] ?? '';
                  final isOwned = widget.ownedIngredientIds.contains(ingId);

                  return SlideInItem(
                    delay: index * 50,
                    child: _IngredientRow(
                      name: name,
                      quantity: '$qty $unit',
                      prepNote: prepNote,
                      isOptional: isOptional,
                      isOwned: isOwned,
                    ),
                  );
                }, childCount: _ingredients.length),
              ),
            ),

            // ── Steps Section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      color: widget.tierColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cooking Steps (${_steps.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_steps.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_fix_high,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No steps available yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final step = _steps[index];
                    final isLast = index == _steps.length - 1;
                    return SlideInItem(
                      delay: (_ingredients.length + index) * 50,
                      child: _StepCard(
                        stepNumber: step['step_number'] ?? (index + 1),
                        humanText: step['human_text'] ?? '',
                        estimatedSeconds: step['estimated_seconds'],
                        requiresAttention: step['requires_attention'] == true,
                        tierColor: widget.tierColor,
                        isLast: isLast,
                      ),
                    );
                  }, childCount: _steps.length),
                ),
              ),

            // ── Bottom spacing ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _steps.isNotEmpty
          ? SlideInItem(
              delay: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CookingRunScreen(
                            recipeId: widget.recipeId,
                            title: widget.title,
                            steps: _steps,
                            matchedIngredientsCount:
                                widget.ownedIngredientIds.length,
                            matchPct: widget.matchPct,
                          ),
                        ),
                      );
                    },
                    backgroundColor: IFridgeTheme.primary,
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Start Cooking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Quick Info Chip ─────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Ingredient Row ──────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final String name;
  final String quantity;
  final String prepNote;
  final bool isOptional;
  final bool isOwned;

  const _IngredientRow({
    required this.name,
    required this.quantity,
    required this.prepNote,
    required this.isOptional,
    required this.isOwned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwned
              ? IFridgeTheme.freshGreen.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Owned / Missing indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isOwned
                  ? IFridgeTheme.freshGreen.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOwned ? Icons.check : Icons.shopping_cart_outlined,
              size: 16,
              color: isOwned ? IFridgeTheme.freshGreen : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          // Name + prep note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOptional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'optional',
                          style: TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
                if (prepNote.isNotEmpty)
                  Text(
                    prepNote,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Quantity
          Text(
            quantity,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Card ───────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String humanText;
  final int? estimatedSeconds;
  final bool requiresAttention;
  final Color tierColor;
  final bool isLast;

  const _StepCard({
    required this.stepNumber,
    required this.humanText,
    this.estimatedSeconds,
    required this.requiresAttention,
    required this.tierColor,
    required this.isLast,
  });

  String get _timeLabel {
    if (estimatedSeconds == null) return '';
    if (estimatedSeconds! < 60) return '${estimatedSeconds}s';
    final min = estimatedSeconds! ~/ 60;
    final sec = estimatedSeconds! % 60;
    return sec > 0 ? '${min}m ${sec}s' : '${min}m';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: tierColor.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Step content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    humanText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_timeLabel.isNotEmpty) ...[
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: requiresAttention
                              ? Colors.orange.withValues(alpha: 0.1)
                              : IFridgeTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              requiresAttention ? '👨‍🍳' : '🤖',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              requiresAttention ? 'Hands-on' : 'Automatic',
                              style: TextStyle(
                                color: requiresAttention
                                    ? Colors.orange
                                    : IFridgeTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }
}
