// I-Fridge — Cook Screen
// =======================
// Displays recipe recommendations sorted into 5 tiers by ingredient match %.
// Queries recipes + recipe_ingredients from Supabase, compares against the
// user's inventory, and computes a match score.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';

const _demoUserId = '00000000-0000-4000-8000-000000000001';

class CookScreen extends StatefulWidget {
  const CookScreen({super.key});

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  // Recipes grouped by tier key ('1'–'5')
  Map<String, List<Map<String, dynamic>>> _tiers = {};

  static const _tierMeta = [
    (label: 'Perfect', icon: Icons.star, key: '1'),
    (label: 'Discover', icon: Icons.explore, key: '2'),
    (label: 'Almost', icon: Icons.shopping_cart, key: '3'),
    (label: 'Try', icon: Icons.lightbulb, key: '4'),
    (label: 'Global', icon: Icons.language, key: '5'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tierMeta.length, vsync: this);
    _fetchRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────

  Future<void> _fetchRecipes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Get user's inventory ingredient IDs
      final inventoryRows = await client
          .from('inventory_items')
          .select('ingredient_id')
          .eq('user_id', _demoUserId);

      final ownedIds = (inventoryRows as List)
          .map((r) => r['ingredient_id'] as String)
          .toSet();

      // 2. Get all recipes with their ingredients
      final recipeRows = await client
          .from('recipes')
          .select('*, recipe_ingredients(ingredient_id, quantity, unit, is_optional, prep_note, ingredients(display_name_en))');

      // 3. Score each recipe
      final scored = <Map<String, dynamic>>[];
      for (final recipe in (recipeRows as List)) {
        final ri = (recipe['recipe_ingredients'] as List?) ?? [];
        final requiredIngredients =
            ri.where((r) => r['is_optional'] != true).toList();
        final totalRequired = requiredIngredients.length;
        if (totalRequired == 0) continue;

        final matchedCount = requiredIngredients
            .where((r) => ownedIds.contains(r['ingredient_id']))
            .length;
        final matchPct = matchedCount / totalRequired;

        // Missing ingredient names
        final missing = requiredIngredients
            .where((r) => !ownedIds.contains(r['ingredient_id']))
            .map((r) {
          final ing = r['ingredients'] as Map<String, dynamic>?;
          return ing?['display_name_en'] ?? 'unknown';
        }).toList();

        scored.add({
          'title': recipe['title'],
          'description': recipe['description'],
          'cuisine': recipe['cuisine'] ?? '',
          'difficulty': recipe['difficulty'] ?? 1,
          'prep_time_minutes': recipe['prep_time_minutes'],
          'cook_time_minutes': recipe['cook_time_minutes'],
          'servings': recipe['servings'],
          'tags': (recipe['tags'] as List?)?.cast<String>() ?? [],
          'match_pct': matchPct,
          'matched': matchedCount,
          'total': totalRequired,
          'missing': missing,
        });
      }

      // 4. Sort into tiers
      scored.sort((a, b) =>
          (b['match_pct'] as double).compareTo(a['match_pct'] as double));

      final Map<String, List<Map<String, dynamic>>> tiers = {
        '1': [], '2': [], '3': [], '4': [], '5': [],
      };

      for (final r in scored) {
        final pct = r['match_pct'] as double;
        if (pct >= 1.0) {
          tiers['1']!.add(r);
        } else if (pct >= 0.8) {
          tiers['2']!.add(r);
        } else if (pct >= 0.6) {
          tiers['3']!.add(r);
        } else if (pct >= 0.4) {
          tiers['4']!.add(r);
        } else {
          tiers['5']!.add(r);
        }
      }

      setState(() {
        _tiers = tiers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 140,
            backgroundColor: AppTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'What to Cook?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.3),
                      AppTheme.background,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchRecipes,
                tooltip: 'Refresh',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.accent,
              labelColor: AppTheme.accent,
              unselectedLabelColor: Colors.white54,
              tabAlignment: TabAlignment.start,
              tabs: _tierMeta
                  .map((t) => Tab(icon: Icon(t.icon, size: 18), text: t.label))
                  .toList(),
            ),
          ),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            SizedBox(height: 16),
            Text('Finding recipes...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off,
                  size: 64, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text('Couldn\'t load recipes',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Check your connection and try again.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _fetchRecipes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children:
          _tierMeta.map((t) => _buildTierList(t.key, t.label)).toList(),
    );
  }

  Widget _buildTierList(String tierKey, String tierLabel) {
    final recipes = _tiers[tierKey] ?? [];

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu,
                size: 56, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No $tierLabel recipes yet',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
            const SizedBox(height: 6),
            Text('Add items to your shelf to get recommendations',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRecipes,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recipes.length,
        itemBuilder: (context, index) =>
            _RecipeCard(recipe: recipes[index], tierKey: tierKey),
      ),
    );
  }
}

// ── Recipe Card Widget ─────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final String tierKey;

  const _RecipeCard({required this.recipe, required this.tierKey});

  Color get _tierColor {
    switch (tierKey) {
      case '1':
        return AppTheme.tierGold;
      case '2':
        return AppTheme.tierSilver;
      case '3':
        return AppTheme.tierBronze;
      case '4':
        return const Color(0xFF6C757D);
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = recipe['title'] ?? 'Untitled';
    final description = recipe['description'] ?? '';
    final matchPct = ((recipe['match_pct'] ?? 0.0) as double) * 100;
    final matched = recipe['matched'] ?? 0;
    final total = recipe['total'] ?? 0;
    final missing = (recipe['missing'] as List?) ?? [];
    final cuisine = recipe['cuisine'] ?? '';
    final prepTime = recipe['prep_time_minutes'];
    final cookTime = recipe['cook_time_minutes'];
    final difficulty = recipe['difficulty'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tierColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: _tierColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matchPct.toInt()}%',
                    style: TextStyle(
                        color: _tierColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13)),
            ],

            const SizedBox(height: 10),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.inventory_2,
                  label: '$matched/$total ingredients',
                  color: matchPct >= 100 ? AppTheme.freshGreen : Colors.orange,
                ),
                if (cuisine.isNotEmpty)
                  _InfoChip(
                      icon: Icons.public, label: cuisine, color: Colors.white54),
                if (prepTime != null)
                  _InfoChip(
                      icon: Icons.timer,
                      label: cookTime != null
                          ? '${prepTime + cookTime} min'
                          : '$prepTime min',
                      color: Colors.white54),
                _InfoChip(
                  icon: Icons.signal_cellular_alt,
                  label: '⚡' * (difficulty as int),
                  color: Colors.white54,
                ),
              ],
            ),

            // Missing ingredients
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Need: ${missing.join(", ")}',
                        style:
                            const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
