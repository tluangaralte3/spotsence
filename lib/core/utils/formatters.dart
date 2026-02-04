import 'package:intl/intl.dart';

/// Formatting utilities for the app
class Formatters {
  /// Format date to readable string
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Format number with K/M suffix
  static String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      final k = number / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    } else {
      final m = number / 1000000;
      return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M';
    }
  }

  /// Format rating (e.g., "4.5")
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Format distance (e.g., "1.2 km" or "450 m")
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Format duration (e.g., "2h 30m")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Format price range
  static String formatPriceRange(String priceRange) {
    return priceRange; // Already formatted like $, $$, $$$, $$$$
  }

  /// Format phone number
  static String formatPhoneNumber(String phone) {
    // Remove all non-numeric characters
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Format as (XXX) XXX-XXXX if 10 digits
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }

    return phone;
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// Format opening hours
  static String formatOpeningHours(String hours) {
    // Already formatted from backend
    return hours;
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
