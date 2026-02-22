// I-Fridge — Profile Screen
// ==========================
// User profile with gamification stats, XP progress,
// earned badges, flavor profile visualization, and settings.
// Loads real data from Supabase tables: users, gamification_stats,
// user_flavor_profile.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/core/widgets/shimmer_loading.dart';
import 'package:ifridge_app/features/gamification/domain/badges.dart' show levelFromXp;

const _demoUserId = '00000000-0000-4000-8000-000000000001';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;

  // User data
  String _userName = 'Chef';
  int _totalXp = 0;
  int _level = 1;

  // Gamification stats
  int _mealsCooked = 0;
  int _itemsSaved = 0;
  int _currentStreak = 0;
  List<Map<String, dynamic>> _badges = [];

  // Flavor profile
  Map<String, double> _flavorValues = {
    'Sweet': 0.5, 'Salty': 0.5, 'Sour': 0.5,
    'Bitter': 0.5, 'Umami': 0.5, 'Spicy': 0.5,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // Parallel queries
      final results = await Future.wait([
        client.from('users').select().eq('id', _demoUserId).maybeSingle(),
        client.from('gamification_stats').select().eq('user_id', _demoUserId).maybeSingle(),
        client.from('user_flavor_profile').select().eq('user_id', _demoUserId).maybeSingle(),
      ]);

      final userData = results[0];
      final statsData = results[1];
      final flavorData = results[2];

      setState(() {
        // User
        _userName = userData?['display_name'] ?? 'Chef';

        // Gamification
        _totalXp = (statsData?['xp_points'] as int?) ?? 0;
        _level = levelFromXp(_totalXp);
        _mealsCooked = (statsData?['total_meals_cooked'] as int?) ?? 0;
        _itemsSaved = (statsData?['items_saved'] as int?) ?? 0;
        _currentStreak = (statsData?['current_streak'] as int?) ?? 0;

        // Badges from JSONB
        final rawBadges = statsData?['badges'];
        if (rawBadges is List) {
          _badges = rawBadges.cast<Map<String, dynamic>>();
        }

        // Flavor profile
        if (flavorData != null) {
          _flavorValues = {
            'Sweet': (flavorData['sweet'] as num?)?.toDouble() ?? 0.5,
            'Salty': (flavorData['salty'] as num?)?.toDouble() ?? 0.5,
            'Sour': (flavorData['sour'] as num?)?.toDouble() ?? 0.5,
            'Bitter': (flavorData['bitter'] as num?)?.toDouble() ?? 0.5,
            'Umami': (flavorData['umami'] as num?)?.toDouble() ?? 0.5,
            'Spicy': (flavorData['spicy'] as num?)?.toDouble() ?? 0.5,
          };
        }

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
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const ProfileSkeleton(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('Couldn\'t load profile',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final nextLevelXp = (_level + 1) * (_level + 1) * 100;
    final progress = _totalXp / nextLevelXp;

    // All possible badges with earned status
    final allBadges = _buildBadgeList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.4),
                      AppTheme.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [IFridgeTheme.primary, IFridgeTheme.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('👨‍🍳', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level $_level • $_totalXp XP',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProfile,
                tooltip: 'Refresh',
              ),
            ],
          ),

          // ── Body ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // XP Progress
                _SectionCard(
                  title: 'Level Progress',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level $_level',
                            style: const TextStyle(
                              color: IFridgeTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$_totalXp / $nextLevelXp XP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.lerp(IFridgeTheme.primary, IFridgeTheme.secondary, value) ?? IFridgeTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Stats
                _SectionCard(
                  title: 'Your Impact',
                  child: Row(
                    children: [
                      _StatTile(
                          value: '$_mealsCooked',
                          label: 'Meals\nCooked',
                          icon: Icons.restaurant),
                      _StatTile(
                          value: '$_itemsSaved',
                          label: 'Items\nSaved',
                          icon: Icons.eco),
                      _StatTile(
                          value: '$_currentStreak',
                          label: 'Day\nStreak',
                          icon: Icons.local_fire_department),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Badges
                _SectionCard(
                  title: 'Earned Badges',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: allBadges,
                  ),
                ),

                const SizedBox(height: 12),

                // Flavor Profile
                _SectionCard(
                  title: 'Flavor Profile',
                  child: SizedBox(
                    height: 200,
                    child: CustomPaint(
                      size: const Size(200, 200),
                      painter: _FlavorRadarPainter(
                        values: _flavorValues,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),


              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBadgeList() {
    final earnedIds = _badges.map((b) => b['id'] as String?).toSet();

    const allPossible = [
      {'id': 'first_scan', 'emoji': '🌱', 'name': 'First Scan'},
      {'id': 'first_meal', 'emoji': '👨‍🍳', 'name': 'First Cook'},
      {'id': 'waste_fighter', 'emoji': '🧹', 'name': 'Waste Fighter'},
      {'id': 'streak_7', 'emoji': '🔥', 'name': '7-Day Streak'},
      {'id': 'world_chef', 'emoji': '🌍', 'name': 'World Chef'},
      {'id': 'master_chef', 'emoji': '💎', 'name': 'Master Chef'},
    ];

    return allPossible
        .map((b) => _BadgeTile(
              emoji: b['emoji']!,
              name: b['name']!,
              earned: earnedIds.contains(b['id']),
            ))
        .toList();
  }
}

// ── Section Card ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Stat Tile ────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge Tile ───────────────────────────────────────────────────

class _BadgeTile extends StatelessWidget {
  final String emoji;
  final String name;
  final bool earned;

  const _BadgeTile(
      {required this.emoji, required this.name, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1.0 : 0.3,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned
                  ? AppTheme.tierGold.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: earned
                    ? AppTheme.tierGold.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: earned ? 0.8 : 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


// ── Flavor Radar Chart Painter ───────────────────────────────────

class _FlavorRadarPainter extends CustomPainter {
  final Map<String, double> values;
  final Color color;

  _FlavorRadarPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;
    final axes = values.keys.toList();
    final n = axes.length;
    final angleStep = (2 * math.pi) / n;

    // Draw grid rings
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final angle = -math.pi / 2 + angleStep * (i % n);
        final p = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, ringPaint);
    }

    // Draw axes and labels
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.6),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..strokeWidth = 1,
      );

      // Label
      final labelPos = Offset(
        center.dx + (radius + 18) * math.cos(angle),
        center.dy + (radius + 18) * math.sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(text: axes[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }

    // Draw data polygon (fill)
    final dataPath = Path();
    for (var i = 0; i <= n; i++) {
      final angle = -math.pi / 2 + angleStep * (i % n);
      final val = values[axes[i % n]] ?? 0;
      final r = radius * val;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw data points
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final val = values[axes[i]] ?? 0;
      final r = radius * val;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      canvas.drawCircle(p, 4, Paint()..color = color);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
