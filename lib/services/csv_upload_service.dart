// lib/services/csv_upload_service.dart
//
// Parses a CSV file and batch-writes rows to a Firestore collection.
// Each tab has its own column schema. Unknown columns are forwarded as-is.
//
// Usage:
//   final result = await CsvUploadService().upload(
//     csvBytes: bytes,
//     collection: 'restaurants',
//   );

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import '../controllers/admin_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result
// ─────────────────────────────────────────────────────────────────────────────

class CsvUploadResult {
  final int total;
  final int uploaded;
  final int skipped;
  final List<String> errors; // row-level error messages

  const CsvUploadResult({
    required this.total,
    required this.uploaded,
    required this.skipped,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// Column definitions per collection
// ─────────────────────────────────────────────────────────────────────────────

/// Each entry describes one CSV column: its header name, the Firestore field
/// it maps to, the data type, and whether it is required.
class _ColDef {
  final String header; // CSV column header (case-insensitive match)
  final String field; // Firestore field name
  final _Type type;
  final bool required;

  const _ColDef(this.header, this.field, this.type, {this.required = false});
}

enum _Type { string, number, boolean, list }

// ─────────────────────────────────────────────────────────────────────────────
// Per-tab schemas
//
// The CSV template for each tab uses these headers in this order.
// Admins can re-order columns — matching is done by header name.
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, List<_ColDef>> _schemas = {
  // ── spots ──────────────────────────────────────────────────────────────────
  'spots': [
    _ColDef('name', 'name', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('category', 'category', _Type.string),
    _ColDef('location', 'locationAddress', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
    _ColDef('imageUrls', 'imagesUrl', _Type.list), // pipe-separated
    _ColDef('featured', 'featured', _Type.boolean),
    _ColDef('status', 'status', _Type.string),
    _ColDef('placeStory', 'placeStory', _Type.string),
  ],

  // ── restaurants ────────────────────────────────────────────────────────────
  'restaurants': [
    _ColDef('name', 'name', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('priceRange', 'priceRange', _Type.string),
    _ColDef('cuisineTypes', 'cuisineTypes', _Type.list),
    _ColDef('openingHours', 'openingHours', _Type.string),
    _ColDef('hasDelivery', 'hasDelivery', _Type.boolean),
    _ColDef('hasReservation', 'hasReservation', _Type.boolean),
    _ColDef('contactPhone', 'contactPhone', _Type.string),
    _ColDef('website', 'website', _Type.string),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
    _ColDef('images', 'images', _Type.list),
    _ColDef('rating', 'rating', _Type.number),
  ],

  // ── accommodations ─────────────────────────────────────────────────────────
  'accommodations': [
    _ColDef('name', 'name', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('type', 'type', _Type.string),
    _ColDef('pricePerNight', 'pricePerNight', _Type.number),
    _ColDef('amenities', 'amenities', _Type.list),
    _ColDef('contactPhone', 'contactPhone', _Type.string),
    _ColDef('website', 'website', _Type.string),
    _ColDef('images', 'images', _Type.list),
    _ColDef('rating', 'rating', _Type.number),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
  ],

  // ── homestays ──────────────────────────────────────────────────────────────
  'homestays': [
    _ColDef('name', 'name', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('pricePerNight', 'pricePerNight', _Type.number),
    _ColDef('amenities', 'amenities', _Type.list),
    _ColDef('contactPhone', 'contactPhone', _Type.string),
    _ColDef('images', 'images', _Type.list),
    _ColDef('rating', 'rating', _Type.number),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
  ],

  // ── cafes ──────────────────────────────────────────────────────────────────
  'cafes': [
    _ColDef('name', 'name', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('priceRange', 'priceRange', _Type.string),
    _ColDef('cuisineTypes', 'cuisineTypes', _Type.list),
    _ColDef('openingHours', 'openingHours', _Type.string),
    _ColDef('contactPhone', 'contactPhone', _Type.string),
    _ColDef('images', 'images', _Type.list),
    _ColDef('rating', 'rating', _Type.number),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
  ],

  // ── adventureSpots ─────────────────────────────────────────────────────────
  'adventureSpots': [
    _ColDef('name', 'name', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('category', 'category', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('difficulty', 'difficulty', _Type.string),
    _ColDef('duration', 'duration', _Type.string),
    _ColDef('bestSeason', 'bestSeason', _Type.string),
    _ColDef('activities', 'activities', _Type.list),
    _ColDef('isPopular', 'isPopular', _Type.boolean),
    _ColDef('images', 'images', _Type.list),
    _ColDef('rating', 'rating', _Type.number),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
  ],

  // ── shoppingAreas ──────────────────────────────────────────────────────────
  'shoppingAreas': [
    _ColDef('name', 'name', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('type', 'type', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('openingHours', 'openingHours', _Type.string),
    _ColDef('products', 'products', _Type.list),
    _ColDef('priceRange', 'priceRange', _Type.string),
    _ColDef('hasParking', 'hasParking', _Type.boolean),
    _ColDef('acceptsCards', 'acceptsCards', _Type.boolean),
    _ColDef('hasDelivery', 'hasDelivery', _Type.boolean),
    _ColDef('isPopular', 'isPopular', _Type.boolean),
    _ColDef('contactPhone', 'contactPhone', _Type.string),
    _ColDef('images', 'images', _Type.list),
    _ColDef('rating', 'rating', _Type.number),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
  ],

  // ── events ─────────────────────────────────────────────────────────────────
  'events': [
    _ColDef('title', 'title', _Type.string, required: true),
    _ColDef('description', 'description', _Type.string),
    _ColDef('type', 'type', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('startDate', 'startDate', _Type.string),
    _ColDef('endDate', 'endDate', _Type.string),
    _ColDef('ticketPrice', 'ticketPrice', _Type.number),
    _ColDef('maxAttendees', 'maxAttendees', _Type.number),
    _ColDef('organizer', 'organizer', _Type.string),
    _ColDef('contactEmail', 'contactEmail', _Type.string),
    _ColDef('contactPhone', 'contactPhone', _Type.string),
    _ColDef('imageUrl', 'imageUrl', _Type.string),
    _ColDef('status', 'status', _Type.string),
    _ColDef('isFeatured', 'isFeatured', _Type.boolean),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
  ],

  // ── ventures (adventureSpots alias used by ventures collection) ────────────
  'ventures': [
    _ColDef('title', 'title', _Type.string, required: true),
    _ColDef('tagline', 'tagline', _Type.string),
    _ColDef('description', 'description', _Type.string),
    _ColDef('category', 'category', _Type.string),
    _ColDef('difficulty', 'difficulty', _Type.string),
    _ColDef('location', 'location', _Type.string),
    _ColDef('district', 'district', _Type.string),
    _ColDef('duration', 'duration', _Type.string),
    _ColDef('meetingPoint', 'meetingPoint', _Type.string),
    _ColDef('minGroupSize', 'minGroupSize', _Type.number),
    _ColDef('maxGroupSize', 'maxGroupSize', _Type.number),
    _ColDef('basePrice', 'basePrice', _Type.number),
    _ColDef('contactPhone', 'contactPhone', _Type.string),
    _ColDef('contactEmail', 'contactEmail', _Type.string),
    _ColDef('images', 'images', _Type.list),
    _ColDef('status', 'status', _Type.string),
    _ColDef('isFeatured', 'isFeatured', _Type.boolean),
    _ColDef('latitude', 'latitude', _Type.number),
    _ColDef('longitude', 'longitude', _Type.number),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// CSV template headers (for download)
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a CSV string with only the header row — used when admin taps
/// "Download Template".
String buildCsvTemplate(String collection) {
  final schema = _schemas[collection];
  if (schema == null) return '';
  final headers = schema.map((c) => c.header).toList();
  return const ListToCsvConverter().convert([headers]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class CsvUploadService {
  final FirebaseFirestore _db;

  CsvUploadService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  /// Parse [csvBytes] (UTF-8) and write each row to [collection].
  /// [onProgress] is called after each batch (0.0 → 1.0).
  Future<CsvUploadResult> upload({
    required List<int> csvBytes,
    required String collection,
    void Function(double progress)? onProgress,
  }) async {
    final schema = _schemas[collection];
    if (schema == null) {
      return CsvUploadResult(
        total: 0,
        uploaded: 0,
        skipped: 0,
        errors: ['No schema defined for collection "$collection".'],
      );
    }

    // ── 1. Parse CSV ──────────────────────────────────────────────────────
    final csvStr = utf8.decode(csvBytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n').convert(csvStr);

    if (rows.isEmpty) {
      return CsvUploadResult(
        total: 0,
        uploaded: 0,
        skipped: 0,
        errors: ['The file is empty.'],
      );
    }

    // First row is the header
    final rawHeaders = rows.first
        .map((h) => h.toString().trim().toLowerCase())
        .toList();

    // Build index map: header_lowercase → column index
    final headerIndex = <String, int>{
      for (var i = 0; i < rawHeaders.length; i++) rawHeaders[i]: i,
    };

    // ── 2. Process data rows ──────────────────────────────────────────────
    final dataRows = rows.skip(1).toList();
    final int total = dataRows.length;
    int uploaded = 0;
    int skipped = 0;
    final errors = <String>[];

    const batchSize = 400; // Firestore batch limit is 500
    var batch = _db.batch();
    int batchCount = 0;

    for (var rowIdx = 0; rowIdx < dataRows.length; rowIdx++) {
      final row = dataRows[rowIdx];
      final rowNum = rowIdx + 2; // 1-based, accounting for header row

      // Skip completely blank rows
      if (row.every((cell) => cell.toString().trim().isEmpty)) {
        skipped++;
        continue;
      }

      // Build Firestore document map from schema
      final doc = <String, dynamic>{};
      bool hasRequired = true;

      for (final col in schema) {
        final idx = headerIndex[col.header.toLowerCase()];
        final raw = idx != null && idx < row.length
            ? row[idx].toString().trim()
            : '';

        if (raw.isEmpty) {
          if (col.required) {
            errors.add('Row $rowNum: Required field "${col.header}" is empty.');
            hasRequired = false;
          }
          continue;
        }

        final value = _cast(raw, col.type);
        if (value != null) {
          doc[col.field] = value;
        }
      }

      // Forward any columns not in the schema as raw strings
      for (var i = 0; i < rawHeaders.length; i++) {
        final hdr = rawHeaders[i];
        final alreadyMapped = schema.any((c) => c.header.toLowerCase() == hdr);
        if (!alreadyMapped && i < row.length) {
          final v = row[i].toString().trim();
          if (v.isNotEmpty) doc[hdr] = v;
        }
      }

      if (!hasRequired) {
        skipped++;
        continue;
      }

      // Inject server timestamps
      doc['createdAt'] = FieldValue.serverTimestamp();
      doc['updatedAt'] = FieldValue.serverTimestamp();

      // Add to batch
      final ref = _db.collection(collection).doc();
      batch.set(ref, doc);
      batchCount++;
      uploaded++;

      // Commit when batch is full
      if (batchCount >= batchSize) {
        await batch.commit();
        batch = _db.batch();
        batchCount = 0;
        onProgress?.call(uploaded / total);
      }
    }

    // Commit any remaining docs
    if (batchCount > 0) {
      await batch.commit();
      onProgress?.call(1.0);
    }

    return CsvUploadResult(
      total: total,
      uploaded: uploaded,
      skipped: skipped,
      errors: errors,
    );
  }

  // ── Type coercion ─────────────────────────────────────────────────────────

  static dynamic _cast(String raw, _Type type) {
    switch (type) {
      case _Type.string:
        return raw;

      case _Type.number:
        return num.tryParse(raw);

      case _Type.boolean:
        final lower = raw.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'yes') return true;
        if (lower == 'false' || lower == '0' || lower == 'no') return false;
        return null;

      case _Type.list:
        // Values separated by pipe "|" or semicolon ";"
        final sep = raw.contains('|') ? '|' : ';';
        return raw
            .split(sep)
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience: returns human-readable column hints for the upload dialog
// ─────────────────────────────────────────────────────────────────────────────

List<({String header, String hint, bool required})> getCsvColumnHints(
  ListingTab tab,
) {
  final schema = _schemas[tab.collection] ?? [];
  return schema.map((c) {
    final String hint = switch (c.type) {
      _Type.boolean => 'true / false',
      _Type.number => 'number',
      _Type.list => 'value1|value2|value3',
      _Type.string => 'text',
    };
    return (header: c.header, hint: hint, required: c.required);
  }).toList();
}
