// I-Fridge — Cook Screen
// =======================
// Displays 5-tier recipe recommendations fetched from the backend.
// Each tier shows recipe cards scored by relevance (expiry urgency,
// flavor affinity, and familiarity).

import 'package:flutter/material.dart';
import 'package:ifridge_app/core/services/api_service.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';

class CookScreen extends StatefulWidget {
  const CookScreen({super.key});

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  // Tier metadata
  static const _tiers = [
    (label: 'Perfect', icon: Icons.star, tier: '1'),
    (label: 'Discover', icon: Icons.explore, tier: '2'),
    (label: 'Almost', icon: Icons.shopping_cart, tier: '3'),
    (label: 'Try', icon: Icons.lightbulb, tier: '4'),
    (label: 'Global', icon: Icons.language, tier: '5'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tiers.length, vsync: this);
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Using a demo user ID — replace with real auth
      final result = await _api.getRecommendations(userId: 'demo-user');
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
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
                onPressed: _fetchRecommendations,
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
              tabs: _tiers.map((t) => Tab(
                icon: Icon(t.icon, size: 18),
                text: t.label,
              )).toList(),
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
            Text(
              'Finding recipes...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return TabBarView(
      controller: _tabController,
      children: _tiers.map((t) => _buildTierList(t.tier, t.label)).toList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Couldn\'t load recommendations',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the database has recipes and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierList(String tierKey, String tierLabel) {
    final tiers = _data?['tiers'] as Map<String, dynamic>? ?? {};
    final recipes = (tiers[tierKey] as List?) ?? [];

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 56,
                color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'No $tierLabel recipes yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Add items to your shelf to get recommendations',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRecommendations,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index] as Map<String, dynamic>;
          return _RecipeCard(recipe: recipe, tierKey: tierKey);
        },
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
      case '1': return AppTheme.tierGold;
      case '2': return AppTheme.tierSilver;
      case '3': return AppTheme.tierBronze;
      case '4': return const Color(0xFF6C757D);
      default:  return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = recipe['title'] ?? 'Untitled';
    final score = (recipe['relevance_score'] ?? 0.0) as num;
    final matchPct = ((recipe['match_percentage'] ?? 0.0) as num) * 100;
    final missing = (recipe['missing_ingredients'] as List?) ?? [];
    final cuisine = recipe['cuisine'] ?? '';
    final prepTime = recipe['prep_time_minutes'];
    final isComfort = recipe['is_comfort'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isComfort)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.tierGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 12,
                            color: AppTheme.tierGold),
                        SizedBox(width: 4),
                        Text('Comfort',
                            style: TextStyle(
                                color: AppTheme.tierGold, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.speed,
                  label: '${(score * 100).toInt()}%',
                  color: _tierColor,
                ),
                _InfoChip(
                  icon: Icons.inventory_2,
                  label: '${matchPct.toInt()}% match',
                  color: matchPct >= 100
                      ? AppTheme.freshGreen
                      : Colors.orange,
                ),
                if (cuisine.isNotEmpty)
                  _InfoChip(
                    icon: Icons.public,
                    label: cuisine,
                    color: Colors.white54,
                  ),
                if (prepTime != null)
                  _InfoChip(
                    icon: Icons.timer,
                    label: '$prepTime min',
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
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
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

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

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
