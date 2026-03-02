import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  static const _pages = [
    _OnboardingPage(
      emoji: '🗺️',
      title: 'Discover Mizoram',
      subtitle:
          'Explore hidden waterfalls, breathtaking viewpoints, and authentic cultural spots across the Land of the Blue Mountains.',
      gradient: [Color(0xFF1A1025), Color(0xFF0A0A0F)],
    ),
    _OnboardingPage(
      emoji: '✨',
      title: 'Earn XP & Badges',
      subtitle:
          'Write reviews, contribute new spots, and climb the leaderboard. Level up from Explorer to Guardian.',
      gradient: [Color(0xFF1A1025), Color(0xFF0A0A0F)],
    ),
    _OnboardingPage(
      emoji: '🤝',
      title: 'Join the Community',
      subtitle:
          'Share tips, create bucket lists, vote on dilemmas, and connect with fellow explorers.',
      gradient: [Color(0xFF1A1025), Color(0xFF0A0A0F)],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _pages[i],
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: TextButton(
              onPressed: _finish,
              child: const Text(
                'Skip',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _current == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _current == i
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Next / Get Started button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_current < _pages.length - 1) {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(
                      _current == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ),

                if (_current == _pages.length - 1) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 80),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 350.ms),
            ],
          ),
        ),
      ),
    );
  }
}
