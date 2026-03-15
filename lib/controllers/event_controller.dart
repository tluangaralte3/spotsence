import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EventState  — holds the full list + loading flags
// ─────────────────────────────────────────────────────────────────────────────

class EventState {
  final List<EventModel> items;
  final bool isLoading;
  final String? error;

  const EventState({this.items = const [], this.isLoading = false, this.error});

  EventState copyWith({
    List<EventModel>? items,
    bool? isLoading,
    String? error,
  }) => EventState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  // ── Derived helpers ──────────────────────────────────────────────────────

  List<EventModel> get upcoming =>
      items.where((e) => e.isUpcoming || e.isOngoing).toList();

  List<EventModel> get past => items.where((e) => e.isPast).toList();

  List<EventModel> get featured => items.where((e) => e.featured).toList();

  /// Returns events whose date falls on [day].
  List<EventModel> eventsForDay(DateTime day) => items
      .where(
        (e) =>
            e.date != null &&
            e.date!.year == day.year &&
            e.date!.month == day.month &&
            e.date!.day == day.day,
      )
      .toList();

  /// Returns every day (year/month/day only) that has at least one event.
  Set<DateTime> get eventDays => {
    for (final e in items)
      if (e.date != null) DateTime(e.date!.year, e.date!.month, e.date!.day),
  };

  /// Events grouped by month (key = DateTime(year, month)).
  Map<DateTime, List<EventModel>> get byMonth {
    final map = <DateTime, List<EventModel>>{};
    for (final e in items) {
      if (e.date == null) continue;
      final key = DateTime(e.date!.year, e.date!.month);
      (map[key] ??= []).add(e);
    }
    return map;
  }

  List<EventModel> byType(String type) =>
      items.where((e) => e.type.toLowerCase() == type.toLowerCase()).toList();

  List<EventModel> byCategory(String category) => items
      .where((e) => e.category.toLowerCase() == category.toLowerCase())
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// EventController
// ─────────────────────────────────────────────────────────────────────────────

class EventController extends Notifier<EventState> {
  @override
  EventState build() {
    Future.microtask(loadAll);
    return const EventState(isLoading: true);
  }

  EventService get _svc => ref.read(eventServiceProvider);

  /// Load all events (upcoming + past).
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _svc.getEvents(limit: 200, upcomingOnly: false);
      state = state.copyWith(isLoading: false, items: events);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load only upcoming events.
  Future<void> loadUpcoming() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _svc.getEvents(limit: 100, upcomingOnly: true);
      state = state.copyWith(isLoading: false, items: events);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load events for a specific month (uses Firestore query).
  Future<void> loadMonth(int year, int month) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _svc.getEventsForMonth(year, month);
      state = state.copyWith(isLoading: false, items: events);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadAll();
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final eventControllerProvider = NotifierProvider<EventController, EventState>(
  EventController.new,
);
