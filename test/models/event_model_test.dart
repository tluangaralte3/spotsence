// test/models/event_model_test.dart
//
// Unit tests for EventModel – derived helpers and static utilities.
// Firebase/Firestore I/O is excluded (requires integration test setup).

import 'package:flutter_test/flutter_test.dart';
import 'package:xplooria/models/event_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

EventModel _makeEvent({
  String id = 'e1',
  String title = 'Test Event',
  String description = 'A test event',
  String location = 'Aizawl',
  DateTime? date,
  DateTime? endDate,
  String time = '10:00 AM',
  int attendees = 0,
  String category = 'cultural',
  String type = 'cultural',
  String status = 'Published',
  bool featured = false,
  bool ticketingEnabled = false,
  double? ticketPrice,
  int? totalTickets,
  int ticketsBooked = 0,
  DateTime? ticketingDeadline,
}) =>
    EventModel(
      id: id,
      title: title,
      description: description,
      location: location,
      date: date,
      endDate: endDate,
      time: time,
      attendees: attendees,
      category: category,
      imageUrl: '',
      type: type,
      status: status,
      featured: featured,
      ticketingEnabled: ticketingEnabled,
      ticketPrice: ticketPrice,
      totalTickets: totalTickets,
      ticketsBooked: ticketsBooked,
      ticketingDeadline: ticketingDeadline,
    );

void main() {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 2));
  final tomorrow = now.add(const Duration(days: 2));
  final nextWeek = now.add(const Duration(days: 7));

  // ── isUpcoming ─────────────────────────────────────────────────────────────

  group('isUpcoming', () {
    test('returns true for a future date', () {
      final event = _makeEvent(date: tomorrow);
      expect(event.isUpcoming, isTrue);
    });

    test('returns false for a past date', () {
      final event = _makeEvent(date: yesterday);
      expect(event.isUpcoming, isFalse);
    });

    test('returns false when date is null', () {
      final event = _makeEvent();
      expect(event.isUpcoming, isFalse);
    });
  });

  // ── isPast ─────────────────────────────────────────────────────────────────

  group('isPast', () {
    test('returns true when date is in the past', () {
      final event = _makeEvent(date: yesterday);
      expect(event.isPast, isTrue);
    });

    test('returns false for a future event', () {
      final event = _makeEvent(date: tomorrow);
      expect(event.isPast, isFalse);
    });

    test('uses endDate as boundary when provided', () {
      // start: yesterday, end: tomorrow → NOT yet past
      final event = _makeEvent(date: yesterday, endDate: tomorrow);
      expect(event.isPast, isFalse);
    });

    test('returns false when date is null', () {
      final event = _makeEvent();
      expect(event.isPast, isFalse);
    });
  });

  // ── isOngoing ─────────────────────────────────────────────────────────────

  group('isOngoing', () {
    test('returns true when now is between start and end', () {
      final event = _makeEvent(date: yesterday, endDate: tomorrow);
      expect(event.isOngoing, isTrue);
    });

    test('returns false when event has ended', () {
      final twoDaysAgo = now.subtract(const Duration(days: 3));
      final event = _makeEvent(date: twoDaysAgo, endDate: yesterday);
      expect(event.isOngoing, isFalse);
    });

    test('returns false when date is null', () {
      final event = _makeEvent();
      expect(event.isOngoing, isFalse);
    });
  });

  // ── Ticketing: ticketsRemaining ────────────────────────────────────────────

  group('ticketsRemaining', () {
    test('returns null when ticketing is disabled', () {
      final event = _makeEvent(totalTickets: 100, ticketsBooked: 10);
      expect(event.ticketsRemaining, isNull);
    });

    test('returns null when totalTickets is null (unlimited)', () {
      final event = _makeEvent(ticketingEnabled: true, ticketsBooked: 5);
      expect(event.ticketsRemaining, isNull);
    });

    test('returns correct remaining count', () {
      final event = _makeEvent(
        ticketingEnabled: true,
        totalTickets: 100,
        ticketsBooked: 40,
      );
      expect(event.ticketsRemaining, 60);
    });

    test('clamps to 0 when overbooked', () {
      final event = _makeEvent(
        ticketingEnabled: true,
        totalTickets: 50,
        ticketsBooked: 60,
      );
      expect(event.ticketsRemaining, 0);
    });
  });

  // ── isSoldOut ──────────────────────────────────────────────────────────────

  group('isSoldOut', () {
    test('returns true when ticketsRemaining is 0', () {
      final event = _makeEvent(
        ticketingEnabled: true,
        totalTickets: 10,
        ticketsBooked: 10,
      );
      expect(event.isSoldOut, isTrue);
    });

    test('returns false when seats remain', () {
      final event = _makeEvent(
        ticketingEnabled: true,
        totalTickets: 10,
        ticketsBooked: 5,
      );
      expect(event.isSoldOut, isFalse);
    });

    test('returns false when ticketing is disabled', () {
      final event = _makeEvent(
        totalTickets: 10,
        ticketsBooked: 10,
      );
      expect(event.isSoldOut, isFalse);
    });
  });

  // ── isFree ────────────────────────────────────────────────────────────────

  group('isFree', () {
    test('returns true when ticketing enabled and price is null', () {
      final event = _makeEvent(ticketingEnabled: true, ticketPrice: null);
      expect(event.isFree, isTrue);
    });

    test('returns true when ticketing enabled and price is 0', () {
      final event = _makeEvent(ticketingEnabled: true, ticketPrice: 0);
      expect(event.isFree, isTrue);
    });

    test('returns false when price is set', () {
      final event = _makeEvent(ticketingEnabled: true, ticketPrice: 100);
      expect(event.isFree, isFalse);
    });

    test('returns false when ticketing is not enabled', () {
      final event = _makeEvent(ticketPrice: null);
      expect(event.isFree, isFalse);
    });
  });

  // ── canBookTicket ─────────────────────────────────────────────────────────

  group('canBookTicket', () {
    test('returns false when ticketing is disabled', () {
      final event = _makeEvent(date: tomorrow);
      expect(event.canBookTicket, isFalse);
    });

    test('returns false when sold out', () {
      final event = _makeEvent(
        ticketingEnabled: true,
        totalTickets: 5,
        ticketsBooked: 5,
        date: tomorrow,
      );
      expect(event.canBookTicket, isFalse);
    });

    test('returns false when deadline has passed', () {
      final event = _makeEvent(
        ticketingEnabled: true,
        date: tomorrow,
        ticketingDeadline: yesterday,
      );
      expect(event.canBookTicket, isFalse);
    });

    test('returns true for an upcoming ticketed event with seats', () {
      final event = _makeEvent(
        ticketingEnabled: true,
        totalTickets: 100,
        ticketsBooked: 10,
        date: tomorrow,
        ticketingDeadline: nextWeek,
      );
      expect(event.canBookTicket, isTrue);
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('preserves unchanged fields', () {
      final original = _makeEvent(title: 'Original', attendees: 20);
      final copy = original.copyWith(title: 'Updated');
      expect(copy.title, 'Updated');
      expect(copy.attendees, 20);
      expect(copy.id, original.id);
    });

    test('can update multiple fields', () {
      final original = _makeEvent(status: 'Draft', featured: false);
      final copy = original.copyWith(status: 'Published', featured: true);
      expect(copy.status, 'Published');
      expect(copy.featured, isTrue);
    });
  });

  // ── Static helpers ────────────────────────────────────────────────────────

  group('typeEmoji', () {
    test('returns correct emoji for known types', () {
      expect(EventModel.typeEmoji('festival'), '🎉');
      expect(EventModel.typeEmoji('cultural'), '🎭');
      expect(EventModel.typeEmoji('adventure'), '🧗');
      expect(EventModel.typeEmoji('personal'), '👤');
      expect(EventModel.typeEmoji('sports'), '⚽');
      expect(EventModel.typeEmoji('music'), '🎵');
      expect(EventModel.typeEmoji('food'), '🍽️');
    });

    test('returns calendar emoji for unknown type', () {
      expect(EventModel.typeEmoji('unknown'), '📅');
      expect(EventModel.typeEmoji(''), '📅');
    });

    test('is case-insensitive', () {
      expect(EventModel.typeEmoji('FESTIVAL'), '🎉');
      expect(EventModel.typeEmoji('Cultural'), '🎭');
    });
  });

  group('typeLabel', () {
    test('returns correct label for known types', () {
      expect(EventModel.typeLabel('festival'), 'Festival');
      expect(EventModel.typeLabel('food'), 'Food & Drink');
    });

    test('returns raw type string for unknown type', () {
      expect(EventModel.typeLabel('gala'), 'gala');
    });

    test('returns "Event" for empty type string', () {
      expect(EventModel.typeLabel(''), 'Event');
    });
  });

  // ── Default field values ──────────────────────────────────────────────────

  group('default field values', () {
    test('ticketingEnabled defaults to false', () {
      final event = _makeEvent();
      expect(event.ticketingEnabled, isFalse);
    });

    test('tickettCurrency defaults to INR', () {
      final event = _makeEvent();
      expect(event.ticketCurrency, 'INR');
    });

    test('ticketsBooked defaults to 0', () {
      final event = _makeEvent();
      expect(event.ticketsBooked, 0);
    });

    test('featured defaults to false', () {
      final event = _makeEvent();
      expect(event.featured, isFalse);
    });

    test('tags defaults to empty list', () {
      final event = _makeEvent();
      expect(event.tags, isEmpty);
    });
  });
}
