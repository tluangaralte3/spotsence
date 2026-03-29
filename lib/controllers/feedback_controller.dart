// lib/controllers/feedback_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feedback_service.dart';

/// Singleton service provider for feedback operations.
final feedbackServiceProvider =
    Provider<FeedbackService>((_) => FeedbackService());
