// lib/controllers/banner_controller.dart
//
// Riverpod providers for banner data — used by home screen and admin panel.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';

// ── Home-screen providers ─────────────────────────────────────────────────────

/// Active banners for the home carousel (only isActive == true).
final activeBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(bannerServiceProvider).watchActiveBanners();
});

/// Global section visibility flag.
final bannerSectionConfigProvider = StreamProvider<BannerSectionConfig>((ref) {
  return ref.watch(bannerServiceProvider).watchSectionConfig();
});

// ── Admin providers ───────────────────────────────────────────────────────────

/// All banners for the admin list (active + inactive).
final allBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(bannerServiceProvider).watchAllBanners();
});
