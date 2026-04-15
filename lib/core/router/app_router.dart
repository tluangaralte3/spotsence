import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../services/notification_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/listings/listings_screen.dart';
import '../../screens/spots/spot_detail_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/community/community_screen.dart';
import '../../screens/community/create_post_screen.dart';
import '../../screens/contribute/contribute_screen.dart';
import '../../screens/leaderboard/leaderboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/listings/listing_detail_screen.dart';
import '../../screens/listings/cafe_detail_screen.dart';
import '../../screens/listings/hotel_detail_screen.dart';
import '../../screens/listings/restaurant_detail_screen.dart';
import '../../screens/community/bucket_list_detail_screen.dart';
import '../../screens/community/create_bucket_list_screen.dart';
import '../../screens/community/edit_bucket_list_screen.dart';
import '../../screens/community/add_bucket_item_screen.dart';
import '../../screens/community/create_dilemma_screen.dart';
import '../../screens/events/event_detail_screen.dart';
import '../../screens/listings/all_reviews_screen.dart';
import '../../screens/packages/tour_venture_screen.dart';
import '../../screens/packages/venture_detail_screen.dart';
import '../../screens/ventures/venture_public_detail_screen.dart';
import '../../screens/ventures/booking_review_screen.dart';
import '../../screens/ventures/my_bookings_screen.dart';
import '../../screens/community/room_management_screen.dart';
import '../../screens/community/dare_detail_screen.dart';
import '../../screens/community/dare_create_screens.dart';
import '../../screens/community/dare_proof_screen.dart';
import '../../screens/community/scratch_card_screen.dart';
import '../../screens/community/dare_rewards_screen.dart';
import '../../screens/notifications/dare_notifications_screen.dart';
import '../../screens/profile/dare_dashboard_screen.dart';
import '../../models/dare_models.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/listings/admin_add_listing_screen.dart';
import '../../screens/admin/listings/admin_venture_form_screen.dart';
import '../../screens/admin/rentals/admin_rentals_screen.dart';
import '../../screens/admin/rentals/admin_add_rental_screen.dart';
import '../../screens/admin/rentals/admin_rental_tracking_screen.dart';
import '../../screens/rentals/rentals_screen.dart';
import '../../controllers/admin_controller.dart';

// Named route paths
abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/';
  static const spots = '/spots';
  static const spotDetail = '/spots/:id';
  static const search = '/search';
  static const community = '/community';
  static const createPost = '/community/new';
  static const contribute = '/contribute';
  static const leaderboard = '/leaderboard';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const listings = '/listings';
  static const listingDetail = '/listings/:type/:id';

  static const eventDetail = '/events/:id';

  static const createDilemma = '/community/dilemmas/new';
  static const createBucketList = '/community/bucket-lists/new';
  static const bucketListDetail = '/community/bucket-lists/:id';
  static const editBucketList = '/community/bucket-lists/:id/edit';
  static const addBucketItem = '/community/bucket-lists/:listId/add-item';

  static const tourPackages = '/packages';
  static const packageDetail = '/packages/:id';
  static String packageDetailPath(String id) => '/packages/$id';

  static const ventureDetail = '/ventures/:id';
  static String ventureDetailPath(String id) => '/ventures/$id';
  static const bookingReview = '/ventures/:id/booking-review';
  static String bookingReviewPath(String id) => '/ventures/$id/booking-review';

  static const myBookings = '/my-bookings';
  static const myRooms = '/community/my-rooms';

  // ── Dare (challenge) routes ──────────────────────────────────────────────
  static const createDare = '/community/dares/new';
  static const dareDetail = '/community/dares/:id';
  static const editDare = '/community/dares/:id/edit';
  static const addDareChallenge = '/community/dares/:dareId/add-challenge';
  static const dareProof =
      '/community/dares/:dareId/challenges/:challengeId/proof';
  static const scratchCard = '/dare-rewards/cards/:cardId';
  static const dareRewards = '/dare-rewards';
  static const notifications = '/notifications';
  static const dareDashboard = '/profile/dare-dashboard';

  static String darePath(String id) => '/community/dares/$id';
  static String editDarePath(String id) => '/community/dares/$id/edit';
  static String addDareChallengePath(String dareId) =>
      '/community/dares/$dareId/add-challenge';
  static String dareProofPath(String dareId, String challengeId) =>
      '/community/dares/$dareId/challenges/$challengeId/proof';
  static String scratchCardPath(String cardId) =>
      '/dare-rewards/cards/$cardId';

  // ── Super Admin ──────────────────────────────────────────────────────────
  static const admin = '/admin';
  static const adminListings = '/admin/listings';
  static const adminUsers = '/admin/users';
  static const adminAnalytics = '/admin/analytics';
  static const adminVentures = '/admin/ventures';
  static const adminModeration = '/admin/moderation';
  static const adminAddListing = '/admin/listings/add/:collection';
  static const adminEditListing = '/admin/listings/edit/:collection/:docId';
  static const adminAddVenture = '/admin/ventures/add';
  static const adminEditVenture = '/admin/ventures/edit/:docId';
  static String adminAddListingPath(String collection) =>
      '/admin/listings/add/$collection';
  static String adminEditListingPath(String collection, String docId) =>
      '/admin/listings/edit/$collection/$docId';
  static String adminAddVenturePath() => '/admin/ventures/add';
  static String adminEditVenturePath(String docId) =>
      '/admin/ventures/edit/$docId';

  static const adminRentals = '/admin/rentals';
  static const adminAddRental = '/admin/rentals/add';
  static const adminEditRental = '/admin/rentals/edit/:docId';
  static String adminEditRentalPath(String docId) =>
      '/admin/rentals/edit/$docId';
  static const adminRentalTracking = '/admin/rentals/tracking';

  static const rentals = '/rentals';

  static const allReviews = '/reviews/:collection/:id';
  static String allReviewsPath({
    required String collection,
    required String id,
    required String name,
    required double avg,
    required int total,
  }) =>
      '/reviews/$collection/$id?name=${Uri.encodeComponent(name)}&avg=$avg&total=$total';

  static String spotDetailPath(String id) => '/spots/$id';
  static String eventDetailPath(String id) => '/events/$id';
  static String listingDetailPath(String type, String id) =>
      '/listings/$type/$id';
  static String bucketListDetailPath(String id) =>
      '/community/bucket-lists/$id';
  static String editBucketListPath(String id) =>
      '/community/bucket-lists/$id/edit';
  static String addBucketItemPath(String listId) =>
      '/community/bucket-lists/$listId/add-item';
}

// ── Router notifier (module-level singleton) ─────────────────────────────────
// Caches the latest auth / admin state so GoRouter's redirect can use it
// without any Riverpod subscription in the provider body.  Avoiding
// ref.watch inside appRouterProvider ensures the GoRouter is NEVER recreated
// when user state updates (XP from votes, ratings, photo uploads, etc.).
class _RouterNotifier extends ChangeNotifier {
  AsyncValue<AuthState> _auth = const AsyncLoading();
  AsyncValue<bool> _admin = const AsyncLoading();

  void setAuth(AsyncValue<AuthState> value) {
    _auth = value;
    notifyListeners();
  }

  void setAdmin(AsyncValue<bool> value) {
    _admin = value;
    notifyListeners();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    if (_auth.isLoading) return null;

    final isAuthenticated = _auth.value?.isAuthenticated ?? false;
    final isAuthRoute = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.onboarding,
    ].contains(state.matchedLocation);

    final protectedRoutes = [
      AppRoutes.profile,
      AppRoutes.editProfile,
      AppRoutes.createPost,
      AppRoutes.contribute,
    ];
    final isProtected = protectedRoutes.any(
      (r) => state.matchedLocation.startsWith(r),
    );

    if (!isAuthenticated && isProtected) return AppRoutes.login;
    if (isAuthenticated && isAuthRoute) return AppRoutes.home;

    // ── Admin gate ─────────────────────────────────────────────────────────
    if (state.matchedLocation.startsWith('/admin')) {
      if (!isAuthenticated) return AppRoutes.login;
      if (_admin.isLoading) return null;
      final isSuperAdmin = _admin.asData?.value ?? false;
      if (!isSuperAdmin) return AppRoutes.home;
    }

    return null;
  }
}

// Single notifier instance — lives for the entire app lifecycle.
final _routerNotifier = _RouterNotifier();

// Wires Riverpod auth/admin listeners into _routerNotifier.
// Contains ONLY ref.listen (no ref.watch), so this provider never invalidates
// its dependents — appRouterProvider is therefore also never invalidated.
final _routerListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<AuthState>>(
    authControllerProvider,
    (_, next) => _routerNotifier.setAuth(next),
    fireImmediately: true,
  );
  ref.listen<AsyncValue<bool>>(
    isSuperAdminProvider,
    (_, next) => _routerNotifier.setAdmin(next),
    fireImmediately: true,
  );
});

final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch the listener provider to keep it alive.
  // Because _routerListenerProvider has no ref.watch inside, its value never
  // changes — so this watch never causes appRouterProvider to rebuild.
  ref.watch(_routerListenerProvider);

  final router = GoRouter(
    // Share the navigator key with NotificationService so it can push routes
    // from FCM tap handlers without needing a BuildContext.
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: _routerNotifier,
    redirect: _routerNotifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _slide(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, state) => _slide(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (_, state) => _slide(state, const ForgotPasswordScreen()),
      ),

      // ── Shell (bottom nav) ─────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: AppRoutes.spots,
            builder: (_, _) => const ListingsScreen(initialTab: 0),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) => _fade(
                  state,
                  SpotDetailScreen(id: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.listings,
            builder: (_, state) {
              final tab =
                  int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
              return ListingsScreen(initialTab: tab);
            },
            routes: [
              GoRoute(
                path: ':type/:id',
                pageBuilder: (_, state) {
                  final type = state.pathParameters['type']!;
                  final id = state.pathParameters['id']!;
                  if (type == 'restaurants') {
                    return _fade(state, RestaurantDetailScreen(id: id));
                  }
                  if (type == 'hotels') {
                    return _fade(state, HotelDetailScreen(id: id));
                  }
                  if (type == 'cafes') {
                    return _fade(state, CafeDetailScreen(id: id));
                  }
                  return _fade(state, ListingDetailScreen(type: type, id: id));
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (_, _) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.tourPackages,
            builder: (_, _) => const TourPackagesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) => _fade(
                  state,
                  VentureDetailScreen(packageId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.community,
            builder: (_, _) => const CommunityScreen(),
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            builder: (_, _) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Modal routes (outside shell) ───────────────────────────────────
      GoRoute(
        path: '/ventures/:id',
        pageBuilder: (_, state) => _fade(
          state,
          VenturePublicDetailScreen(ventureId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/ventures/:id/booking-review',
        pageBuilder: (_, state) {
          final args = state.extra as BookingReviewArgs;
          return _fade(state, BookingReviewScreen(args: args));
        },
      ),
      GoRoute(
        path: AppRoutes.myBookings,
        pageBuilder: (_, state) =>
            _fade(state, const MyBookingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.myRooms,
        pageBuilder: (_, state) =>
            _slide(state, const RoomManagementScreen()),
      ),

      // ── Admin (outside shell — own navigation) ─────────────────────────
      // Use pageBuilder with HeroControllerScope to prevent Hero tag conflicts
      // when transitioning from MainShell (which also has a Scaffold + Heroes).
      GoRoute(
        path: AppRoutes.admin,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          // Isolate Hero animations so they don't clash with MainShell heroes
          child: HeroControllerScope(
            controller: MaterialApp.createMaterialHeroController(),
            child: const AdminShell(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        ),
        routes: [
          GoRoute(
            path: 'listings/add/:collection',
            pageBuilder: (_, state) => _slide(
              state,
              AdminAddListingScreen(
                collection: state.pathParameters['collection']!,
              ),
            ),
          ),
          GoRoute(
            path: 'listings/edit/:collection/:docId',
            pageBuilder: (_, state) => _slide(
              state,
              AdminAddListingScreen(
                collection: state.pathParameters['collection']!,
                docId: state.pathParameters['docId'],
              ),
            ),
          ),
          GoRoute(
            path: 'ventures/add',
            pageBuilder: (_, state) =>
                _slide(state, const AdminVentureFormScreen()),
          ),
          GoRoute(
            path: 'ventures/edit/:docId',
            pageBuilder: (_, state) => _slide(
              state,
              AdminVentureFormScreen(docId: state.pathParameters['docId']),
            ),
          ),
          GoRoute(
            path: 'rentals',
            pageBuilder: (_, state) =>
                _slide(state, const AdminRentalsScreen()),
          ),
          GoRoute(
            path: 'rentals/add',
            pageBuilder: (_, state) =>
                _slide(state, const AdminAddRentalScreen()),
          ),
          GoRoute(
            path: 'rentals/edit/:docId',
            pageBuilder: (_, state) => _slide(
              state,
              AdminAddRentalScreen(
                docId: state.pathParameters['docId'],
              ),
            ),
          ),
          GoRoute(
            path: 'rentals/tracking',
            pageBuilder: (_, state) =>
                _slide(state, const AdminRentalTrackingScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.rentals,
        pageBuilder: (_, state) =>
            _slide(state, const RentalsScreen()),
      ),
      GoRoute(
        path: AppRoutes.createPost,
        pageBuilder: (_, state) =>
            _bottomSheet(state, const CreatePostScreen()),
      ),

      // ── Dare routes ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.createDare,
        pageBuilder: (_, state) =>
            _bottomSheet(state, const CreateDareScreen()),
      ),
      GoRoute(
        path: AppRoutes.dareDetail,
        pageBuilder: (_, state) => _slide(
          state,
          DareDetailScreen(dareId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.editDare,
        pageBuilder: (_, state) => _slide(
          state,
          // Re-use CreateDareScreen in edit mode — same form but with extra
          // passed as a DareModel; we keep it simple for now
          DareDetailScreen(dareId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.addDareChallenge,
        pageBuilder: (_, state) => _slide(
          state,
          AddDareChallengeScreen(
            dareId: state.pathParameters['dareId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dareProof,
        pageBuilder: (_, state) => _slide(
          state,
          DareProofScreen(
            dareId: state.pathParameters['dareId']!,
            challengeId: state.pathParameters['challengeId']!,
            challengeTitle: state.uri.queryParameters['title'] ?? 'Challenge',
            initialImages:
                state.extra is List<File> ? state.extra as List<File> : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dareRewards,
        pageBuilder: (_, state) =>
            _slide(state, const DareRewardsScreen()),
      ),
      GoRoute(
        path: AppRoutes.scratchCard,
        pageBuilder: (_, state) {
          final card = state.extra as ScratchCard;
          return _slide(state, ScratchCardScreen(card: card));
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (_, state) =>
            _slide(state, const DareNotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.dareDashboard,
        pageBuilder: (_, state) {
          final userId = state.uri.queryParameters['uid'] ?? '';
          return _slide(state, DareDashboardScreen(userId: userId));
        },
      ),
      GoRoute(
        path: AppRoutes.createDilemma,
        pageBuilder: (_, state) =>
            _slide(state, const CreateDilemmaScreen()),
      ),
      GoRoute(
        path: AppRoutes.createBucketList,
        pageBuilder: (_, state) =>
            _bottomSheet(state, const CreateBucketListScreen()),
      ),
      GoRoute(
        path: AppRoutes.editBucketList,
        pageBuilder: (_, state) => _slide(
          state,
          EditBucketListScreen(listId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.bucketListDetail,
        pageBuilder: (_, state) => _slide(
          state,
          BucketListDetailScreen(listId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.addBucketItem,
        pageBuilder: (_, state) => _slide(
          state,
          AddBucketItemScreen(listId: state.pathParameters['listId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        pageBuilder: (_, state) =>
            _slide(state, EventDetailScreen(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.contribute,
        pageBuilder: (_, state) => _slide(state, const ContributeScreen()),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (_, state) => _slide(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.allReviews,
        pageBuilder: (_, state) {
          final collection = state.pathParameters['collection']!;
          final id = state.pathParameters['id']!;
          final name = Uri.decodeComponent(
            state.uri.queryParameters['name'] ?? '',
          );
          final avg =
              double.tryParse(state.uri.queryParameters['avg'] ?? '') ?? 0.0;
          final total =
              int.tryParse(state.uri.queryParameters['total'] ?? '') ?? 0;
          return _slide(
            state,
            AllReviewsScreen(
              collection: collection,
              entityId: id,
              entityName: name,
              averageRating: avg,
              totalRatings: total,
            ),
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

// ── Page transition helpers ───────────────────────────────────────────────────

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, _, c) => SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: c,
      ),
    );

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, _, c) =>
          FadeTransition(opacity: animation, child: c),
    );

CustomTransitionPage<void> _bottomSheet(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      opaque: false,
      transitionsBuilder: (_, animation, _, c) => SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutQuart)),
        ),
        child: c,
      ),
    );
