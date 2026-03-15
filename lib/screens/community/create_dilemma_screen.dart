import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';

// ── Quick place-search model (flat across all collections) ───────────────────

class _PlaceResult {
  final String id;
  final String name;
  final String category;
  final String? imageUrl;
  final String? district;

  const _PlaceResult({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    this.district,
  });

  DilemmaOption toOption() => DilemmaOption(
    spotId: id,
    name: name,
    category: category,
    imageUrl: imageUrl,
    district: district,
  );
}

// ── Duration presets ─────────────────────────────────────────────────────────

class _DurationOption {
  final String label;
  final Duration? duration;
  const _DurationOption(this.label, this.duration);
}

const _durations = [
  _DurationOption('No limit', null),
  _DurationOption('1 day', Duration(days: 1)),
  _DurationOption('3 days', Duration(days: 3)),
  _DurationOption('1 week', Duration(days: 7)),
  _DurationOption('2 weeks', Duration(days: 14)),
  _DurationOption('1 month', Duration(days: 30)),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class CreateDilemmaScreen extends ConsumerStatefulWidget {
  const CreateDilemmaScreen({super.key});

  @override
  ConsumerState<CreateDilemmaScreen> createState() =>
      _CreateDilemmaScreenState();
}

class _CreateDilemmaScreenState extends ConsumerState<CreateDilemmaScreen> {
  final _questionCtrl = TextEditingController();
  DilemmaOption? _placeA;
  DilemmaOption? _placeB;
  int _durationIndex = 0; // index into _durations
  bool _saving = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _questionCtrl.text.trim().isNotEmpty &&
      _placeA != null &&
      _placeB != null &&
      _placeA!.spotId != _placeB!.spotId;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);

    final error = await ref
        .read(dilemmasControllerProvider.notifier)
        .createDilemma(
          question: _questionCtrl.text.trim(),
          optionA: _placeA!,
          optionB: _placeB!,
          authorId: user.id,
          authorName: user.displayName,
          authorPhoto: user.photoURL ?? '',
          duration: _durations[_durationIndex].duration,
        );

    if (mounted) {
      setState(() => _saving = false);
      if (error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dilemma posted! 🤔'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickPlace(bool isA) async {
    final result = await showModalBottomSheet<DilemmaOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PlacePickerSheet(excludeId: isA ? _placeB?.spotId : _placeA?.spotId),
    );
    if (result != null && mounted) {
      setState(() {
        if (isA) {
          _placeA = result;
        } else {
          _placeB = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.surface,
        title: const Text('New Dilemma'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _canSubmit && !_saving ? _submit : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: _canSubmit
                          ? AppColors.primary
                          : context.col.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            _SectionLabel(
              icon: Icons.help_outline_rounded,
              label: 'Your question',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionCtrl,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. "Which is better for a weekend trip?"',
                hintStyle: TextStyle(color: context.col.textMuted),
                filled: true,
                fillColor: context.col.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.col.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.col.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                counterStyle: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 11,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Places
            _SectionLabel(
              icon: Icons.compare_arrows_rounded,
              label: 'Compare two places',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PlaceSlot(
                    label: 'Place A',
                    option: _placeA,
                    color: AppColors.secondary,
                    onTap: () => _pickPlace(true),
                  ),
                ),
                const SizedBox(width: 12),
                const _VsChip(),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlaceSlot(
                    label: 'Place B',
                    option: _placeB,
                    color: AppColors.warning,
                    onTap: () => _pickPlace(false),
                  ),
                ),
              ],
            ),

            if (_placeA != null &&
                _placeB != null &&
                _placeA!.spotId == _placeB!.spotId)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Please select two different places.',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),

            const SizedBox(height: 28),

            // Duration
            _SectionLabel(
              icon: Icons.timer_outlined,
              label: 'Poll duration (optional)',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_durations.length, (i) {
                final selected = _durationIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _durationIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : context.col.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : context.col.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      _durations[i].label,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? AppColors.primary
                            : context.col.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSubmit && !_saving ? _submit : null,
                icon: _saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.col.bg,
                        ),
                      )
                    : const Icon(Icons.how_to_vote_outlined),
                label: Text(_saving ? 'Posting...' : 'Post Dilemma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: context.col.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: context.col.border,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.col.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── VS chip ───────────────────────────────────────────────────────────────────

class _VsChip extends StatelessWidget {
  const _VsChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.col.surfaceElevated,
        border: Border.all(color: context.col.border),
      ),
      alignment: Alignment.center,
      child: Text(
        'VS',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: context.col.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Place slot ────────────────────────────────────────────────────────────────

class _PlaceSlot extends StatelessWidget {
  final String label;
  final DilemmaOption? option;
  final Color color;
  final VoidCallback onTap;
  const _PlaceSlot({
    required this.label,
    required this.option,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: option != null
                ? color.withValues(alpha: 0.6)
                : context.col.border,
            width: option != null ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: option == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_location_alt_outlined, color: color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to select',
                    style: TextStyle(color: context.col.textMuted, fontSize: 10),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (option!.imageUrl != null && option!.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: option!.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, err, child) => Container(
                        color: color.withValues(alpha: 0.15),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.place_rounded,
                          color: color,
                          size: 32,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: color.withValues(alpha: 0.15),
                      alignment: Alignment.center,
                      child: Icon(Icons.place_rounded, color: color, size: 32),
                    ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Name
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (option!.category != null)
                          Text(
                            _categoryLabel(option!.category!),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Edit badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.edit_rounded, size: 12, color: color),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'cafe':
        return '☕ Café';
      case 'restaurant':
        return '🍽️ Restaurant';
      case 'hotel':
        return '🏨 Hotel';
      case 'homestay':
        return '🏠 Homestay';
      default:
        return '🏔️ Spot';
    }
  }
}

// ── Place picker bottom sheet ─────────────────────────────────────────────────

class _PlacePickerSheet extends StatefulWidget {
  final String? excludeId;
  const _PlacePickerSheet({this.excludeId});

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  final _ctrl = TextEditingController();
  List<_PlaceResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final db = FirebaseFirestore.instance;
    final lower = q.toLowerCase();

    // Search all 5 collections in parallel using startAt / endAt range query
    final futures = [
      _queryCollection(db, 'spots', lower, 'name', 'spot', 'imagesUrl'),
      _queryCollection(db, 'cafes', lower, 'name', 'cafe', 'images'),
      _queryCollection(
        db,
        'restaurants',
        lower,
        'name',
        'restaurant',
        'images',
      ),
      _queryCollection(db, 'accommodations', lower, 'name', 'hotel', 'images'),
      _queryCollection(db, 'homestays', lower, 'name', 'homestay', 'images'),
    ];

    final lists = await Future.wait(futures);
    final all = lists.expand((l) => l).toList();

    // Sort by relevance (starts-with gets priority)
    all.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(lower) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(lower) ? 0 : 1;
      return aStarts.compareTo(bStarts);
    });

    // Exclude the already-chosen place
    final filtered = all.where((r) => r.id != widget.excludeId).toList();

    if (mounted) {
      setState(() {
        _results = filtered;
        _loading = false;
      });
    }
  }

  Future<List<_PlaceResult>> _queryCollection(
    FirebaseFirestore db,
    String collection,
    String query,
    String nameField,
    String category,
    String imageField,
  ) async {
    try {
      final snap = await db
          .collection(collection)
          .orderBy(nameField)
          .startAt([query[0].toUpperCase() + query.substring(1)])
          .endAt(['$query\uf8ff'])
          .limit(8)
          .get();

      // Fallback: also try lowercase start
      final snap2 = await db
          .collection(collection)
          .orderBy(nameField)
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(8)
          .get();

      final allDocs = {...snap.docs, ...snap2.docs}.toList();

      return allDocs
          .map((doc) {
            final d = doc.data();
            String? heroImg;
            final imgRaw = d[imageField];
            if (imgRaw is List && imgRaw.isNotEmpty) {
              heroImg = imgRaw.first?.toString();
            } else if (imgRaw is String && imgRaw.isNotEmpty) {
              heroImg = imgRaw;
            }
            return _PlaceResult(
              id: doc.id,
              name: d[nameField]?.toString() ?? '',
              category: category,
              imageUrl: heroImg,
              district: d['district']?.toString() ?? d['location']?.toString(),
            );
          })
          .where((r) => r.name.toLowerCase().contains(query))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select a place',
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search spots, cafés, restaurants...',
                hintStyle: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: context.col.surfaceElevated,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.col.textSecondary,
                  size: 20,
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearch,
            ),
          ),
          const SizedBox(height: 8),

          // Results
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _results.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(top: 32, bottom: 32 + bottom),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: context.col.textMuted,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _ctrl.text.length < 2
                              ? 'Type to search places'
                              : 'No results found',
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 16 + bottom),
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final place = _results[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              place.imageUrl != null &&
                                  place.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: place.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorWidget: (ctx, err, child) =>
                                      _PlaceIcon(category: place.category),
                                )
                              : _PlaceIcon(category: place.category),
                        ),
                        title: Text(
                          place.name,
                          style: TextStyle(
                            color: context.col.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          [
                            _catLabel(place.category),
                            if (place.district != null) place.district!,
                          ].join(' · '),
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, place.toOption()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _catLabel(String cat) {
    switch (cat) {
      case 'cafe':
        return '☕ Café';
      case 'restaurant':
        return '🍽️ Restaurant';
      case 'hotel':
        return '🏨 Hotel';
      case 'homestay':
        return '🏠 Homestay';
      default:
        return '🏔️ Spot';
    }
  }
}

class _PlaceIcon extends StatelessWidget {
  final String category;
  const _PlaceIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = switch (category) {
      'cafe' => const Color(0xFF8D6E63),
      'restaurant' => const Color(0xFFEF5350),
      'hotel' => AppColors.secondary,
      'homestay' => AppColors.warning,
      _ => const Color(0xFF4CAF50),
    };
    return Container(
      width: 48,
      height: 48,
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(Icons.place_rounded, color: color, size: 22),
    );
  }
}
