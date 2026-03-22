import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EventModel
//
// Mirrors the Firestore `events` collection schema:
//   attendees, category, createdAt, createdBy, date, description,
//   endDate, endTime, featured, imageUrl, location, status,
//   tags[], time, title, type, updatedAt
//
// Ticket-booking fields (used in a future phase):
//   ticketingEnabled  — bool: whether the event has bookable tickets
//   ticketPrice       — num?: price per ticket (null = free)
//   ticketCurrency    — String: currency code (default 'INR')
//   totalTickets      — int?: total capacity (null = unlimited)
//   ticketsBooked     — int: seats already taken
//   ticketingDeadline — DateTime?: last date to book
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class EventModel {
  // ── Core fields ─────────────────────────────────────────────────────────
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime? date; // event start date
  final DateTime? endDate; // event end date (optional)
  final String time; // e.g. "10:00 AM"
  final String endTime; // e.g. "5:00 PM"
  final int attendees;
  final String category;
  final String imageUrl;
  final String type; // 'festival' | 'cultural' | 'adventure' | 'personal'
  final String status; // 'Published' | 'Draft'
  final List<String> tags;
  final bool featured;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Ticketing fields (phase 2) ───────────────────────────────────────────
  final bool ticketingEnabled;
  final double? ticketPrice;
  final String ticketCurrency;
  final int? totalTickets;
  final int ticketsBooked;
  final DateTime? ticketingDeadline;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    this.endDate,
    required this.time,
    this.endTime = '',
    required this.attendees,
    required this.category,
    required this.imageUrl,
    required this.type,
    required this.status,
    this.tags = const [],
    this.featured = false,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
    // ticketing
    this.ticketingEnabled = false,
    this.ticketPrice,
    this.ticketCurrency = 'INR',
    this.totalTickets,
    this.ticketsBooked = 0,
    this.ticketingDeadline,
  });

  // ── Derived helpers ──────────────────────────────────────────────────────

  bool get isUpcoming {
    if (date == null) return false;
    return date!.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }

  bool get isOngoing {
    final now = DateTime.now();
    if (date == null) return false;
    if (endDate != null) return now.isAfter(date!) && now.isBefore(endDate!);
    return _isSameDay(now, date!);
  }

  bool get isPast {
    if (date == null) return false;
    final end = endDate ?? date!;
    return end.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Remaining tickets (null = not ticketed or unlimited).
  int? get ticketsRemaining {
    if (!ticketingEnabled) return null;
    if (totalTickets == null) return null;
    return (totalTickets! - ticketsBooked).clamp(0, totalTickets!);
  }

  bool get isSoldOut {
    final rem = ticketsRemaining;
    return rem != null && rem == 0;
  }

  bool get isFree =>
      ticketingEnabled && (ticketPrice == null || ticketPrice == 0);

  bool get canBookTicket {
    if (!ticketingEnabled) return false;
    if (isSoldOut) return false;
    if (ticketingDeadline != null && DateTime.now().isAfter(ticketingDeadline!))
      return false;
    return isUpcoming || isOngoing;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Static helpers ───────────────────────────────────────────────────────

  static String typeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'festival':
        return '🎉';
      case 'cultural':
        return '🎭';
      case 'adventure':
        return '🧗';
      case 'personal':
        return '👤';
      case 'sports':
        return '⚽';
      case 'music':
        return '🎵';
      case 'food':
        return '🍽️';
      default:
        return '📅';
    }
  }

  static String typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'festival':
        return 'Festival';
      case 'cultural':
        return 'Cultural';
      case 'adventure':
        return 'Adventure';
      case 'personal':
        return 'Personal';
      case 'sports':
        return 'Sports';
      case 'music':
        return 'Music';
      case 'food':
        return 'Food & Drink';
      default:
        return type.isEmpty ? 'Event' : type;
    }
  }

  // ── Firestore deserialization ────────────────────────────────────────────

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return EventModel(
      id: doc.id,
      title: d['title']?.toString() ?? d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      location: d['location']?.toString() ?? d['venue']?.toString() ?? '',
      date: _parseDateTime(d['date'] ?? d['eventDate'] ?? d['startDate']),
      endDate: _parseDateTime(d['endDate']),
      time: d['time']?.toString() ?? d['startTime']?.toString() ?? '',
      endTime: d['endTime']?.toString() ?? '',
      attendees:
          _toNum(d['attendees'])?.toInt() ??
          _toNum(d['attendeeCount'])?.toInt() ??
          0,
      category: d['category']?.toString() ?? '',
      imageUrl: _pickImageUrl(d),
      type: d['type']?.toString() ?? 'cultural',
      status: d['status']?.toString() ?? 'Published',
      tags: _toStringList(d['tags']),
      featured: d['featured'] == true,
      createdBy: d['createdBy']?.toString() ?? '',
      createdAt: _parseDateTime(d['createdAt']),
      updatedAt: _parseDateTime(d['updatedAt']),
      // ticketing
      ticketingEnabled: d['ticketingEnabled'] == true,
      ticketPrice: _toNum(d['ticketPrice'])?.toDouble(),
      ticketCurrency: d['ticketCurrency']?.toString() ?? 'INR',
      totalTickets: _toNum(d['totalTickets'])?.toInt(),
      ticketsBooked: _toNum(d['ticketsBooked'])?.toInt() ?? 0,
      ticketingDeadline: _parseDateTime(d['ticketingDeadline']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'location': location,
    'date': date != null ? Timestamp.fromDate(date!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'time': time,
    'endTime': endTime,
    'attendees': attendees,
    'category': category,
    'imageUrl': imageUrl,
    'type': type,
    'status': status,
    'tags': tags,
    'featured': featured,
    'createdBy': createdBy,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'ticketingEnabled': ticketingEnabled,
    'ticketPrice': ticketPrice,
    'ticketCurrency': ticketCurrency,
    'totalTickets': totalTickets,
    'ticketsBooked': ticketsBooked,
    'ticketingDeadline': ticketingDeadline != null
        ? Timestamp.fromDate(ticketingDeadline!)
        : null,
  };

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    DateTime? endDate,
    String? time,
    String? endTime,
    int? attendees,
    String? category,
    String? imageUrl,
    String? type,
    String? status,
    List<String>? tags,
    bool? featured,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? ticketingEnabled,
    double? ticketPrice,
    String? ticketCurrency,
    int? totalTickets,
    int? ticketsBooked,
    DateTime? ticketingDeadline,
  }) => EventModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    location: location ?? this.location,
    date: date ?? this.date,
    endDate: endDate ?? this.endDate,
    time: time ?? this.time,
    endTime: endTime ?? this.endTime,
    attendees: attendees ?? this.attendees,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    type: type ?? this.type,
    status: status ?? this.status,
    tags: tags ?? this.tags,
    featured: featured ?? this.featured,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    ticketingEnabled: ticketingEnabled ?? this.ticketingEnabled,
    ticketPrice: ticketPrice ?? this.ticketPrice,
    ticketCurrency: ticketCurrency ?? this.ticketCurrency,
    totalTickets: totalTickets ?? this.totalTickets,
    ticketsBooked: ticketsBooked ?? this.ticketsBooked,
    ticketingDeadline: ticketingDeadline ?? this.ticketingDeadline,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EventModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  // ── Private helpers ──────────────────────────────────────────────────────

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  static String _pickImageUrl(Map<String, dynamic> d) {
    if (d['imageUrl'] is String && (d['imageUrl'] as String).isNotEmpty) {
      return d['imageUrl'] as String;
    }
    if (d['image'] is String && (d['image'] as String).isNotEmpty) {
      return d['image'] as String;
    }
    final images = d['images'];
    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }
    return '';
  }

  static List<String> _toStringList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  /// Safely converts a dynamic value to num, handling both numeric types
  /// and String representations (e.g. Firestore stored "10" instead of 10).
  static num? _toNum(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw);
    return null;
  }
}
