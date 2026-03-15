import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
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
import '../../screens/events/event_detail_screen.dart';
import '../../screens/listings/all_reviews_screen.dart';

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

  static const createBucketList = '/community/bucket-lists/new';
  static const bucketListDetail = '/community/bucket-lists/:id';
  static const editBucketList = '/community/bucket-lists/:id/edit';
  static const addBucketItem = '/community/bucket-lists/:listId/add-item';

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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.onboarding,
      ].contains(state.matchedLocation);

      // If not authenticated and trying to access a protected route → login
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
      // If authenticated and on auth screen → home
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
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
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: AppRoutes.spots,
            builder: (_, __) => const ListingsScreen(initialTab: 0),
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
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.community,
            builder: (_, __) => const CommunityScreen(),
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            builder: (_, __) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Modal routes (outside shell) ───────────────────────────────────
      GoRoute(
        path: AppRoutes.createPost,
        pageBuilder: (_, state) =>
            _bottomSheet(state, const CreatePostScreen()),
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
});

// ── Page transition helpers ───────────────────────────────────────────────────

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, c) => SlideTransition(
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
      transitionsBuilder: (_, animation, __, c) =>
          FadeTransition(opacity: animation, child: c),
    );

CustomTransitionPage<void> _bottomSheet(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      opaque: false,
      transitionsBuilder: (_, animation, __, c) => SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutQuart)),
        ),
        child: c,
      ),
    );
