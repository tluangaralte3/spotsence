import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dare_controller.dart';
import '../../core/theme/app_theme.dart';
import 'dare_camera_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DareProofScreen — submit image + location proof for a challenge
// ─────────────────────────────────────────────────────────────────────────────

class DareProofScreen extends ConsumerStatefulWidget {
  final String dareId;
  final String challengeId;
  final String challengeTitle;

  const DareProofScreen({
    super.key,
    required this.dareId,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  ConsumerState<DareProofScreen> createState() => _DareProofScreenState();
}

class _DareProofScreenState extends ConsumerState<DareProofScreen> {
  final _noteCtrl = TextEditingController();
  final _locationNameCtrl = TextEditingController();

  final List<File> _images = [];
  final int _maxImages = 4;
  bool _gettingLocation = false;
  double? _lat;
  double? _lng;
  String? _locationName;
  bool _submitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _locationNameCtrl.dispose();
    super.dispose();
  }

  /// Returns the listing name / location for the overlay stamp.
  String _getSpotName() {
    final dare = ref.read(dareDetailProvider(widget.dareId)).value;
    if (dare != null) {
      for (final c in dare.challenges) {
        if (c.id == widget.challengeId) {
          return c.listingLocation ?? c.title;
        }
      }
    }
    return widget.challengeTitle;
  }

  Future<void> _cameraWithOverlay() async {
    if (_images.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Max $_maxImages images allowed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<File?>(
      MaterialPageRoute<File?>(
        fullscreenDialog: true,
        builder: (_) => DareCameraOverlay(
          challengeTitle: widget.challengeTitle,
          spotName: _getSpotName(),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _images.add(result));
    }
  }

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Max $_maxImages images allowed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final remaining = _maxImages - _images.length;
    final picked = await picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 80,
      limit: remaining,
    );
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.map((x) => File(x.path)));
    });
  }

  Future<void> _fetchGPS() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permission permanently denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationName = '${pos.latitude.toStringAsFixed(4)}, '
            '${pos.longitude.toStringAsFixed(4)}';
        _locationNameCtrl.text = _locationName!;
      });
    } catch (e) {
      _showLocationError('Could not get location: $e');
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  void _showLocationError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
    );
  }

  Future<List<String>> _uploadImages(String userId) async {
    final urls = <String>[];
    for (int i = 0; i < _images.length; i++) {
      final fileName =
          'proof_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('dare_proofs/$fileName');
      await storageRef.putFile(_images[i]);
      final url = await storageRef.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo as proof'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final imageUrls = await _uploadImages(user.id);
      final locationName = _locationNameCtrl.text.trim().isNotEmpty
          ? _locationNameCtrl.text.trim()
          : _locationName;

      await ref.read(dareControllerProvider.notifier).submitProof(
        dareId: widget.dareId,
        challengeId: widget.challengeId,
        userId: user.id,
        userName: user.displayName,
        userPhoto: user.photoURL,
        imageUrls: imageUrls,
        latitude: _lat,
        longitude: _lng,
        locationName: locationName,
      );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof submitted! Waiting for host review.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit proof: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        title: Text(
          'Submit Proof',
          style: TextStyle(color: context.col.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.col.textSecondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Challenge info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.medal_star5,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenge',
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        widget.challengeTitle,
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Photos section
          _SectionHeader(
            icon: Iconsax.camera,
            title: 'Photos (${_images.length}/$_maxImages)',
            subtitle: 'Add clear photos showing you completed the challenge',
          ),
          const SizedBox(height: 12),
          // Camera (with milestone overlay) vs gallery
          if (_images.length < _maxImages)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cameraWithOverlay,
                    icon: const Icon(Iconsax.camera, size: 16),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Iconsax.image, size: 16),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.col.textSecondary,
                      side: BorderSide(color: context.col.border),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ImageGrid(
              images: _images,
              maxImages: _maxImages,
              onPick: _pickImages,
              onRemove: (i) => setState(() => _images.removeAt(i)),
            ),
          ],
          const SizedBox(height: 24),

          // Location section
          _SectionHeader(
            icon: Iconsax.location,
            title: 'Location (Optional)',
            subtitle: 'Add your location to verify where you completed it',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationNameCtrl,
                  style: TextStyle(color: context.col.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Location name or GPS coordinates',
                    hintStyle:
                        TextStyle(color: context.col.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: context.col.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Iconsax.location,
                      size: 18,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _HasGps(
                loading: _gettingLocation,
                hasGps: _lat != null,
                onTap: _fetchGPS,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Note section (future)
          _SectionHeader(
            icon: Iconsax.note_text,
            title: 'Note',
            subtitle: 'Additional notes (coming soon)',
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.col.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _noteCtrl,
                  enabled: false,
                  maxLines: 3,
                  style: TextStyle(color: context.col.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tell us about your experience...',
                    hintStyle:
                        TextStyle(color: context.col.textMuted, fontSize: 14),
                    filled: false,
                    contentPadding: const EdgeInsets.all(14),
                    border: InputBorder.none,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.col.surfaceElevated.withAlpha(200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.col.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.col.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.clock,
                              size: 13,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Coming soon',
                              style: TextStyle(
                                color: context.col.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bg,
                      ),
                    )
                  : const Icon(Iconsax.send_1, size: 18),
              label: Text(_submitting ? 'Submitting...' : 'Submit Proof'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<File> images;
  final int maxImages;
  final VoidCallback onPick;
  final void Function(int) onRemove;

  const _ImageGrid({
    required this.images,
    required this.maxImages,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length < maxImages ? images.length + 1 : images.length,
      itemBuilder: (context, i) {
        if (i == images.length) {
          // Add button
          return GestureDetector(
            onTap: onPick,
            child: Container(
              decoration: BoxDecoration(
                color: context.col.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withAlpha(60),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.camera,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(images[i], fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HasGps extends StatelessWidget {
  final bool loading;
  final bool hasGps;
  final VoidCallback onTap;

  const _HasGps({
    required this.loading,
    required this.hasGps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: hasGps ? AppColors.success.withAlpha(25) : context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasGps ? AppColors.success : context.col.border,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(
                hasGps ? Iconsax.location_tick : Iconsax.gps,
                size: 20,
                color: hasGps ? AppColors.success : context.col.textSecondary,
              ),
      ),
    );
  }
}
