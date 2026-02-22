/// I-Fridge — XP Toast Widget
/// ============================
/// Animated floating toast that appears when the user earns XP.

import 'package:flutter/material.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/features/gamification/domain/badges.dart';

/// Show a floating XP reward toast.
void showXpReward(BuildContext context, int xp, {WasteBadge? newBadge}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _XpToastAnimation(
      xp: xp,
      badge: newBadge,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _XpToastAnimation extends StatefulWidget {
  final int xp;
  final WasteBadge? badge;
  final VoidCallback onDismiss;

  const _XpToastAnimation({
    required this.xp,
    this.badge,
    required this.onDismiss,
  });

  @override
  State<_XpToastAnimation> createState() => _XpToastAnimationState();
}

class _XpToastAnimationState extends State<_XpToastAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideUp,
          child: FadeTransition(
            opacity: _fadeIn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    IFridgeTheme.primary.withOpacity(0.9),
                    IFridgeTheme.secondary.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: IFridgeTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.badge != null
                    ? '${widget.badge!.emoji} ${widget.badge!.title} +${widget.xp}XP!'
                    : '+${widget.xp}XP! 🌿 Waste Reduced!',
                style: const TextStyle(
                  color: IFridgeTheme.bgDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
