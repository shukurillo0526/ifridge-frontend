// I-Fridge — Active Cooking Screen
// ==================================
// Distraction-free, step-by-step cooking interface.
// Parses robot_action JSON to display simulated backend actions.
// Allows sweeping through steps and completing the recipe.

import 'dart:convert';
import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                  // Back Button (hidden on first step)
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

// ── Step Detail Card ────────────────────────────────────────────────

class _CookingStepCard extends StatelessWidget {
  final Map<String, dynamic> step;

  const _CookingStepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final humanText = step['human_text'] ?? '';
    final estimatedSeconds = step['estimated_seconds'];
    final requiresAttention = step['requires_attention'] == true;

    // Parse Robot Action JSON
    Map<String, dynamic> robotAction = {};
    if (step['robot_action'] != null) {
      if (step['robot_action'] is String) {
        try {
          robotAction = jsonDecode(step['robot_action']);
        } catch (_) {}
      } else if (step['robot_action'] is Map) {
        robotAction = step['robot_action'] as Map<String, dynamic>;
      }
    }

    final actionType = robotAction['action'] ?? 'UNKNOWN';
    final target = robotAction['target'] ?? 'item';
    final params = (robotAction['params'] as Map?) ?? {};

    // Robot Summary
    String robotSummary = 'Waiting for instruction';
    IconData robotIcon = Icons.memory;

    switch (actionType) {
      case 'CUT':
        robotSummary =
            'Preparing to cut $target (${params['style'] ?? 'default style'})';
        robotIcon = Icons.fastfood;
        break;
      case 'HEAT':
        robotSummary = 'Heating $target to ${params['temp_c']}°C...';
        robotIcon = Icons.local_fire_department;
        break;
      case 'FRY':
      case 'SAUTE':
      case 'SCRAMBLE':
      case 'SIMMER':
      case 'BOIL':
        robotSummary =
            'Cooking $target for ${params['duration_s'] ?? estimatedSeconds}s';
        robotIcon = Icons.lunch_dining;
        break;
      case 'MIX':
        robotSummary = 'Mixing $target automatically...';
        robotIcon = Icons.blender;
        break;
      case 'BAKE':
        robotSummary = 'Baking $target at ${params['temp_c']}°C...';
        robotIcon = Icons.microwave;
        break;
      case 'PLATE':
      case 'SEASON_PLATE':
        robotSummary = 'Ready for plating $target';
        robotIcon = Icons.room_service;
        break;
      default:
        robotSummary = 'Executing $actionType on $target';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic / Illustration Placeholder
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: Icon(
                  requiresAttention ? Icons.front_hand : Icons.smart_toy,
                  size: 80,
                  color:
                      (requiresAttention ? Colors.orange : IFridgeTheme.primary)
                          .withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Core Instruction (Human)
          Text(
            humanText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Time Estimate
          if (estimatedSeconds != null)
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  estimatedSeconds < 60
                      ? '${estimatedSeconds} seconds'
                      : '${estimatedSeconds ~/ 60}m ${estimatedSeconds % 60}s',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Robot Simulated Action Decode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: requiresAttention
                    ? Colors.orange.withValues(alpha: 0.15)
                    : IFridgeTheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      requiresAttention ? Icons.person : Icons.smart_toy,
                      size: 14,
                      color: requiresAttention
                          ? Colors.orange
                          : IFridgeTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      requiresAttention
                          ? 'MANUAL ACTION REQUIRED'
                          : 'AUTOMATED ROBOT ACTION',
                      style: TextStyle(
                        color: requiresAttention
                            ? Colors.orange
                            : IFridgeTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(robotIcon, size: 18, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        robotSummary,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
