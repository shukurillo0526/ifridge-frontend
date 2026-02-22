// I-Fridge — Inventory Item Card Widget
// A single item on the Living Shelf, with freshness overlay,
// expiry badge, and swipe-to-action gestures.

import 'package:flutter/material.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/features/shelf/domain/inventory_item.dart';
import 'package:ifridge_app/features/shelf/presentation/widgets/freshness_overlay.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onMarkOpened;
  final VoidCallback? onRemove;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMarkOpened,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = item.freshnessState == FreshnessState.expired;
    final isUrgent = item.freshnessState == FreshnessState.critical ||
        item.freshnessState == FreshnessState.urgent;

    return UrgencyPulse(
      isUrgent: isUrgent,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // --- Card Body ---
            Container(
              decoration: BoxDecoration(
                color: IFridgeTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Icon / Image Area ---
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: IFridgeTheme.bgElevated,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: Center(
                        child: ColorFiltered(
                          colorFilter: isExpired
                              ? const ColorFilter.mode(
                                  Colors.grey, BlendMode.saturation)
                              : const ColorFilter.mode(
                                  Colors.transparent, BlendMode.multiply),
                          child: Text(
                            _categoryEmoji(item.category),
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Info Area ---
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              color: isExpired
                                  ? IFridgeTheme.textMuted
                                  : IFridgeTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: isExpired
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _expiryLabel,
                            style: TextStyle(
                              color: _expiryLabelColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Freshness Overlay ---
            Positioned.fill(
              child: FreshnessOverlay(freshnessRatio: item.freshnessRatio),
            ),

            // --- Quantity Badge ---
            if (item.quantity > 1)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: IFridgeTheme.bgDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '×${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}',
                    style: const TextStyle(
                      color: IFridgeTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // --- State Badge (opened / frozen) ---
            if (item.itemState != 'sealed')
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _stateBadgeColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _stateBadgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String get _expiryLabel {
    final days = item.daysUntilExpiry;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Use today!';
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return '$days days';
    return '${(days / 7).floor()}w left';
  }

  Color get _expiryLabelColor {
    switch (item.freshnessState) {
      case FreshnessState.fresh:
        return IFridgeTheme.freshGreen;
      case FreshnessState.aging:
        return IFridgeTheme.agingAmber;
      case FreshnessState.urgent:
        return IFridgeTheme.urgentOrange;
      case FreshnessState.critical:
        return IFridgeTheme.criticalRed;
      case FreshnessState.expired:
        return IFridgeTheme.expiredGrey;
    }
  }

  String get _stateBadgeLabel {
    switch (item.itemState) {
      case 'opened':
        return 'OPENED';
      case 'partially_used':
        return 'PARTIAL';
      case 'frozen':
        return 'FROZEN';
      case 'thawed':
        return 'THAWED';
      default:
        return '';
    }
  }

  Color get _stateBadgeColor {
    switch (item.itemState) {
      case 'opened':
        return IFridgeTheme.agingAmber;
      case 'frozen':
        return IFridgeTheme.secondary;
      case 'thawed':
        return IFridgeTheme.urgentOrange;
      default:
        return IFridgeTheme.textMuted;
    }
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return '🍎';
      case 'vegetable':
        return '🥦';
      case 'dairy':
        return '🥛';
      case 'protein':
      case 'meat':
        return '🥩';
      case 'seafood':
        return '🐟';
      case 'grain':
      case 'bread':
        return '🍞';
      case 'spice':
      case 'seasoning':
        return '🧂';
      case 'beverage':
        return '🧃';
      case 'egg':
        return '🥚';
      default:
        return '🧊';
    }
  }
}
