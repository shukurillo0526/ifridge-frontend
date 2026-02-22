// I-Fridge — Profile Screen
// ==========================
// User profile with gamification stats, XP progress,
// earned badges, flavor profile visualization, and settings.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/features/gamification/domain/badges.dart' show levelFromXp;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data — replace with real user data from Supabase
    const userName = 'Chef Demo';
    const totalXp = 850;
    final level = levelFromXp(totalXp);
    final nextLevelXp = (level + 1) * (level + 1) * 100;
    final progress = totalXp / nextLevelXp;

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
                            colors: [AppTheme.accent, AppTheme.tierGold],
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
                      const Text(
                        userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level $level • $totalXp XP',
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
                            'Level $level',
                            style: const TextStyle(
                              color: AppTheme.tierGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$totalXp / $nextLevelXp XP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.accent),
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
                          value: '24', label: 'Items\nScanned', icon: Icons.camera_alt),
                      _StatTile(
                          value: '8', label: 'Recipes\nCooked', icon: Icons.restaurant),
                      _StatTile(
                          value: '1.2kg',
                          label: 'Waste\nPrevented',
                          icon: Icons.eco),
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
                    children: [
                      _BadgeTile(
                        emoji: '🌱',
                        name: 'First Scan',
                        earned: true,
                      ),
                      _BadgeTile(
                        emoji: '👨‍🍳',
                        name: 'First Cook',
                        earned: true,
                      ),
                      _BadgeTile(
                        emoji: '🧹',
                        name: 'Zero Waste',
                        earned: true,
                      ),
                      _BadgeTile(
                        emoji: '🔥',
                        name: '7-Day Streak',
                        earned: false,
                      ),
                      _BadgeTile(
                        emoji: '🌍',
                        name: 'World Chef',
                        earned: false,
                      ),
                      _BadgeTile(
                        emoji: '💎',
                        name: 'Master Chef',
                        earned: false,
                      ),
                    ],
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
                        values: {
                          'Sweet': 0.7,
                          'Salty': 0.5,
                          'Sour': 0.3,
                          'Bitter': 0.2,
                          'Umami': 0.8,
                          'Spicy': 0.6,
                        },
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Settings
                _SectionCard(
                  title: 'Settings',
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        trailing: Switch(
                          value: true,
                          onChanged: (_) {},
                          activeColor: AppTheme.accent,
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.palette_outlined,
                        label: 'Theme',
                        trailing: Text('Dark',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5))),
                      ),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        label: 'About I-Fridge',
                        trailing: Icon(Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
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

// ── Settings Tile ────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsTile(
      {required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          trailing,
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
