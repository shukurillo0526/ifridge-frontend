// I-Fridge — Living Shelf Screen
// The Digital Twin of the user's kitchen — a reactive grid of inventory items
// organized by storage zone (fridge, freezer, pantry).
// Connected to Supabase with Realtime for live updates.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/features/shelf/domain/inventory_item.dart';
import 'package:ifridge_app/features/shelf/presentation/widgets/inventory_item_card.dart';

/// Demo user UUID — matches the seed_data.sql deterministic UUID.
const _demoUserId = '00000000-0000-4000-8000-000000000001';

class LivingShelfScreen extends StatefulWidget {
  const LivingShelfScreen({super.key});

  @override
  State<LivingShelfScreen> createState() => _LivingShelfScreenState();
}

class _LivingShelfScreenState extends State<LivingShelfScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _zones = ['Fridge', 'Freezer', 'Pantry'];

  List<InventoryItem> _items = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _zones.length, vsync: this);
    _loadInventory();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────

  Future<void> _loadInventory() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await Supabase.instance.client
          .from('inventory_items')
          .select('*, ingredients(display_name_en, category)')
          .eq('user_id', _demoUserId)
          .order('computed_expiry', ascending: true);

      setState(() {
        _items = (data as List)
            .map((row) =>
                InventoryItem.fromSupabase(row as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Realtime Subscription ────────────────────────────────────

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('inventory_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inventory_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _demoUserId,
          ),
          callback: (payload) {
            // Reload full inventory on any change
            _loadInventory();
          },
        )
        .subscribe();
  }

  List<InventoryItem> _itemsForZone(String zone) {
    return _items
        .where((i) => i.location == zone.toLowerCase())
        .toList()
      ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧊 My Fridge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Expiry alerts',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: IFridgeTheme.primary,
          labelColor: IFridgeTheme.primary,
          unselectedLabelColor: IFridgeTheme.textSecondary,
          tabs: _zones.map((z) => Tab(text: z)).toList(),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(height: 16),
                  Text('Loading inventory...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: _zones.map((zone) {
                    final items = _itemsForZone(zone);
                    return _buildShelfGrid(items, zone);
                  }).toList(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Couldn\'t load inventory',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadInventory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfGrid(List<InventoryItem> items, String zone) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              zone == 'Fridge' ? '🧊' : zone == 'Freezer' ? '❄️' : '🗄️',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Your $zone is empty',
              style: const TextStyle(
                color: IFridgeTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan items or add them manually',
              style: TextStyle(
                color: IFridgeTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Separate urgent items for the banner
    final urgentItems = items.where((i) => i.daysUntilExpiry <= 2).toList();

    return RefreshIndicator(
      onRefresh: _loadInventory,
      color: AppTheme.accent,
      child: CustomScrollView(
        slivers: [
          // --- Expiring Soon Banner ---
          if (urgentItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      IFridgeTheme.criticalRed.withValues(alpha: 0.15),
                      IFridgeTheme.urgentOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: IFridgeTheme.criticalRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expiring Soon',
                            style: TextStyle(
                              color: IFridgeTheme.criticalRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${urgentItems.length} item(s) need attention',
                            style: const TextStyle(
                              color: IFridgeTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IFridgeTheme.criticalRed,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Cook Now',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // --- Section Header ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${items.length} items',
                    style: const TextStyle(
                      color: IFridgeTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sorted by expiry ↑',
                    style: TextStyle(
                      color: IFridgeTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Main Grid ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    InventoryItemCard(item: items[index]),
                childCount: items.length,
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
