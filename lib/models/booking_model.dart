// lib/models/booking_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status enum
// ─────────────────────────────────────────────────────────────────────────────

enum BookingStatus { pending, confirmed, cancelled, completed }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  static BookingStatus parse(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VentureBooking model
// ─────────────────────────────────────────────────────────────────────────────

class VentureBooking {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;

  final String ventureId;
  final String ventureTitle;
  final String heroImage;
  final String category;
  final String location;

  final String operatorName;
  final String operatorPhone;
  final String operatorWhatsapp;
  final String operatorEmail;

  final String? selectedPackageName;
  final String? selectedPackageDesc;
  final double? pricePerPerson;

  final int personCount;
  final List<Map<String, dynamic>> selectedAddons;
  final double addonSubtotal;
  final double grandTotal;

  final BookingStatus status;
  final String? adminNote;

  final DateTime createdAt;
  final DateTime updatedAt;

  const VentureBooking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.ventureId,
    required this.ventureTitle,
    required this.heroImage,
    required this.category,
    required this.location,
    required this.operatorName,
    required this.operatorPhone,
    required this.operatorWhatsapp,
    required this.operatorEmail,
    this.selectedPackageName,
    this.selectedPackageDesc,
    this.pricePerPerson,
    required this.personCount,
    required this.selectedAddons,
    required this.addonSubtotal,
    required this.grandTotal,
    required this.status,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VentureBooking.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    List<Map<String, dynamic>> parseAddons(dynamic raw) {
      if (raw is! List) return [];
      return raw.map<Map<String, dynamic>>((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }

    DateTime parseTs(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      return DateTime.now();
    }

    return VentureBooking(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      userEmail: d['userEmail'] as String? ?? '',
      ventureId: d['ventureId'] as String? ?? '',
      ventureTitle: d['ventureTitle'] as String? ?? '',
      heroImage: d['heroImage'] as String? ?? '',
      category: d['category'] as String? ?? '',
      location: d['location'] as String? ?? '',
      operatorName: d['operatorName'] as String? ?? '',
      operatorPhone: d['operatorPhone'] as String? ?? '',
      operatorWhatsapp: d['operatorWhatsapp'] as String? ?? '',
      operatorEmail: d['operatorEmail'] as String? ?? '',
      selectedPackageName: d['selectedPackageName'] as String?,
      selectedPackageDesc: d['selectedPackageDesc'] as String?,
      pricePerPerson: (d['pricePerPerson'] as num?)?.toDouble(),
      personCount: (d['personCount'] as num?)?.toInt() ?? 1,
      selectedAddons: parseAddons(d['selectedAddons']),
      addonSubtotal: (d['addonSubtotal'] as num?)?.toDouble() ?? 0,
      grandTotal: (d['grandTotal'] as num?)?.toDouble() ?? 0,
      status: BookingStatusX.parse(d['status'] as String? ?? ''),
      adminNote: d['adminNote'] as String?,
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
    );
  }

  /// Serializes to Firestore map. Timestamps are added by BookingService.
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'ventureId': ventureId,
        'ventureTitle': ventureTitle,
        'heroImage': heroImage,
        'category': category,
        'location': location,
        'operatorName': operatorName,
        'operatorPhone': operatorPhone,
        'operatorWhatsapp': operatorWhatsapp,
        'operatorEmail': operatorEmail,
        if (selectedPackageName != null)
          'selectedPackageName': selectedPackageName,
        if (selectedPackageDesc != null)
          'selectedPackageDesc': selectedPackageDesc,
        if (pricePerPerson != null) 'pricePerPerson': pricePerPerson,
        'personCount': personCount,
        'selectedAddons': selectedAddons,
        'addonSubtotal': addonSubtotal,
        'grandTotal': grandTotal,
        'status': status.name,
        if (adminNote != null) 'adminNote': adminNote,
      };
}
