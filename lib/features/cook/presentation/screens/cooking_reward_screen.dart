// I-Fridge — Cooking Reward Screen
// ==================================
// Celebratory screen shown after completing a recipe.
// Awards XP, updates user history, and provides a return to the dashboard.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/features/gamification/data/gamification_repository.dart';

class CookingRewardScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final int matchedIngredientsCount;
  final double matchPct;

  const CookingRewardScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.matchedIngredientsCount,
    required this.matchPct,
  });

  @override
  State<CookingRewardScreen> createState() => _CookingRewardScreenState();
}

class _CookingRewardScreenState extends State<CookingRewardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isSaving = true;
  String? _error;

  // Base reward is 50 XP, bonus is +5 for every matched ingredient
  late int _xpEarned;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _xpEarned = 50 + (widget.matchedIngredientsCount * 5);
    _saveRewards();
  }

  Future<void> _saveRewards() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      // Using demo user ID for prototype if no auth
      final userId = user?.id ?? '00000000-0000-4000-8000-000000000001';

      final repo = GamificationRepository();
      await repo.completeCookingSession(
        userId: userId,
        recipeId: widget.recipeId,
        xpGain: _xpEarned,
        matchedIngredientsCount: widget.matchedIngredientsCount,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save progress. $e';
          _isSaving = false;
        });
        // Still animate so user can dismiss
        _animController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _finish() {
    // Pop back to the main app shell
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              IFridgeTheme.primary.withValues(alpha: 0.2),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: _isSaving
                ? const CircularProgressIndicator(color: IFridgeTheme.primary)
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Confetti / Icon ──────────────────────
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: IFridgeTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  border: Border.all(
                                    color: IFridgeTheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: IFridgeTheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.workspace_premium,
                                size: 60,
                                color: IFridgeTheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // ── Title ────────────────────────────────
                          const Text(
                            'Meal Completed!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'You cooked "${widget.title}" based on your inventory.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),

                          // ── Stats Cards ──────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatCard(
                                icon: Icons.star,
                                value: '+$_xpEarned',
                                label: 'XP Earned',
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 16),
                              _StatCard(
                                icon: Icons.eco,
                                value: '${widget.matchedIngredientsCount}',
                                label: 'Items Used',
                                color: IFridgeTheme.freshGreen,
                              ),
                            ],
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 32),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],

                          const SizedBox(height: 48),

                          // ── Done Button ──────────────────────────
                          FilledButton(
                            onPressed: _finish,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.background,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Back to Shelf',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
