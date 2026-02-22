/// I-Fridge — Inventory Item Domain Model
/// ========================================

class InventoryItem {
  final String id;
  final String ingredientId;
  final String name;
  final String? imageUrl;
  final double quantity;
  final String unit;
  final String itemState;       // sealed, opened, partially_used, frozen, thawed
  final DateTime? purchaseDate;
  final DateTime? computedExpiry;
  final String location;        // fridge, freezer, pantry
  final String source;          // manual, camera, barcode
  final double? confidenceScore;
  final String category;        // fruit, dairy, protein, etc.

  InventoryItem({
    required this.id,
    required this.ingredientId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.unit,
    required this.itemState,
    this.purchaseDate,
    this.computedExpiry,
    this.location = 'fridge',
    this.source = 'manual',
    this.confidenceScore,
    this.category = 'other',
  });

  /// Days until this item expires. Negative = already expired.
  int get daysUntilExpiry {
    if (computedExpiry == null) return 999;
    return computedExpiry!.difference(DateTime.now()).inDays;
  }

  /// Freshness ratio: 1.0 = perfectly fresh, 0.0 = expired.
  double get freshnessRatio {
    if (computedExpiry == null || purchaseDate == null) return 1.0;
    final totalLife = computedExpiry!.difference(purchaseDate!).inDays;
    if (totalLife <= 0) return 0.0;
    final remaining = computedExpiry!.difference(DateTime.now()).inDays;
    return (remaining / totalLife).clamp(0.0, 1.0);
  }

  /// Freshness state for visual rendering.
  FreshnessState get freshnessState {
    final ratio = freshnessRatio;
    if (ratio > 0.6) return FreshnessState.fresh;
    if (ratio > 0.3) return FreshnessState.aging;
    if (ratio > 0.1) return FreshnessState.urgent;
    if (ratio > 0.0) return FreshnessState.critical;
    return FreshnessState.expired;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      ingredientId: json['ingredient_id'] as String,
      name: json['name'] ?? json['display_name_en'] ?? 'Unknown',
      imageUrl: json['image_url'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'piece',
      itemState: json['item_state'] as String? ?? 'sealed',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'])
          : null,
      computedExpiry: json['computed_expiry'] != null
          ? DateTime.tryParse(json['computed_expiry'])
          : null,
      location: json['location'] as String? ?? 'fridge',
      source: json['source'] as String? ?? 'manual',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      category: json['category'] as String? ?? 'other',
    );
  }

  /// Factory for Supabase rows with joined `ingredients` table.
  /// Expects: `inventory_items.select('*, ingredients(display_name_en, category)')`.
  factory InventoryItem.fromSupabase(Map<String, dynamic> row) {
    final ingredient = row['ingredients'] as Map<String, dynamic>?;
    return InventoryItem(
      id: row['id'] as String,
      ingredientId: row['ingredient_id'] as String,
      name: ingredient?['display_name_en'] ?? 'Unknown',
      quantity: (row['quantity'] as num).toDouble(),
      unit: row['unit'] as String? ?? 'piece',
      itemState: row['item_state'] as String? ?? 'sealed',
      purchaseDate: row['purchase_date'] != null
          ? DateTime.tryParse(row['purchase_date'].toString())
          : null,
      computedExpiry: row['computed_expiry'] != null
          ? DateTime.tryParse(row['computed_expiry'].toString())
          : null,
      location: row['location'] as String? ?? 'fridge',
      source: row['source'] as String? ?? 'manual',
      confidenceScore: (row['confidence_score'] as num?)?.toDouble(),
      category: ingredient?['category'] as String? ?? 'other',
    );
  }
}

enum FreshnessState { fresh, aging, urgent, critical, expired }
