# 🚀 SpotMizoram Mobile - Development Guide

## ✅ What's Been Completed

### 1. **Project Structure** ✓

- Clean Architecture folder structure created
- Feature-based organization aligned with web platform
- Core utilities, constants, and theme setup

### 2. **Core Configuration** ✓

- `AppConstants` - App-wide constants matching web implementation
- `Enums` - All categories, statuses, and types from web
- `AppColors` - Tourism-themed color palette
- `AppTheme` - Material 3 theme with light/dark modes
- Error handling (Failures & Exceptions)
- Validators for input fields

### 3. **Domain Layer** ✓

- **Entities Created**:
  - `SpotEntity` - Tourist spots (matches web `spots` collection)
  - `RestaurantEntity` - Dining places (matches web `restaurants`)
  - `AdventureSpotEntity` - Adventure activities (matches web `adventureSpots`)
  - `ShoppingAreaEntity` - Shopping areas (matches web `shoppingAreas`)
  - `UserEntity` - User profiles
  - `BadgeEntity` - Gamification badges

- **Repository Interfaces Created**:
  - `SpotsRepository` - Spot data operations
  - `RestaurantsRepository` - Restaurant queries
  - `AdventureRepository` - Adventure spot management
  - `ShoppingRepository` - Shopping area operations
  - `AuthRepository` - Authentication & user management
  - `GamificationRepository` - Points, badges, leaderboard

### 4. **Utilities** ✓

- `Formatters` - Date, number, distance, rating formatting
- `LocationHelper` - GPS calculations, distance, bearing
- `ImageHelper` - Image picking, compression, thumbnails
- `Validators` - Email, password, phone, URL validation

### 5. **Presentation Layer** ✓

- **Router** - GoRouter configuration with routes
- **Home Page** - Discovery hub with sections matching web layout
- **Placeholder Pages** - Spots, Restaurants, Adventure, Shopping, Profile, Login

### 6. **Dependencies** ✓

- All required packages added to `pubspec.yaml`
- Dependencies installed successfully

---

## 🔥 Next Steps to Make the App Functional

### Step 1: Firebase Configuration (REQUIRED)

#### A. Android Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create one)
3. Add Android app with package name: `com.hillstech.spotmizoram`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

#### B. iOS Setup

1. In Firebase Console, add iOS app
2. Bundle ID: `com.hillstech.spotmizoram`
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/GoogleService-Info.plist`

#### C. Update `android/build.gradle.kts` (Project level)

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

#### D. Update `android/app/build.gradle.kts` (App level)

Add at the bottom:

```kotlin
apply(plugin = "com.google.gms.google-services")
```

### Step 2: Generate Freezed Code

Run this command to generate serialization code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will create:

- `*.freezed.dart` files for all entities
- `*.g.dart` files for JSON serialization

### Step 3: Implement Data Layer

#### A. Create Firebase Data Source

**File**: `lib/features/spots/data/datasources/spots_remote_datasource.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spot_model.dart';

abstract class SpotsRemoteDataSource {
  Future<List<SpotModel>> getFeaturedSpots({int limit = 12});
  Future<SpotModel> getSpotById(String id);
  // ... other methods
}

class SpotsRemoteDataSourceImpl implements SpotsRemoteDataSource {
  final FirebaseFirestore firestore;

  SpotsRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<SpotModel>> getFeaturedSpots({int limit = 12}) async {
    final snapshot = await firestore
        .collection('spots')
        .where('status', isEqualTo: 'Approved')
        .where('featured', isEqualTo: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SpotModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Implement other methods...
}
```

#### B. Create Models

**File**: `lib/features/spots/data/models/spot_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/spot_entity.dart';
import '../../../../core/constants/enums.dart';

part 'spot_model.freezed.dart';
part 'spot_model.g.dart';

@freezed
class SpotModel with _$SpotModel {
  const factory SpotModel({
    required String id,
    required String name,
    required String category,
    required String locationAddress,
    required double latitude,
    required double longitude,
    required List<String> imagesUrl,
    String? placeStory,
    double? averageRating,
    int? popularity,
    required bool featured,
    required String status,
    // ... all fields matching Firestore
  }) = _SpotModel;

  factory SpotModel.fromJson(Map<String, dynamic> json) =>
      _$SpotModelFromJson(json);

  // Convert to entity
  SpotEntity toEntity() {
    return SpotEntity(
      id: id,
      name: name,
      category: _parseCategory(category),
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
      imagesUrl: imagesUrl,
      placeStory: placeStory,
      averageRating: averageRating,
      popularity: popularity,
      featured: featured,
      status: _parseStatus(status),
    );
  }

  static SpotCategory _parseCategory(String value) {
    // Parse category string to enum
  }

  static ApprovalStatus _parseStatus(String value) {
    // Parse status string to enum
  }
}
```

#### C. Implement Repository

**File**: `lib/features/spots/data/repositories/spots_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/spot_entity.dart';
import '../../domain/repositories/spots_repository.dart';
import '../datasources/spots_remote_datasource.dart';

class SpotsRepositoryImpl implements SpotsRepository {
  final SpotsRemoteDataSource remoteDataSource;

  SpotsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<SpotEntity>>> getFeaturedSpots({
    int limit = 12,
  }) async {
    try {
      final models = await remoteDataSource.getFeaturedSpots(limit: limit);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // Implement other methods...
}
```

### Step 4: Create Riverpod Providers

**File**: `lib/features/spots/presentation/providers/spots_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/spots_remote_datasource.dart';
import '../../data/repositories/spots_repository_impl.dart';
import '../../domain/repositories/spots_repository.dart';

// Firebase instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Data source provider
final spotsRemoteDataSourceProvider = Provider<SpotsRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SpotsRemoteDataSourceImpl(firestore);
});

// Repository provider
final spotsRepositoryProvider = Provider<SpotsRepository>((ref) {
  final remoteDataSource = ref.watch(spotsRemoteDataSourceProvider);
  return SpotsRepositoryImpl(remoteDataSource);
});

// Featured spots provider
final featuredSpotsProvider = FutureProvider((ref) async {
  final repository = ref.watch(spotsRepositoryProvider);
  final result = await repository.getFeaturedSpots();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (spots) => spots,
  );
});
```

### Step 5: Update Home Page to Use Real Data

**File**: `lib/features/home/presentation/pages/home_page.dart`

```dart
// In the Featured Spots section
final featuredSpots = ref.watch(featuredSpotsProvider);

// Replace placeholder ListView with:
featuredSpots.when(
  data: (spots) => SizedBox(
    height: 280,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        return SpotCard(spot: spot); // Create this widget
      },
    ),
  ),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
)
```

### Step 6: Create Reusable Widgets

**File**: `lib/features/spots/presentation/widgets/spot_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/spot_entity.dart';
import '../../../../core/theme/app_colors.dart';

class SpotCard extends StatelessWidget {
  final SpotEntity spot;

  const SpotCard({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: spot.displayImage ?? '',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.primary.withOpacity(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.image, size: 48),
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.category.displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (spot.averageRating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          spot.averageRating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing the App

### 1. Run the App

```bash
flutter run
```

### 2. Test on Devices

```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

### 3. Hot Reload

Press `r` in terminal for hot reload during development

---

## 📝 Development Checklist

### Priority 1: Core Features

- [ ] Complete Firebase setup (Android & iOS)
- [ ] Generate Freezed code
- [ ] Implement Spots feature (full CRUD)
- [ ] Implement Restaurants feature
- [ ] Implement Adventure feature
- [ ] Implement Shopping feature
- [ ] Add loading states (Shimmer)
- [ ] Add error handling UI

### Priority 2: Authentication

- [ ] Login page UI
- [ ] Email/Password authentication
- [ ] Google Sign-In
- [ ] User profile management
- [ ] Auth state persistence

### Priority 3: Gamification

- [ ] Points tracking
- [ ] Badge system
- [ ] Check-in feature (GPS verification)
- [ ] Leaderboard page
- [ ] Achievement notifications

### Priority 4: Enhanced Features

- [ ] Google Maps integration
- [ ] Search functionality
- [ ] Filter & sort options
- [ ] Favorites/Bookmarks
- [ ] Reviews & ratings
- [ ] Image upload for contributions
- [ ] Offline caching (Hive)

### Priority 5: Polish

- [ ] Animations (Lottie)
- [ ] Splash screen
- [ ] Onboarding flow
- [ ] Push notifications
- [ ] App icon & branding
- [ ] Deep linking
- [ ] Analytics tracking

---

## 🐛 Common Issues & Solutions

### Issue: Freezed code not generated

**Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

### Issue: Firebase not initialized

**Solution**: Ensure `Firebase.initializeApp()` is called in `main()` and config files are added

### Issue: Image not loading

**Solution**: Check Firebase Storage rules and ensure images exist in Firestore

### Issue: Navigation not working

**Solution**: Verify route names in `app_router.dart` match the GoRouter paths

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Freezed Package](https://pub.dev/packages/freezed)
- [GoRouter Guide](https://pub.dev/packages/go_router)

---

## 💡 Tips

1. **Use Riverpod DevTools** for debugging state
2. **Test on both Android & iOS** regularly
3. **Keep web & mobile in sync** - same Firestore collections
4. **Optimize images** before uploading to Firebase Storage
5. **Use Firebase Emulator** for local testing

---

**Ready to build! 🚀**

Next command to run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Then start implementing the data layer and connect to Firebase!
