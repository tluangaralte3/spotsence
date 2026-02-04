import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/spots/presentation/pages/spots_list_page.dart';
import '../../features/restaurants/presentation/pages/restaurants_list_page.dart';
import '../../features/adventure/presentation/pages/adventure_list_page.dart';
import '../../features/shopping/presentation/pages/shopping_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

/// App router configuration using GoRouter
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    routes: [
      // Home
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Spots
      GoRoute(
        path: '/spots',
        name: 'spots',
        builder: (context, state) => const SpotsListPage(),
      ),
      GoRoute(
        path: '/spots/:id',
        name: 'spot-detail',
        builder: (context, state) {
          // final id = state.pathParameters['id']!;
          return const Scaffold(body: Center(child: Text('Spot Detail')));
        },
      ),

      // Restaurants
      GoRoute(
        path: '/restaurants',
        name: 'restaurants',
        builder: (context, state) => const RestaurantsListPage(),
      ),
      GoRoute(
        path: '/restaurants/:id',
        name: 'restaurant-detail',
        builder: (context, state) {
          // final id = state.pathParameters['id']!;
          return const Scaffold(body: Center(child: Text('Restaurant Detail')));
        },
      ),

      // Adventure
      GoRoute(
        path: '/adventure',
        name: 'adventure',
        builder: (context, state) => const AdventureListPage(),
      ),
      GoRoute(
        path: '/adventure/:id',
        name: 'adventure-detail',
        builder: (context, state) {
          // final id = state.pathParameters['id']!;
          return const Scaffold(body: Center(child: Text('Adventure Detail')));
        },
      ),

      // Shopping
      GoRoute(
        path: '/shopping',
        name: 'shopping',
        builder: (context, state) => const ShoppingListPage(),
      ),
      GoRoute(
        path: '/shopping/:id',
        name: 'shopping-detail',
        builder: (context, state) {
          // final id = state.pathParameters['id']!;
          return const Scaffold(body: Center(child: Text('Shopping Detail')));
        },
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],

    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
