import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Home page - main discovery hub (matches web layout)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            title: const Text('SpotMizoram'),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),

          // Hero Section
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Discover Mizoram',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spot the Soul of Mizoram',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('1,000+', 'Spots', Icons.place),
                  _buildStatCard('500+', 'Restaurants', Icons.restaurant),
                  _buildStatCard('10K+', 'Visitors', Icons.people),
                ],
              ),
            ),
          ),

          // Featured Spots Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Featured Spots',
              'Explore popular destinations',
              onViewAll: () => context.push('/spots'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, index) =>
                    _buildFeatureCard('Spot ${index + 1}', 'Location', 4.5),
              ),
            ),
          ),

          // Trending Restaurants Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Trending Restaurants',
              'Best rated dining experiences',
              onViewAll: () => context.push('/restaurants'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, index) => _buildFeatureCard(
                  'Restaurant ${index + 1}',
                  'Cuisine Type',
                  4.8,
                ),
              ),
            ),
          ),

          // Adventure & Nature Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Adventure & Nature',
              'Explore outdoor activities',
              onViewAll: () => context.push('/adventure'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, index) => _buildFeatureCard(
                  'Adventure ${index + 1}',
                  'Activity Type',
                  4.6,
                ),
              ),
            ),
          ),

          // Shopping Destinations Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Shopping Destinations',
              'Discover local markets & malls',
              onViewAll: () => context.push('/shopping'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, index) => _buildFeatureCard(
                  'Shopping ${index + 1}',
                  'Market Type',
                  4.3,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              // Discover page
              break;
            case 2:
              // Map view
              break;
            case 3:
              // Leaderboard
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Rank',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (onViewAll != null)
            TextButton(onPressed: onViewAll, child: const Text('View All')),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, double rating) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 48, color: AppColors.textHint),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
