import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/spot_model.dart';
import 'shared_widgets.dart';

/// Large hero card used in featured carousel.
class FeaturedSpotCard extends StatelessWidget {
  final SpotModel spot;
  final VoidCallback onTap;

  const FeaturedSpotCard({super.key, required this.spot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (spot.heroImage.isNotEmpty)
              CachedNetworkImage(
                imageUrl: spot.heroImage,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _PlaceholderBg(),
              )
            else
              const _PlaceholderBg(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),

            // Featured badge
            if (spot.featured)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✨ Featured',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // Info
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spot.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          spot.locationAddress,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StarRating(rating: spot.averageRating),
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

/// Compact list tile card for spots grid/list view.
class SpotCard extends StatelessWidget {
  final SpotModel spot;
  final VoidCallback onTap;

  const SpotCard({super.key, required this.spot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: spot.heroImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: spot.heroImage,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const _PlaceholderBg(),
                    )
                  : const _PlaceholderBg(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      spot.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    spot.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          spot.district.isNotEmpty
                              ? spot.district
                              : spot.locationAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StarRating(rating: spot.averageRating),
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

class _PlaceholderBg extends StatelessWidget {
  const _PlaceholderBg();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: AppColors.textMuted),
      ),
    );
  }
}
