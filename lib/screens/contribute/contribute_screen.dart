import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/gamification_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gamification_models.dart';
import '../../services/community_service.dart';

/// Multi-step form to submit a new tourist spot.
/// Step 1 → Details (name, category, description)
/// Step 2 → Location (city, address, lat/lng hint)
/// Step 3 → Photos (up to 5)
/// Step 4 → Review & Submit
class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key});

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _submitting = false;

  // Step 1 – Details
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'waterfall';

  // Step 2 – Location
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  // Step 3 – Photos
  final List<XFile> _photos = [];

  static const _steps = ['Details', 'Location', 'Photos', 'Submit'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty &&
            _descCtrl.text.trim().length >= 20;
      case 1:
        return _cityCtrl.text.trim().isNotEmpty;
      case 2:
        return true; // photos optional
      default:
        return true;
    }
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 5) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 75);
    if (picked.isNotEmpty) {
      setState(() {
        _photos.addAll(picked.take(5 - _photos.length));
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final service = ref.read(communityServiceProvider);
    final error = await service.createContribution(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      lat: double.tryParse(_latCtrl.text),
      lng: double.tryParse(_lngCtrl.text),
      photos: _photos,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (error == null) {
        // Award XP and increment contribution counter
        await ref
            .read(gamificationControllerProvider.notifier)
            .award(XpAction.submitContribution);
        await ref
            .read(gamificationControllerProvider.notifier)
            .incrementCounter('contributionsCount');

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: context.col.surfaceElevated,
            title: const Text('🎉 Spot Submitted!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your contribution is under review. '
                  'Thank you for helping grow the map!',
                  style: TextStyle(color: context.col.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        '+20 XP Earned',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contribute a Spot – Step ${_step + 1}/${_steps.length}'),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _back,
              )
            : null,
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(current: _step, steps: _steps),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DetailsStep(
                  nameCtrl: _nameCtrl,
                  descCtrl: _descCtrl,
                  category: _category,
                  onCategoryChanged: (c) => setState(() => _category = c),
                ),
                _LocationStep(
                  cityCtrl: _cityCtrl,
                  addressCtrl: _addressCtrl,
                  latCtrl: _latCtrl,
                  lngCtrl: _lngCtrl,
                ),
                _PhotosStep(
                  photos: _photos,
                  onPick: _pickPhotos,
                  onRemove: (i) => setState(() => _photos.removeAt(i)),
                ),
                _ReviewStep(
                  name: _nameCtrl.text,
                  desc: _descCtrl.text,
                  category: _category,
                  city: _cityCtrl.text,
                  address: _addressCtrl.text,
                  photoCount: _photos.length,
                ),
              ],
            ),
          ),

          // Bottom action
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canProceed && !_submitting)
                    ? (_step == _steps.length - 1 ? _submit : _next)
                    : null,
                child: _submitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.col.bg,
                        ),
                      )
                    : Text(_step == _steps.length - 1 ? 'Submit Spot' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final List<String> steps;
  const _StepIndicator({required this.current, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Divider line
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < current
                    ? AppColors.primary
                    : context.col.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < current;
          final active = stepIndex == current;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? AppColors.primary : context.col.surface,
                  border: Border.all(
                    color: done || active
                        ? AppColors.primary
                        : context.col.border,
                  ),
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : context.col.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 9,
                  color: active ? AppColors.primary : context.col.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Details ─────────────────────────────────────────────────────────

class _DetailsStep extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String category;
  final ValueChanged<String> onCategoryChanged;

  const _DetailsStep({
    required this.nameCtrl,
    required this.descCtrl,
    required this.category,
    required this.onCategoryChanged,
  });

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> {
  @override
  void initState() {
    super.initState();
    widget.nameCtrl.addListener(() => setState(() {}));
    widget.descCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Tell us about this spot',
          style: TextStyle(color: context.col.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: widget.nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Spot Name *',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: 16),

        // Category selector
        Text('Category', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.categories.where((c) => c['id'] != 'all').map((
            c,
          ) {
            final selected = widget.category == c['id'];
            return GestureDetector(
              onTap: () => widget.onCategoryChanged(c['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(0.15)
                      : context.col.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : context.col.border,
                  ),
                ),
                child: Text(
                  '${c['emoji']} ${c['label']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    color: selected
                        ? AppColors.primary
                        : context.col.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: widget.descCtrl,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Description * (min 20 chars)',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
      ],
    );
  }
}

// ─── Step 2: Location ─────────────────────────────────────────────────────────

class _LocationStep extends StatelessWidget {
  final TextEditingController cityCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;

  const _LocationStep({
    required this.cityCtrl,
    required this.addressCtrl,
    required this.latCtrl,
    required this.lngCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Where is this spot?',
          style: TextStyle(color: context.col.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: cityCtrl,
          decoration: const InputDecoration(
            labelText: 'City / District *',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: addressCtrl,
          decoration: const InputDecoration(
            labelText: 'Address (optional)',
            prefixIcon: Icon(Icons.map_outlined),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: latCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  prefixIcon: Icon(Icons.north_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: lngCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  prefixIcon: Icon(Icons.east_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '💡 Tip: You can find coordinates in Google Maps by long-pressing a location.',
          style: TextStyle(
            color: context.col.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Step 3: Photos ───────────────────────────────────────────────────────────

class _PhotosStep extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  const _PhotosStep({
    required this.photos,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add some photos (optional, max 5)',
            style: TextStyle(color: context.col.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Photo grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...photos.asMap().entries.map((e) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(e.value.path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(e.key),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // Add photo button
              if (photos.length < 5)
                GestureDetector(
                  onTap: onPick,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.col.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Review ───────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final String name;
  final String desc;
  final String category;
  final String city;
  final String address;
  final int photoCount;

  const _ReviewStep({
    required this.name,
    required this.desc,
    required this.category,
    required this.city,
    required this.address,
    required this.photoCount,
  });

  @override
  Widget build(BuildContext context) {
    final cat = AppConstants.categories.firstWhere(
      (c) => c['id'] == category,
      orElse: () => {'emoji': '📍', 'label': category},
    );

    final rows = [
      {'label': 'Name', 'value': name},
      {'label': 'Category', 'value': '${cat['emoji']} ${cat['label']}'},
      {
        'label': 'Description',
        'value': desc.length > 80 ? '${desc.substring(0, 80)}…' : desc,
      },
      {'label': 'City', 'value': city},
      if (address.isNotEmpty) {'label': 'Address', 'value': address},
      {'label': 'Photos', 'value': '$photoCount photo(s) added'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Review your submission',
          style: TextStyle(color: context.col.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: context.col.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.col.border),
          ),
          child: Column(
            children: rows.asMap().entries.map((e) {
              final isLast = e.key == rows.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: context.col.border),
                        ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        e.value['label']!,
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value['value']!,
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Earn +10 XP now and +100 XP when your spot gets approved by an admin!',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
