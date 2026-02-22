// I-Fridge — Empty State Widget
// Displays beautiful SVG/Icon-based empty states for inventories and lists.

import 'package:flutter/material.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';

class EmptyStateIllustration extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateIllustration({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyStateIllustration> createState() => _EmptyStateIllustrationState();
}

class _EmptyStateIllustrationState extends State<EmptyStateIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ghostly Floating Icon
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: IFridgeTheme.primary.withValues(alpha: 0.05),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: 60,
                  color: IFridgeTheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Text Content
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IFridgeTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: widget.onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: IFridgeTheme.primary.withValues(alpha: 0.2),
                  foregroundColor: IFridgeTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  widget.actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
