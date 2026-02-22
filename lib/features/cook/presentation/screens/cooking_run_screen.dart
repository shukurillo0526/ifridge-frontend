// I-Fridge — Active Cooking Screen
// ==================================
// Distraction-free, step-by-step cooking tutorial.
// Features: contextual icons, interactive countdown timers,
// attention flags, wakelock, and swipeable step cards.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/features/cook/presentation/screens/cooking_reward_screen.dart';

class CookingRunScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final List<Map<String, dynamic>> steps;
  final int matchedIngredientsCount;
  final double matchPct;

  const CookingRunScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.steps,
    required this.matchedIngredientsCount,
    required this.matchPct,
  });

  @override
  State<CookingRunScreen> createState() => _CookingRunScreenState();
}

class _CookingRunScreenState extends State<CookingRunScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finishCooking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CookingRewardScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          matchedIngredientsCount: widget.matchedIngredientsCount,
          matchPct: widget.matchPct,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'No steps available for this recipe.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final totalSteps = widget.steps.length;
    final progress = (_currentIndex + 1) / totalSteps;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress Bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      IFridgeTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Step ${_currentIndex + 1} of $totalSteps',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // ── Step Carousel ────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemCount: totalSteps,
                itemBuilder: (context, index) {
                  return _CookingStepCard(step: widget.steps[index]);
                },
              ),
            ),

            // ── Navigation Controls ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  _currentIndex > 0
                      ? TextButton.icon(
                          onPressed: _prevStep,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Back',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        )
                      : const SizedBox(width: 80),

                  // Next / Finish Button
                  _currentIndex < totalSteps - 1
                      ? FilledButton.icon(
                          onPressed: _nextStep,
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          label: const Text(
                            'Next Step',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: IFridgeTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: _finishCooking,
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text(
                            'Finish Cooking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: IFridgeTheme.freshGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step Detail Card (Human-First Tutorial) ─────────────────────────

class _CookingStepCard extends StatefulWidget {
  final Map<String, dynamic> step;

  const _CookingStepCard({required this.step});

  @override
  State<_CookingStepCard> createState() => _CookingStepCardState();
}

class _CookingStepCardState extends State<_CookingStepCard> {
  int? _timerSeconds;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    final est = widget.step['estimated_seconds'];
    if (est != null && est is int && est > 0) {
      _timerSeconds = est;
    }
  }

  void _startTimer() {
    if (_timerSeconds == null || _timerSeconds! <= 0 || _timerRunning) return;
    setState(() => _timerRunning = true);
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_timerRunning) return;
      setState(() {
        _timerSeconds = (_timerSeconds ?? 1) - 1;
        if (_timerSeconds! <= 0) {
          _timerRunning = false;
        } else {
          _tick();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  // Choose an icon based on common cooking keywords
  IconData _pickIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('heat') || lower.contains('boil') || lower.contains('simmer')) {
      return Icons.local_fire_department;
    }
    if (lower.contains('cut') || lower.contains('chop') || lower.contains('dice') || lower.contains('slice')) {
      return Icons.content_cut;
    }
    if (lower.contains('mix') || lower.contains('stir') || lower.contains('whisk')) {
      return Icons.blender;
    }
    if (lower.contains('bake') || lower.contains('oven')) {
      return Icons.microwave;
    }
    if (lower.contains('fry') || lower.contains('saute') || lower.contains('pan')) {
      return Icons.lunch_dining;
    }
    if (lower.contains('serve') || lower.contains('plate') || lower.contains('garnish')) {
      return Icons.room_service;
    }
    if (lower.contains('wash') || lower.contains('rinse') || lower.contains('clean')) {
      return Icons.water_drop;
    }
    if (lower.contains('season') || lower.contains('salt') || lower.contains('pepper')) {
      return Icons.spa;
    }
    if (lower.contains('cool') || lower.contains('chill') || lower.contains('refrigerat')) {
      return Icons.ac_unit;
    }
    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    final humanText = widget.step['human_text'] ?? '';
    final estimatedSeconds = widget.step['estimated_seconds'];
    final requiresAttention = widget.step['requires_attention'] == true;
    final icon = _pickIcon(humanText);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cooking Illustration Area
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 72,
                      color: (requiresAttention ? Colors.orange : IFridgeTheme.primary)
                          .withValues(alpha: 0.3),
                    ),
                    if (requiresAttention) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '👀 Needs Your Attention',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Core Instruction — Big, bold, readable
          Text(
            humanText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Timer Button
          if (estimatedSeconds != null && estimatedSeconds is int && estimatedSeconds > 0)
            GestureDetector(
              onTap: _startTimer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _timerRunning
                      ? IFridgeTheme.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _timerRunning
                        ? IFridgeTheme.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _timerRunning ? Icons.timer : Icons.play_circle_fill,
                      color: _timerRunning ? IFridgeTheme.primary : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _timerRunning
                          ? _formatTime(_timerSeconds ?? 0)
                          : 'Start Timer • ${_formatTime(estimatedSeconds)}',
                      style: TextStyle(
                        color: _timerRunning ? IFridgeTheme.primary : Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (_timerSeconds == 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.check_circle, color: IFridgeTheme.freshGreen, size: 22),
                    ],
                  ],
                ),
              ),
            ),

          const Spacer(),
        ],
      ),
    );
  }
}
