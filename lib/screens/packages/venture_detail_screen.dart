// lib/screens/packages/package_detail_screen.dart
//
// Dare & Venture — full detail screen for a single activity package.
// Sections: hero gallery, overview chips, highlights, pricing tiers,
//           schedule slots, what to expect/bring, operator info, booking CTA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/tour_venture_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tour_venture_models.dart';
import '../../services/tour_venture_service.dart';
import '../../widgets/shared_widgets.dart';

class VentureDetailScreen extends ConsumerStatefulWidget {
  final String packageId;
  const VentureDetailScreen({super.key, required this.packageId});

  @override
  ConsumerState<VentureDetailScreen> createState() =>
      _PackageDetailScreenState();
}

class _PackageDetailScreenState extends ConsumerState<VentureDetailScreen> {
  int _selectedImageIndex = 0;
  PricingTier? _selectedTier;
  ScheduleSlot? _selectedSlot;
  int _personCount = 1;

  @override
  Widget build(BuildContext context) {
    final packageAsync = ref.watch(packageDetailProvider(widget.packageId));

    return packageAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.col.bg,
        appBar: AppBar(
          backgroundColor: context.col.bg,
          leading: _backButton(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.col.bg,
        appBar: AppBar(
          backgroundColor: context.col.bg,
          leading: _backButton(context),
        ),
        body: Center(
          child: EmptyState(
            emoji: '😕',
            title: 'Venture not found',
            subtitle: '$e',
          ),
        ),
      ),
      data: (package) {
        if (package == null) {
          return Scaffold(
            backgroundColor: context.col.bg,
            appBar: AppBar(
              backgroundColor: context.col.bg,
              leading: _backButton(context),
            ),
            body: const Center(
              child: EmptyState(emoji: '⚡', title: 'Venture not found'),
            ),
          );
        }

        // Auto-select first available tier
        if (_selectedTier == null && package.pricingTiers.isNotEmpty) {
          final popular = package.pricingTiers
              .where((t) => t.isPopular && t.isAvailable)
              .toList();
          _selectedTier = popular.isNotEmpty
              ? popular.first
              : package.pricingTiers.firstWhere(
                  (t) => t.isAvailable,
                  orElse: () => package.pricingTiers.first,
                );
        }

        return Scaffold(
          backgroundColor: context.col.bg,
          body: CustomScrollView(
            slivers: [
              _HeroSliver(
                package: package,
                selectedIndex: _selectedImageIndex,
                onImageTap: (i) => setState(() => _selectedImageIndex = i),
              ),
              SliverToBoxAdapter(
                child: _DetailBody(
                  package: package,
                  selectedTier: _selectedTier,
                  selectedSlot: _selectedSlot,
                  personCount: _personCount,
                  onTierSelect: (t) => setState(() => _selectedTier = t),
                  onSlotSelect: (s) => setState(() => _selectedSlot = s),
                  onPersonCountChange: (n) => setState(() => _personCount = n),
                  onBook: () => _onBook(context, package),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Sticky bottom booking bar
          bottomNavigationBar: _BookingBar(
            package: package,
            selectedTier: _selectedTier,
            personCount: _personCount,
            onBook: () => _onBook(context, package),
          ),
        );
      },
    );
  }

  Widget _backButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    color: context.col.textPrimary,
    onPressed: () => context.pop(),
  );

  void _onBook(BuildContext context, TourVentureModel package) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book a package')),
      );
      return;
    }
    if (_selectedTier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pricing plan')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookingSheet(
        package: package,
        tier: _selectedTier!,
        slot: _selectedSlot,
        personCount: _personCount,
        userId: user.id,
        userName: user.displayName,
        service: ref.read(tourPackageServiceProvider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero image sliver with gallery dots
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSliver extends StatelessWidget {
  final TourVentureModel package;
  final int selectedIndex;
  final ValueChanged<int> onImageTap;

  const _HeroSliver({
    required this.package,
    required this.selectedIndex,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = package.images.isEmpty ? <String>[] : package.images;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: context.col.bg,
      leading: Padding(
        padding: const EdgeInsets.all(6),
        child: CircleAvatar(
          backgroundColor: Colors.black54,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white,
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Main image
            images.isEmpty
                ? Container(
                    color: context.col.surfaceElevated,
                    child: Center(
                      child: Text(
                        package.category.emoji,
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                  )
                : PageView.builder(
                    itemCount: images.length,
                    onPageChanged: onImageTap,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: context.col.surfaceElevated),
                      errorWidget: (_, __, ___) => Container(
                        color: context.col.surfaceElevated,
                        child: Center(
                          child: Text(
                            package.category.emoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    ),
                  ),

            // Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Image dots
            if (images.length > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == selectedIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == selectedIndex
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail body
// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final TourVentureModel package;
  final PricingTier? selectedTier;
  final ScheduleSlot? selectedSlot;
  final int personCount;
  final ValueChanged<PricingTier> onTierSelect;
  final ValueChanged<ScheduleSlot?> onSlotSelect;
  final ValueChanged<int> onPersonCountChange;
  final VoidCallback onBook;

  const _DetailBody({
    required this.package,
    required this.selectedTier,
    required this.selectedSlot,
    required this.personCount,
    required this.onTierSelect,
    required this.onSlotSelect,
    required this.onPersonCountChange,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────────────────────────
          Text(
            package.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.col.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            package.tagline,
            style: TextStyle(
              fontSize: 14,
              color: context.col.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 14),

          // ── Overview chips ─────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: package.durationLabel,
              ),
              _InfoChip(icon: Icons.place_outlined, label: package.location),
              _InfoChip(
                icon: Icons.departure_board_rounded,
                label: package.departurePeriod,
              ),
              if (package.maxGroupSize > 0)
                _InfoChip(
                  icon: Icons.group_outlined,
                  label: 'Max ${package.maxGroupSize} pax',
                ),
              if (package.minAge > 0)
                _InfoChip(
                  icon: Icons.child_care_rounded,
                  label: '${package.minAge}+ years',
                ),
              if (package.languages.isNotEmpty)
                _InfoChip(
                  icon: Icons.language_rounded,
                  label: package.languages.join(', '),
                ),
              _InfoChip(
                icon: Icons.fitness_center_rounded,
                label: package.difficulty.label,
                color: Color(package.difficulty.colorHex),
              ),
              if (package.instantBooking)
                _InfoChip(
                  icon: Icons.bolt,
                  label: 'Instant Booking',
                  color: AppColors.accent,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Seasons ────────────────────────────────────────────────────
          if (package.seasons.isNotEmpty) ...[
            _SectionTitle('📅 Best Seasons'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: package.seasons
                  .map((s) => _SeasonBadge(season: s))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── Rating + reviews ───────────────────────────────────────────
          if (package.averageRating > 0) ...[
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFBBF24),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  package.averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.col.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${package.ratingsCount} reviews)',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.col.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                if (package.bookingsCount > 0)
                  Text(
                    '• ${package.bookingsCount} bookings',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.col.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          _Divider(),

          // ── Description ────────────────────────────────────────────────
          _SectionTitle('About this Experience'),
          const SizedBox(height: 8),
          Text(
            package.description,
            style: TextStyle(
              fontSize: 14,
              color: context.col.textSecondary,
              height: 1.6,
            ),
          ),

          // ── Highlights ─────────────────────────────────────────────────
          if (package.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Divider(),
            _SectionTitle('✨ Highlights'),
            const SizedBox(height: 10),
            ...package.highlights.map(
              (h) => _BulletItem(text: h, color: AppColors.primary),
            ),
          ],

          // ── Pricing tiers ──────────────────────────────────────────────
          if (package.pricingTiers.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Divider(),
            _SectionTitle('💰 Choose Your Plan'),
            const SizedBox(height: 4),
            Text(
              'Select the package that suits your group size',
              style: TextStyle(fontSize: 12, color: context.col.textSecondary),
            ),
            const SizedBox(height: 12),
            ...package.pricingTiers.map(
              (tier) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PricingTierCard(
                  tier: tier,
                  isSelected: selectedTier?.id == tier.id,
                  onTap: tier.isAvailable ? () => onTierSelect(tier) : null,
                ),
              ),
            ),
          ],

          // ── Person count selector ──────────────────────────────────────
          if (selectedTier != null) ...[
            const SizedBox(height: 4),
            _PersonCountSelector(
              count: personCount,
              min: selectedTier!.minPersons,
              max: selectedTier!.maxPersons,
              onChanged: onPersonCountChange,
            ),
          ],

          // ── Schedule slots ─────────────────────────────────────────────
          if (package.scheduleSlots.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Divider(),
            _SectionTitle('🕐 Time Slots'),
            const SizedBox(height: 12),
            ...package.scheduleSlots.map(
              (slot) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SlotCard(
                  slot: slot,
                  isSelected: selectedSlot?.id == slot.id,
                  onTap: slot.isFull
                      ? null
                      : () => onSlotSelect(
                          selectedSlot?.id == slot.id ? null : slot,
                        ),
                ),
              ),
            ),
          ],

          // ── What to expect ─────────────────────────────────────────────
          if (package.whatToExpect.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Divider(),
            _SectionTitle('🔍 What to Expect'),
            const SizedBox(height: 10),
            ...package.whatToExpect.map(
              (item) => _BulletItem(text: item, color: AppColors.secondary),
            ),
          ],

          // ── What to bring ──────────────────────────────────────────────
          if (package.whatToBring.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Divider(),
            _SectionTitle('🎒 What to Bring (Gear Up)'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: package.whatToBring
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.col.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.col.border),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.col.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // ── Cancellation policy ────────────────────────────────────────
          if (package.cancellationPolicy.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Divider(),
            _SectionTitle('📋 Cancellation Policy'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      package.cancellationPolicy,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.col.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Operator info ──────────────────────────────────────────────
          if (package.operator != null) ...[
            const SizedBox(height: 16),
            _Divider(),
            _OperatorCard(operator: package.operator!),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pricing tier card
// ─────────────────────────────────────────────────────────────────────────────

class _PricingTierCard extends StatelessWidget {
  final PricingTier tier;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PricingTierCard({
    required this.tier,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unavailable = !tier.isAvailable;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.col.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: unavailable ? 0.5 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Radio
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : context.col.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tier.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : context.col.textPrimary,
                      ),
                    ),
                  ),
                  // Popular badge
                  if (tier.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🔥 Popular',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  // Unavailable badge
                  if (unavailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.col.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Sold Out',
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Person range
              Text(
                '${tier.minPersons == tier.maxPersons ? '${tier.minPersons} person${tier.minPersons > 1 ? 's' : ''}' : '${tier.minPersons}–${tier.maxPersons} persons'}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.col.textSecondary,
                ),
              ),

              if (tier.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  tier.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.col.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${tier.pricePerPerson.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? AppColors.primary
                          : context.col.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '/ person',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.col.textMuted,
                      ),
                    ),
                  ),
                ],
              ),

              // Includes / excludes
              if (tier.includes.isNotEmpty) ...[
                const SizedBox(height: 10),
                const _MiniLabel('✅ Includes'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tier.includes
                      .map(
                        (item) =>
                            _MiniChip(label: item, color: AppColors.success),
                      )
                      .toList(),
                ),
              ],
              if (tier.excludes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _MiniLabel('❌ Excludes'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tier.excludes
                      .map(
                        (item) =>
                            _MiniChip(label: item, color: AppColors.error),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Person count selector
// ─────────────────────────────────────────────────────────────────────────────

class _PersonCountSelector extends StatelessWidget {
  final int count;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _PersonCountSelector({
    required this.count,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Number of Persons',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.col.textPrimary,
              ),
            ),
          ),
          // Decrement
          _CountButton(
            icon: Icons.remove,
            onTap: count > min ? () => onChanged(count - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          // Increment
          _CountButton(
            icon: Icons.add,
            onTap: count < max ? () => onChanged(count + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CountButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withOpacity(0.12)
              : context.col.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.primary : context.col.border,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : context.col.textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule slot card
// ─────────────────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final ScheduleSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SlotCard({required this.slot, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final full = slot.isFull;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.1)
              : context.col.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : context.col.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: full ? 0.5 : 1.0,
          child: Row(
            children: [
              // Time range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.secondary
                            : context.col.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slot.startTime} – ${slot.endTime}  •  ${slot.durationHours}h',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.col.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Spots left / full badge
              if (full)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Full',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${slot.spotsLeft} left',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────────────────────
// Operator info card
// ─────────────────────────────────────────────────────────────────────────────

class _OperatorCard extends StatelessWidget {
  final OperatorInfo operator;
  const _OperatorCard({required this.operator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('🏢 About the Operator'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.col.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.col.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo or initial
                  operator.logoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: operator.logoUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              operator.name.isNotEmpty
                                  ? operator.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                operator.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: context.col.textPrimary,
                                ),
                              ),
                            ),
                            if (operator.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (operator.rating > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFBBF24),
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${operator.rating.toStringAsFixed(1)} (${operator.totalReviews} reviews)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.col.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Contact info
              if (operator.phone.isNotEmpty ||
                  operator.email.isNotEmpty ||
                  operator.whatsapp.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (operator.phone.isNotEmpty)
                      _ContactChip(
                        icon: Icons.phone_outlined,
                        label: operator.phone,
                        color: AppColors.success,
                      ),
                    if (operator.whatsapp.isNotEmpty)
                      _ContactChip(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                      ),
                    if (operator.email.isNotEmpty)
                      _ContactChip(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        color: AppColors.info,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky booking bar
// ─────────────────────────────────────────────────────────────────────────────

class _BookingBar extends StatelessWidget {
  final TourVentureModel package;
  final PricingTier? selectedTier;
  final int personCount;
  final VoidCallback onBook;

  const _BookingBar({
    required this.package,
    required this.selectedTier,
    required this.personCount,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final total = selectedTier != null
        ? selectedTier!.pricePerPerson * personCount
        : package.startingPrice;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.col.surface,
        border: Border(top: BorderSide(color: context.col.border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedTier != null ? 'Total' : 'Starting from',
                style: TextStyle(fontSize: 11, color: context.col.textMuted),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              if (selectedTier != null)
                Text(
                  '${personCount} person${personCount > 1 ? 's' : ''} × ₹${selectedTier!.pricePerPerson.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: context.col.textMuted),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: package.isAvailable ? onBook : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: context.col.border,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                package.isAvailable
                    ? (package.instantBooking
                          ? '⚡ Dare It — Book Now'
                          : '📩 Request Your Venture')
                    : 'Not Available',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
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
// Booking confirmation sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingSheet extends ConsumerStatefulWidget {
  final TourVentureModel package;
  final PricingTier tier;
  final ScheduleSlot? slot;
  final int personCount;
  final String userId;
  final String userName;
  final TourVentureService service;

  const _BookingSheet({
    required this.package,
    required this.tier,
    required this.slot,
    required this.personCount,
    required this.userId,
    required this.userName,
    required this.service,
  });

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.tier.pricePerPerson * widget.personCount;

    return Container(
      decoration: BoxDecoration(
        color: context.col.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.col.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Confirm Your Venture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.col.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Summary box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _SummaryRow('Package', widget.package.title),
                  _SummaryRow('Plan', widget.tier.name),
                  _SummaryRow('Persons', '${widget.personCount}'),
                  if (widget.slot != null)
                    _SummaryRow('Slot', widget.slot!.label),
                  _SummaryRow(
                    'Total',
                    '₹${total.toStringAsFixed(0)}',
                    highlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Preferred date
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _preferredDate,
                  firstDate: DateTime.now().add(
                    Duration(days: widget.package.advanceBookingDays),
                  ),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _preferredDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: context.col.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.col.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Preferred Date: ${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.col.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Phone
            _InputField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: '+91 98765 43210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 10),

            // Email
            _InputField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 10),

            // Notes
            _InputField(
              controller: _notesCtrl,
              label: 'Special Requests (optional)',
              hint: 'Any dietary requirements, special occasions…',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        widget.package.instantBooking
                            ? '⚡ Confirm & Dare It'
                            : '📩 Send Venture Request',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.service.submitBookingRequest(
        packageId: widget.package.id,
        userId: widget.userId,
        userName: widget.userName,
        userPhone: _phoneCtrl.text.trim(),
        userEmail: _emailCtrl.text.trim(),
        tierId: widget.tier.id,
        tierName: widget.tier.name,
        numberOfPersons: widget.personCount,
        preferredDate: _preferredDate,
        slotId: widget.slot?.id ?? '',
        notes: _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            widget.package.instantBooking
                ? '✅ Venture confirmed! The operator will contact you.'
                : '📩 Request sent! You\'ll hear back within 24 hours.',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Failed to submit: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: context.col.textPrimary,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, color: context.col.border),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.col.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? context.col.surfaceElevated).withOpacity(
          color != null ? 0.12 : 1.0,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color != null ? color!.withOpacity(0.3) : context.col.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonBadge extends StatelessWidget {
  final PackageSeason season;
  const _SeasonBadge({required this.season});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Text(
        '${season.emoji}  ${season.label}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: context.col.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;
  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: context.col.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: context.col.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.primary : context.col.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: context.col.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.col.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: context.col.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: context.col.textMuted),
        filled: true,
        fillColor: context.col.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
