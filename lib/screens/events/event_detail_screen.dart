import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EventDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class EventDetailScreen extends ConsumerWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventDetailProvider(id));
    return async.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(error: e.toString()),
      data: (event) {
        if (event == null) {
          return const _ErrorScaffold(error: 'Event not found.');
        }
        return _EventBody(event: event);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────────────────────────────────────

class _EventBody extends StatelessWidget {
  final EventModel event;
  const _EventBody({required this.event});

  Color get _typeColor {
    switch (event.type.toLowerCase()) {
      case 'festival':
        return AppColors.accent;
      case 'cultural':
        return AppColors.secondary;
      case 'adventure':
        return AppColors.success;
      case 'music':
        return const Color(0xFFEC4899);
      case 'sports':
        return AppColors.info;
      case 'food':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _typeColor;
    final e = event;
    final formattedDate = e.date != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(e.date!)
        : '';
    final formattedEndDate = e.endDate != null
        ? DateFormat('MMMM d, yyyy').format(e.endDate!)
        : '';
    final isMultiDay =
        e.endDate != null && e.date != null && e.endDate!.day != e.date!.day;

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero image + app bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.col.bg,
            leading: _BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroSection(event: e, typeColor: tc),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status bar ──────────────────────────────────────────
                _StatusBar(event: e, typeColor: tc),

                // ── Title + badges ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeBadge(
                            label: EventModel.typeLabel(e.type),
                            color: tc,
                          ),
                          if (e.featured) ...[
                            const SizedBox(width: 8),
                            _TypeBadge(
                              label: '⭐ Featured',
                              color: AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        e.title,
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Quick-info cards ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _QuickInfoGrid(
                    event: e,
                    formattedDate: formattedDate,
                    formattedEndDate: formattedEndDate,
                    isMultiDay: isMultiDay,
                    typeColor: tc,
                  ),
                ),

                // ── Tags ────────────────────────────────────────────────
                if (e.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: e.tags.map((t) => _Tag(label: '#$t')).toList(),
                    ),
                  ),

                // ── Description ─────────────────────────────────────────
                if (e.description.isNotEmpty)
                  _Section(
                    title: 'About this event',
                    child: Text(
                      e.description,
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 14,
                        height: 1.65,
                      ),
                    ),
                  ),

                // ── Attendees ───────────────────────────────────────────
                if (e.attendees > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _AttendeeBar(attendees: e.attendees),
                  ),

                // ── Ticketing block ─────────────────────────────────────
                if (e.ticketingEnabled)
                  _Section(
                    title: 'Tickets',
                    child: _TicketingBlock(event: e),
                  ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom CTA ──────────────────────────────────────────────────────
      bottomNavigationBar: _BottomCta(event: e, typeColor: tc),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final EventModel event;
  final Color typeColor;
  const _HeroSection({required this.event, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        event.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    _PlaceholderHero(typeColor: typeColor, event: event),
                errorWidget: (_, __, ___) =>
                    _PlaceholderHero(typeColor: typeColor, event: event),
              )
            : _PlaceholderHero(typeColor: typeColor, event: event),
        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              stops: const [0.45, 1.0],
            ),
          ),
        ),
        // Bottom date pill
        if (event.date != null)
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DateFormat('MMM d, yyyy').format(event.date!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaceholderHero extends StatelessWidget {
  final Color typeColor;
  final EventModel event;
  const _PlaceholderHero({required this.typeColor, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: typeColor.withValues(alpha: 0.18),
      child: Center(
        child: Text(
          EventModel.typeEmoji(event.type),
          style: const TextStyle(fontSize: 72),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status bar  (ongoing / upcoming / past pill)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final EventModel event;
  final Color typeColor;
  const _StatusBar({required this.event, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    if (event.isOngoing) {
      label = 'Happening Now';
      color = AppColors.success;
      icon = Icons.fiber_manual_record_rounded;
    } else if (event.isUpcoming) {
      label = 'Upcoming';
      color = typeColor;
      icon = Icons.access_time_rounded;
    } else {
      label = 'Past Event';
      color = AppColors.textMuted;
      icon = Icons.history_rounded;
    }

    return Container(
      color: color.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          if (event.isOngoing) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick info grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickInfoGrid extends StatelessWidget {
  final EventModel event;
  final String formattedDate;
  final String formattedEndDate;
  final bool isMultiDay;
  final Color typeColor;

  const _QuickInfoGrid({
    required this.event,
    required this.formattedDate,
    required this.formattedEndDate,
    required this.isMultiDay,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <_InfoTile>[];

    if (formattedDate.isNotEmpty) {
      tiles.add(
        _InfoTile(
          icon: Icons.calendar_today_outlined,
          label: isMultiDay ? 'Start Date' : 'Date',
          value: formattedDate,
          iconColor: typeColor,
        ),
      );
    }

    if (isMultiDay && formattedEndDate.isNotEmpty) {
      tiles.add(
        _InfoTile(
          icon: Icons.event_outlined,
          label: 'End Date',
          value: formattedEndDate,
          iconColor: typeColor,
        ),
      );
    }

    if (event.time.isNotEmpty) {
      final timeStr = event.endTime.isNotEmpty
          ? '${event.time} – ${event.endTime}'
          : event.time;
      tiles.add(
        _InfoTile(
          icon: Icons.schedule_outlined,
          label: 'Time',
          value: timeStr,
          iconColor: typeColor,
        ),
      );
    }

    if (event.location.isNotEmpty) {
      tiles.add(
        _InfoTile(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: event.location,
          iconColor: AppColors.error,
          onTap: () => _openMaps(event.location),
        ),
      );
    }

    if (event.category.isNotEmpty) {
      tiles.add(
        _InfoTile(
          icon: Icons.category_outlined,
          label: 'Category',
          value: event.category,
          iconColor: AppColors.secondary,
        ),
      );
    }

    if (event.attendees > 0) {
      tiles.add(
        _InfoTile(
          icon: Icons.people_outline,
          label: 'Attending',
          value: '${event.attendees} people',
          iconColor: AppColors.primary,
        ),
      );
    }

    return Column(
      children:
          [
            for (int i = 0; i < tiles.length; i += 2)
              Row(
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: 12),
                  if (i + 1 < tiles.length)
                    Expanded(child: tiles[i + 1])
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ).also(
                (_) => tiles.length > 2 && i < tiles.length - 2 ? null : null,
              ),
          ].expand((w) sync* {
            yield w;
            yield const SizedBox(height: 12);
          }).toList(),
    );
  }

  Future<void> _openMaps(String location) async {
    final encoded = Uri.encodeComponent(location);
    final uri = Uri.parse('https://maps.google.com/?q=$encoded');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.col.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.col.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: onTap != null
                          ? AppColors.primary
                          : context.col.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: context.col.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendee bar
// ─────────────────────────────────────────────────────────────────────────────

class _AttendeeBar extends StatelessWidget {
  final int attendees;
  const _AttendeeBar({required this.attendees});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$attendees ',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'people are attending',
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticketing block
// ─────────────────────────────────────────────────────────────────────────────

class _TicketingBlock extends StatelessWidget {
  final EventModel event;
  const _TicketingBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event;
    final remaining = e.ticketsRemaining;
    final lowStock = remaining != null && remaining > 0 && remaining <= 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price row
        Row(
          children: [
            Text(
              e.isFree
                  ? 'FREE'
                  : '${e.ticketCurrency} ${e.ticketPrice?.toStringAsFixed(0) ?? '—'}',
              style: TextStyle(
                color: e.isFree ? AppColors.success : context.col.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!e.isFree)
              Text(
                ' / ticket',
                style: TextStyle(color: context.col.textMuted, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Availability row
        if (e.totalTickets != null) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.totalTickets! > 0
                        ? e.ticketsBooked / e.totalTickets!
                        : 0,
                    backgroundColor: context.col.border,
                    color: e.isSoldOut
                        ? AppColors.error
                        : lowStock
                        ? AppColors.warning
                        : AppColors.primary,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                e.isSoldOut
                    ? 'Sold out'
                    : lowStock
                    ? 'Only $remaining left!'
                    : '$remaining available',
                style: TextStyle(
                  color: e.isSoldOut
                      ? AppColors.error
                      : lowStock
                      ? AppColors.warning
                      : context.col.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Deadline
        if (e.ticketingDeadline != null)
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: context.col.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Book by ${DateFormat('MMM d, yyyy').format(e.ticketingDeadline!)}',
                style: TextStyle(
                  color: context.col.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom CTA
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final EventModel event;
  final Color typeColor;
  const _BottomCta({required this.event, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    final e = event;

    // No CTA for past events without ticketing
    if (e.isPast && !e.ticketingEnabled) {
      return const SizedBox.shrink();
    }

    String label;
    Color btnColor;
    bool enabled;

    if (e.ticketingEnabled) {
      if (e.isSoldOut) {
        label = 'Sold Out';
        btnColor = AppColors.textMuted;
        enabled = false;
      } else if (!e.canBookTicket) {
        label = 'Booking Closed';
        btnColor = AppColors.textMuted;
        enabled = false;
      } else {
        label = e.isFree ? 'Register Free' : 'Book Ticket';
        btnColor = typeColor;
        enabled = true;
      }
    } else {
      label = 'Add to Calendar';
      btnColor = typeColor;
      enabled = !e.isPast;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: context.col.bg,
          border: Border(top: BorderSide(color: context.col.border)),
        ),
        child: Row(
          children: [
            // Attendees compact
            if (e.attendees > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.col.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.col.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.attendees}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: enabled ? () => _onCtaTap(context, e) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enabled
                        ? btnColor
                        : context.col.surfaceElevated,
                    foregroundColor: enabled
                        ? Colors.white
                        : context.col.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  void _onCtaTap(BuildContext context, EventModel e) {
    if (e.ticketingEnabled && e.canBookTicket) {
      // TODO: navigate to ticket booking flow (phase 2)
      _showBookingComingSoon(context);
    } else {
      _showAddToCalendarSheet(context, e);
    }
  }

  void _showBookingComingSoon(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎟️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Ticket Booking Coming Soon',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'We are building an in-app ticket booking system. Stay tuned!',
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToCalendarSheet(
    BuildContext context,
    EventModel e,
  ) async {
    if (e.date == null) return;
    final date = DateFormat('yyyyMMdd').format(e.date!);
    final endDateStr = e.endDate != null
        ? DateFormat('yyyyMMdd').format(e.endDate!)
        : date;
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(e.title)}'
      '&dates=$date/$endDateStr'
      '&details=${Uri.encodeComponent(e.description)}'
      '&location=${Uri.encodeComponent(e.location)}',
    );
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: context.col.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.col.border),
    ),
    child: Text(
      label,
      style: TextStyle(color: context.col.textSecondary, fontSize: 12),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error scaffolds
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.col.bg,
    appBar: AppBar(
      backgroundColor: context.col.bg,
      leading: _BackButton(),
      elevation: 0,
    ),
    body: const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );
}

class _ErrorScaffold extends StatelessWidget {
  final String error;
  const _ErrorScaffold({required this.error});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.col.bg,
    appBar: AppBar(
      backgroundColor: context.col.bg,
      leading: _BackButton(),
      elevation: 0,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: context.col.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(color: context.col.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Go back',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Dart extension used internally
extension _Also<T> on T {
  T also(void Function(T) fn) {
    fn(this);
    return this;
  }
}
