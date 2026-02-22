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

      final result = await _api.recognizeImage(
        userId: 'demo-user',
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

  // ── Results State ────────────────────────────────────────────────

  Widget _buildResults() {
    final autoAdded = (_results?['auto_added'] as List?) ?? [];
    final confirm = (_results?['confirm'] as List?) ?? [];
    final correct = (_results?['correct'] as List?) ?? [];

    final total = autoAdded.length + confirm.length + correct.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
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
            ),
            child: Column(
              children: [
                Icon(
                  total > 0 ? Icons.check_circle : Icons.info_outline,
                  color: total > 0 ? AppTheme.freshGreen : Colors.white54,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  total > 0
                      ? '$total item${total != 1 ? 's' : ''} detected'
                      : 'No food items detected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Auto-added section
          if (autoAdded.isNotEmpty) ...[
            _sectionHeader(
              '✅ Auto-Added',
              '${autoAdded.length} items added instantly',
              AppTheme.freshGreen,
            ),
            ...autoAdded.map((id) => _resultTile(
              icon: Icons.check_circle,
              title: 'Item added to shelf',
              subtitle: 'ID: $id',
              color: AppTheme.freshGreen,
            )),
            const SizedBox(height: 16),
          ],

          // Confirm section
          if (confirm.isNotEmpty) ...[
            _sectionHeader(
              '🔶 Needs Confirmation',
              '${confirm.length} items to review',
              Colors.orange,
            ),
            ...confirm.map((pred) {
              final p = pred as Map<String, dynamic>;
              return _resultTile(
                icon: Icons.help_outline,
                title: p['clarifai_concept'] ?? 'Unknown',
                subtitle:
                    'Confidence: ${((p['confidence'] ?? 0) * 100).toInt()}%',
                color: Colors.orange,
                onConfirm: () {
                  // TODO: Implement confirm action
                },
              );
            }),
            const SizedBox(height: 16),
          ],

          // Correct section
          if (correct.isNotEmpty) ...[
            _sectionHeader(
              '❌ Needs Correction',
              '${correct.length} items to identify',
              Colors.red,
            ),
            ...correct.map((pred) {
              final p = pred as Map<String, dynamic>;
              return _resultTile(
                icon: Icons.edit,
                title: p['clarifai_concept'] ?? 'Unknown',
                subtitle:
                    'Confidence: ${((p['confidence'] ?? 0) * 100).toInt()}% — tap to correct',
                color: Colors.red,
              );
            }),
          ],

          const SizedBox(height: 32),

          // Scan again button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => setState(() {
                _results = null;
                _error = null;
              }),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Again'),
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
        trailing: onConfirm != null
            ? IconButton(
                icon: const Icon(Icons.check, color: AppTheme.freshGreen),
                onPressed: onConfirm,
              )
            : null,
      ),
    );
  }
}
