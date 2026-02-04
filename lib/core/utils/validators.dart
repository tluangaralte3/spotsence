/// Input validation utilities
class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^[+]?[0-9]{10,14}$');

    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Description length validation
  static String? validateDescription(
    String? value, {
    int minLength = 10,
    int maxLength = 500,
  }) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }

    if (value.length < minLength) {
      return 'Description must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return 'Description must not exceed $maxLength characters';
    }

    return null;
  }

  // Rating validation
  static String? validateRating(double? value) {
    if (value == null) {
      return 'Rating is required';
    }

    if (value < 0 || value > 5) {
      return 'Rating must be between 0 and 5';
    }

    return null;
  }

  // Coordinate validation
  static String? validateLatitude(double? value) {
    if (value == null) {
      return 'Latitude is required';
    }

    if (value < -90 || value > 90) {
      return 'Latitude must be between -90 and 90';
    }

    return null;
  }

  static String? validateLongitude(double? value) {
    if (value == null) {
      return 'Longitude is required';
    }

    if (value < -180 || value > 180) {
      return 'Longitude must be between -180 and 180';
    }

    return null;
  }
}
