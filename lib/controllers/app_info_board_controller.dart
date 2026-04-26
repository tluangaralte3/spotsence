// lib/controllers/app_info_board_controller.dart
//
// Riverpod providers for the App Information Board section config.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_info_board_model.dart';
import '../services/app_info_board_service.dart';

/// Live stream of the AI Planner section config — used by home screen.
final appInfoBoardSectionProvider =
    StreamProvider<AppInfoBoardModel>((ref) {
  return ref.watch(appInfoBoardServiceProvider).watchSection();
});
