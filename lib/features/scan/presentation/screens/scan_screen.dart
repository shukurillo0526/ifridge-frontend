// I-Fridge — Scan Screen
// =======================
// Camera-based ingredient scanning with AI recognition.
// Captures an image, sends to the backend vision API,
// and displays results in 3 confidence tiers: auto-add, confirm, or correct.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ifridge_app/core/services/api_service.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();

  bool _scanning = false;
  Map<String, dynamic>? _results;
  String? _error;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        _scanning = true;
        _error = null;
        _results = null;
      });

      final Uint8List bytes = await image.readAsBytes();

      // Send to FastAPI -> Gemini Vision Endpoint
      final result = await _api.parseReceipt(
        imageBytes: bytes,
        filename: image.name,
      );

      setState(() {
        _results = result;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Scan Food',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.surface,
        centerTitle: true,
      ),
      body: _scanning
          ? _buildScanningState()
          : _results != null
              ? _buildResults()
              : _buildCaptureState(),
    );
  }

  // ── Capture State (initial) ──────────────────────────────────────

  Widget _buildCaptureState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated scan icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _pulseController.value * 0.08,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.3),
                          AppTheme.accent.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      size: 56,
                      color: AppTheme.accent,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            const Text(
              'Scan Your Ingredients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of food items to add them\nto your shelf automatically',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Camera button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _captureImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 22),
                label: const Text(
                  'Take Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Gallery button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _captureImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library,
                    size: 22, color: Colors.white.withValues(alpha: 0.7)),
                label: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Manual Entry Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton.icon(
                onPressed: _showManualEntryForm,
                icon: const Icon(Icons.edit_note, size: 22, color: IFridgeTheme.primary),
                label: const Text(
                  'Add Manually',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: IFridgeTheme.primary,
                  ),
                ),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recognition failed. Try again.',
                        style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Scanning State (loading) ─────────────────────────────────────

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 3,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing your food...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is identifying ingredients',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Results State (Parsed Receipt) ───────────────────────────────

  Widget _buildResults() {
    final data = _results?['data'] as Map<String, dynamic>?;
    if (data == null) return _buildCaptureState();

    final store = data['store'] as String? ?? 'Unknown Store';
    final date = data['date'] as String? ?? 'Unknown Date';
    final items = (data['items'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.15),
                  AppTheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppTheme.accent,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  store,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.freshGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} Items Detected',
                    style: const TextStyle(
                      color: AppTheme.freshGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Parsed Items List
          if (items.isNotEmpty) ...[
            _sectionHeader(
              '📦 Parsed Ingredients',
              'Review and add to shelf',
              Colors.white,
            ),
            ...items.map((item) {
              final i = item as Map<String, dynamic>;
              final canonicalName = i['canonical_name'] ?? 'Unknown';
              final qty = i['quantity']?.toString() ?? '1';
              final unit = i['unit'] ?? '';
              final category = i['category'] ?? '';
              final expiry = i['expiry_date'] != null 
                  ? DateTime.parse(i['expiry_date']).toString().split(' ')[0] 
                  : 'Unknown';

              return _resultTile(
                icon: Icons.check_circle_outline,
                title: canonicalName,
                subtitle: '$qty $unit • $category\nExp: $expiry',
                color: AppTheme.freshGreen,
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: AppTheme.accent),
                  onPressed: () {
                    // TODO: Phase 2 Connect specific item insert to Supabase RPC
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added $canonicalName!')),
                    );
                  },
                ),
              );
            }),
          ],

          const SizedBox(height: 32),

          // Scan again button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _results = null;
                _error = null;
              }),
              icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.7)),
              label: Text('Scan Another', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Add All Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                 // TODO: Phase 2 Connect Bulk Insert to Supabase RPC
                 ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All items added to shelf!')),
                  );
                 setState(() {
                  _results = null;
                 });
              },
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Add All to Shelf', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(subtitle,
              style: TextStyle(
                  color: color.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _resultTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onConfirm,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        trailing: trailing ?? (onConfirm != null
            ? IconButton(
                icon: const Icon(Icons.check, color: AppTheme.freshGreen),
                onPressed: onConfirm,
              )
            : null),
      ),
    );
  }

  // ── Manual Entry Form ────────────────────────────────────────────

  void _showManualEntryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ManualEntryBottomSheet(),
    );
  }
}

class _ManualEntryBottomSheet extends StatefulWidget {
  const _ManualEntryBottomSheet();

  @override
  State<_ManualEntryBottomSheet> createState() => _ManualEntryBottomSheetState();
}

class _ManualEntryBottomSheetState extends State<_ManualEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedIngredientId;
  String _ingredientName = '';
  double _quantity = 1.0;
  String _unit = 'pcs';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  
  // Future: Autocomplete from master_ingredients table
  final List<String> _units = ['pcs', 'g', 'kg', 'ml', 'L', 'pack', 'bunch'];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Connect to Supabase INSERT in Phase 2 backend step
      
      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $_ingredientName to shelf!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle keyboard pushing up the sheet
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset + 24 : 48,
      ),
      decoration: BoxDecoration(
        color: IFridgeTheme.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const Text(
              'Add Ingredient',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Autocomplete Field (Mocked for now)
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Ingredient Name',
                hintText: 'e.g. Milk, Apples, Chicken',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _ingredientName = v!,
            ),
            const SizedBox(height: 16),

            // Quantity & Unit Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: '1',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSaved: (v) => _quantity = double.tryParse(v!) ?? 1.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expiry Date Picker (Mocked Action)
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Estimated Expiry',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_expiryDate.month}/${_expiryDate.day}/${_expiryDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: IFridgeTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Add to Shelf', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
