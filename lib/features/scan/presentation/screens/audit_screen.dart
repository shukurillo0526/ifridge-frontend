import 'package:flutter/material.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'dart:math' as math;

class AuditItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String rawDetect;
  
  AuditItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rawDetect,
  });
}

class AuditScreen extends StatefulWidget {
  final List<AuditItem> initialItems;

  const AuditScreen({super.key, required this.initialItems});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> with TickerProviderStateMixin {
  late List<AuditItem> _items;
  double _swipeOffset = 0.0;
  double _swipeAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffset += details.delta.dx;
      _swipeAngle = _swipeOffset / 400; // Arbitrary divisor to convert offset to radians
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_swipeOffset > 100 || details.velocity.pixelsPerSecond.dx > 800) {
      _swipeRight();
    } else if (_swipeOffset < -100 || details.velocity.pixelsPerSecond.dx < -800) {
      _swipeLeft();
    } else {
      // Snap back to center
      setState(() {
        _swipeOffset = 0.0;
        _swipeAngle = 0.0;
      });
    }
  }

  void _swipeLeft() {
    // Reject
    _animateAndRemove(-MediaQuery.of(context).size.width, 'Rejected');
  }

  void _swipeRight() {
    // Accept
    _animateAndRemove(MediaQuery.of(context).size.width, 'Accepted');
  }

  void _animateAndRemove(double targetOffset, String actionMsg) {
    setState(() {
      _swipeOffset = targetOffset;
      _swipeAngle = targetOffset / 400;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (_items.isNotEmpty) {
        final removed = _items.removeLast();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionMsg: ${removed.title}'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: AppTheme.surface,
          ),
        );
      }
      setState(() {
        _swipeOffset = 0.0;
        _swipeAngle = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Visual Audit', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Review AI Detections\nSwipe Right to Accept, Left to Reject',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _items.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all, size: 80, color: AppTheme.freshGreen.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('Audit Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 32),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to Shelf'),
                          )
                        ],
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: _items.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final AuditItem item = entry.value;
                          final bool isTop = index == _items.length - 1;

                          return _buildCard(item, isTop);
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            if (_items.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.large(
                    heroTag: 'reject_btn',
                    onPressed: _swipeLeft,
                    backgroundColor: AppTheme.surface,
                    foregroundColor: Colors.red,
                    elevation: 8,
                    child: const Icon(Icons.close, size: 36),
                  ),
                  FloatingActionButton.large(
                    heroTag: 'accept_btn',
                    onPressed: _swipeRight,
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.freshGreen,
                    elevation: 8,
                    child: const Icon(Icons.favorite, size: 36),
                  ),
                ],
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(AuditItem item, bool isTop) {
    Widget card = Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Center(
                child: Icon(
                  item.category == 'Produce' ? Icons.eco 
                  : item.category == 'Dairy' ? Icons.water_drop 
                  : item.category == 'Meat' ? Icons.set_meal 
                  : Icons.kitchen,
                  size: 100,
                  color: AppTheme.accent.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    'Raw OCR: "${item.rawDetect}"',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!isTop) {
      return Transform.scale(
        scale: 0.95,
        child: card,
      );
    }

    // Top card gets gestures and animation
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(_swipeOffset, 0),
        child: Transform.rotate(
          angle: _swipeAngle,
          child: Stack(
            children: [
              card,
              // Stamp Overlays
              if (_swipeOffset > 20)
                Positioned(
                  top: 40,
                  left: 40,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.freshGreen, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('KEEP', style: TextStyle(color: AppTheme.freshGreen, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ),
                ),
              if (_swipeOffset < -20)
                Positioned(
                  top: 40,
                  right: 40,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('DISCARD', style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
