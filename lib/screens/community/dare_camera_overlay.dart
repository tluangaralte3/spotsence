import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DareCameraOverlay
// Full-screen camera capture with a challenge milestone overlay stamped on the
// photo. Navigate to this screen via Navigator.of(context, rootNavigator: true).
// Pops with a composited File (PNG), or null if the user cancels.
// ─────────────────────────────────────────────────────────────────────────────

class DareCameraOverlay extends StatefulWidget {
  final String challengeTitle;
  final String spotName;
  /// Optional medal label stamped on the photo, e.g. "Bronze Medal"
  final String? medalLabel;
  /// Color for the medal badge in the stamp
  final Color? medalColor;

  const DareCameraOverlay({
    super.key,
    required this.challengeTitle,
    required this.spotName,
    this.medalLabel,
    this.medalColor,
  });

  @override
  State<DareCameraOverlay> createState() => _DareCameraOverlayState();
}

class _DareCameraOverlayState extends State<DareCameraOverlay> {
  File? _captured;
  bool _compositing = false;
  final _repaintKey = GlobalKey();
  double? _lat;
  double? _lng;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _dateStr {
    final now = DateTime.now();
    return '${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  Future<void> _openCamera() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (x != null && mounted) {
      setState(() => _captured = File(x.path));
      _fetchGPS(); // background GPS fetch while user reviews the photo
    }
  }

  Future<void> _fetchGPS() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (_) {
      // GPS unavailable — stamp will omit coordinates
    }
  }

  Future<void> _confirmAndComposite() async {
    if (_captured == null) return;
    setState(() => _compositing = true);
    try {
      // Let the frame fully render before compositing
      await Future.delayed(const Duration(milliseconds: 120));
      final boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final file = File(
        '${Directory.systemTemp.path}/dare_overlay_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      if (mounted) Navigator.of(context).pop(file);
    } catch (_) {
      // Compositing failed — return original photo without overlay
      if (mounted) Navigator.of(context).pop(_captured);
    } finally {
      if (mounted) setState(() => _compositing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Challenge Photo',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          if (_captured != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _compositing ? null : _confirmAndComposite,
                child: Text(
                  _compositing ? 'Saving…' : 'Use Photo',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _captured == null ? _capturePrompt() : _previewWithOverlay(),
    );
  }

  // ── Capture prompt ─────────────────────────────────────────────────────────

  Widget _capturePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(80),
                  width: 2,
                ),
              ),
              child: const Icon(
                Iconsax.camera,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Capture your achievement',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.spotName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.challengeTitle,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: _openCamera,
              icon: const Icon(Iconsax.camera),
              label: const Text('Open Camera'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview with stamped overlay ───────────────────────────────────────────

  Widget _previewWithOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Compositable layer (RepaintBoundary captures this) ──────────────
        RepaintBoundary(
          key: _repaintKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_captured!, fit: BoxFit.cover),
              // Bottom gradient + milestone badge overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.88),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Achievement badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.black,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Challenge Achieved',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Spot / listing name
                      Text(
                        widget.spotName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Challenge title
                      Text(
                        widget.challengeTitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Medal badge (if provided)
                      if (widget.medalLabel != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.medalColor ?? AppColors.accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.medal_star5,
                                size: 11,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.medalLabel!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      // GPS coordinates + date row
                      Row(
                        children: [
                          if (_lat != null && _lng != null) ...[
                            const Icon(
                              Iconsax.location,
                              size: 10,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            _dateStr,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Controls (outside RepaintBoundary — not stamped onto photo) ─────
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _openCamera,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 22),
            ),
          ),
        ),

        if (_compositing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Stamping milestone…',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
