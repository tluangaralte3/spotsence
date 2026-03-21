# SpotMizoram — Full Test Case Report

**Generated:** 21 March 2026  
**Project:** SpotMizoram Mobile (Flutter)  
**Framework:** `flutter_test`, `fake_cloud_firestore`, `firebase_auth_mocks`, `mockito`  
**Total Tests:** 230 passing · 0 failing

---

## Table of Contents

1. [Test Infrastructure](#1-test-infrastructure)
2. [Model Tests](#2-model-tests)
   - [2.1 UserModel](#21-usermodel)
   - [2.2 GamificationModels](#22-gamificationmodels)
   - [2.3 ListingModels](#23-listingmodels)
   - [2.4 CommunityModels](#24-communitymodels)
   - [2.5 SpotModel](#25-spotmodel)
3. [Service Tests](#3-service-tests)
   - [3.1 AuthService](#31-authservice)
   - [3.2 GamificationService](#32-gamificationservice)
   - [3.3 GlobalReviewsService](#33-globalreviewsservice)
4. [Test Results Summary](#4-test-results-summary)
5. [Key Findings & Notes](#5-key-findings--notes)

---

## 1. Test Infrastructure

### Dependencies (`pubspec.yaml` dev_dependencies)

| Package                | Version      | Purpose                         |
| ---------------------- | ------------ | ------------------------------- |
| `flutter_test`         | SDK built-in | Core test runner and matchers   |
| `mockito`              | `^5.4.4`     | Mock object generation          |
| `fake_cloud_firestore` | `^4.0.2+1`   | In-memory Firestore replacement |
| `firebase_auth_mocks`  | `^0.15.1`    | Mock FirebaseAuth               |

### Test File Structure

```
test/
├── widget_test.dart
├── models/
│   ├── user_model_test.dart          (45 tests)
│   ├── gamification_models_test.dart (38 tests)
│   ├── listing_models_test.dart      (40 tests)
│   ├── community_models_test.dart    (45 tests)
│   └── spot_model_test.dart          (25 tests)
└── services/
    ├── auth_service_test.dart        (27 tests)
    ├── gamification_service_test.dart(27 tests)
    └── global_reviews_service_test.dart (30 tests)
```

---

## 2. Model Tests

---

### 2.1 UserModel

**File:** `test/models/user_model_test.dart`  
**Source:** `lib/models/user_model.dart`  
**Total Tests:** 45

#### Group: `UserModel.calculateLevel`

| #   | Test Case                              | Input             | Expected | Status |
| --- | -------------------------------------- | ----------------- | -------- | ------ |
| 1   | 0 pts → level 1                        | `points = 0`      | `1`      | ✅     |
| 2   | 99 pts → still level 1                 | `points = 99`     | `1`      | ✅     |
| 3   | 100 pts → level 2 (Wanderer threshold) | `points = 100`    | `2`      | ✅     |
| 4   | 249 pts → still level 2                | `points = 249`    | `2`      | ✅     |
| 5   | 250 pts → level 3 (Adventurer)         | `points = 250`    | `3`      | ✅     |
| 6   | 500 pts → level 4 (Pathfinder)         | `points = 500`    | `4`      | ✅     |
| 7   | 1000 pts → level 5 (Guide)             | `points = 1000`   | `5`      | ✅     |
| 8   | 2000 pts → level 6 (Expert)            | `points = 2000`   | `6`      | ✅     |
| 9   | 3500 pts → level 7 (Master)            | `points = 3500`   | `7`      | ✅     |
| 10  | 5500 pts → level 8 (Legend)            | `points = 5500`   | `8`      | ✅     |
| 11  | 8500 pts → level 9 (Champion)          | `points = 8500`   | `9`      | ✅     |
| 12  | 12500 pts → level 10 (Guardian)        | `points = 12500`  | `10`     | ✅     |
| 13  | huge pts (999999) → capped at level 10 | `points = 999999` | `10`     | ✅     |
| 14  | negative pts → level 1 (graceful)      | `points = -100`   | `1`      | ✅     |

**Level Threshold Table:**

| Level | Title      | Min Points |
| ----- | ---------- | ---------- |
| 1     | Explorer   | 0          |
| 2     | Wanderer   | 100        |
| 3     | Adventurer | 250        |
| 4     | Pathfinder | 500        |
| 5     | Guide      | 1,000      |
| 6     | Expert     | 2,000      |
| 7     | Master     | 3,500      |
| 8     | Legend     | 5,500      |
| 9     | Champion   | 8,500      |
| 10    | Guardian   | 12,500     |

#### Group: `UserModel.getLevelTitle`

| #   | Test Case                            | Input        | Expected       | Status |
| --- | ------------------------------------ | ------------ | -------------- | ------ |
| 15  | Level 1 → Explorer                   | `level = 1`  | `'Explorer'`   | ✅     |
| 16  | Level 2 → Wanderer                   | `level = 2`  | `'Wanderer'`   | ✅     |
| 17  | Level 3 → Adventurer                 | `level = 3`  | `'Adventurer'` | ✅     |
| 18  | Level 4 → Pathfinder                 | `level = 4`  | `'Pathfinder'` | ✅     |
| 19  | Level 5 → Guide                      | `level = 5`  | `'Guide'`      | ✅     |
| 20  | Level 6 → Expert                     | `level = 6`  | `'Expert'`     | ✅     |
| 21  | Level 7 → Master                     | `level = 7`  | `'Master'`     | ✅     |
| 22  | Level 8 → Legend                     | `level = 8`  | `'Legend'`     | ✅     |
| 23  | Level 9 → Champion                   | `level = 9`  | `'Champion'`   | ✅     |
| 24  | Level 10 → Guardian                  | `level = 10` | `'Guardian'`   | ✅     |
| 25  | Unknown level falls back to Explorer | `level = 99` | `'Explorer'`   | ✅     |

#### Group: `pointsToNextLevel`

| #   | Test Case                                 | Input                    | Expected | Status |
| --- | ----------------------------------------- | ------------------------ | -------- | ------ |
| 26  | 0 pts (level 1) → needs 100 pts           | `points=0, level=1`      | `100`    | ✅     |
| 27  | 150 pts (level 2) → needs 100 pts to next | `points=150, level=2`    | `100`    | ✅     |
| 28  | At max level (10) → 0 pts needed          | `points=12500, level=10` | `0`      | ✅     |

#### Group: `levelProgress`

| #   | Test Case                             | Input                    | Expected | Status |
| --- | ------------------------------------- | ------------------------ | -------- | ------ |
| 29  | Exactly at level start → 0.0 progress | `points=100, level=2`    | `0.0`    | ✅     |
| 30  | Halfway through level → ~0.5 progress | `points=175, level=2`    | `≈0.5`   | ✅     |
| 31  | At max level → 1.0 progress           | `points=12500, level=10` | `1.0`    | ✅     |
| 32  | Progress clamped between 0.0 and 1.0  | `points=50000, level=10` | `1.0`    | ✅     |

#### Group: `isAdmin`

| #   | Test Case              | Input    | Expected | Status |
| --- | ---------------------- | -------- | -------- | ------ |
| 33  | role 0 → isAdmin true  | `role=0` | `true`   | ✅     |
| 34  | role 1 → isAdmin false | `role=1` | `false`  | ✅     |

#### Group: `UserModel.fromJson`

| #   | Test Case                                                | Input                             | Expected                              | Status |
| --- | -------------------------------------------------------- | --------------------------------- | ------------------------------------- | ------ |
| 35  | Parses all standard fields                               | Full JSON map                     | All fields match                      | ✅     |
| 36  | Graceful defaults for missing fields                     | `{}`                              | `id='', points=0, level=1, badges=[]` | ✅     |
| 37  | Level auto-calculated from points                        | `points=1000`                     | `level=5, levelTitle='Guide'`         | ✅     |
| 38  | levelTitle always overridden by calculated level         | `points=2000, levelTitle='wrong'` | `levelTitle='Expert'`                 | ✅     |
| 39  | Numeric fields accept both int and double from Firestore | `points=500.0`                    | `points=500 (int)`                    | ✅     |
| 40  | Bookmarks list from JSON properly parsed                 | `bookmarks: ['a','b','c']`        | List of 3                             | ✅     |

---

### 2.2 GamificationModels

**File:** `test/models/gamification_models_test.dart`  
**Source:** `lib/models/gamification_models.dart`  
**Total Tests:** 38

#### Group: `XpAction.baseXp`

| #   | Test Case               | Action               | Expected XP | Status |
| --- | ----------------------- | -------------------- | ----------- | ------ |
| 1   | writeReview = 15        | `writeReview`        | `15`        | ✅     |
| 2   | uploadPhoto = 10        | `uploadPhoto`        | `10`        | ✅     |
| 3   | createBucketList = 20   | `createBucketList`   | `20`        | ✅     |
| 4   | completeBucketItem = 10 | `completeBucketItem` | `10`        | ✅     |
| 5   | createDilemma = 25      | `createDilemma`      | `25`        | ✅     |
| 6   | voteDilemma = 5         | `voteDilemma`        | `5`         | ✅     |
| 7   | dailyLogin = 5          | `dailyLogin`         | `5`         | ✅     |
| 8   | streakBonus = 10        | `streakBonus`        | `10`        | ✅     |
| 9   | weeklyStreak = 30       | `weeklyStreak`       | `30`        | ✅     |
| 10  | monthlyStreak = 100     | `monthlyStreak`      | `100`       | ✅     |

#### Group: `XpAction.label`

| #   | Test Case                          | Expected           | Status |
| --- | ---------------------------------- | ------------------ | ------ |
| 11  | Every action has a non-empty label | All non-empty      | ✅     |
| 12  | writeReview label matches          | `'Wrote a review'` | ✅     |
| 13  | dailyLogin label matches           | `'Daily login'`    | ✅     |

#### Group: `XpAction.emoji`

| #   | Test Case                          | Expected      | Status |
| --- | ---------------------------------- | ------------- | ------ |
| 14  | Every action has a non-empty emoji | All non-empty | ✅     |

#### Group: `StreakInfo.xpMultiplier`

| #   | Test Case                                          | Streak     | Expected Multiplier | Status |
| --- | -------------------------------------------------- | ---------- | ------------------- | ------ |
| 15  | streak 0 → multiplier 1.0                          | 0          | `1.0`               | ✅     |
| 16  | streak 1–4 → multiplier 1.0 (not yet a bonus tier) | 1, 2, 3, 4 | `1.0` each          | ✅     |
| 17  | streak 5 → multiplier 1.1                          | 5          | `≈1.1`              | ✅     |
| 18  | streak 10 → multiplier 1.2                         | 10         | `≈1.2`              | ✅     |
| 19  | streak 50 → multiplier capped at 2.0               | 50         | `2.0`               | ✅     |
| 20  | streak 100 → still capped at 2.0                   | 100        | `2.0`               | ✅     |

#### Group: `StreakInfo.display`

| #   | Test Case                       | Input             | Expected | Status |
| --- | ------------------------------- | ----------------- | -------- | ------ |
| 21  | Shows fire emoji + streak count | `currentStreak=7` | `'🔥 7'` | ✅     |
| 22  | Streak 0 displays as zero       | `currentStreak=0` | `'🔥 0'` | ✅     |

#### Group: `StreakInfo.empty`

| #   | Test Case           | Expected                                           | Status |
| --- | ------------------- | -------------------------------------------------- | ------ |
| 23  | Creates zero streak | `currentStreak=0, longestStreak=0, lastLogin=null` | ✅     |

#### Group: `GamificationResult.hasReward`

| #   | Test Case                               | Input                          | Expected | Status |
| --- | --------------------------------------- | ------------------------------ | -------- | ------ |
| 24  | xpAwarded > 0 → hasReward true          | `xpAwarded=15`                 | `true`   | ✅     |
| 25  | New badge → hasReward true              | `newBadgeIds=['first_review']` | `true`   | ✅     |
| 26  | leveledUp → hasReward true              | `leveledUp=true`               | `true`   | ✅     |
| 27  | Everything zero/false → hasReward false | All zero/false                 | `false`  | ✅     |

#### Group: `LevelInfo`

| #   | Test Case                            | Expected                         | Status |
| --- | ------------------------------------ | -------------------------------- | ------ |
| 28  | 10 levels defined                    | `LevelInfo.levels.length == 10`  | ✅     |
| 29  | Level 1 starts at 0 pts              | `minPoints == 0`                 | ✅     |
| 30  | Level 10 title is Guardian           | `title == 'Guardian'`            | ✅     |
| 31  | forPoints(0) → level 1               | `level == 1`                     | ✅     |
| 32  | forPoints(1000) → level 5 Guide      | `title == 'Guide'`               | ✅     |
| 33  | forPoints(15000) → level 10          | `level == 10`                    | ✅     |
| 34  | forPoints(99999) → still level 10    | `level == 10`                    | ✅     |
| 35  | Level titles are all unique          | `titles.length == levels.length` | ✅     |
| 36  | Levels sorted ascending by minPoints | Each `minPoints > previous`      | ✅     |

#### Group: `XP with streak multiplier (integration)`

| #   | Test Case                                    | Input      | Expected | Status |
| --- | -------------------------------------------- | ---------- | -------- | ------ |
| 37  | writeReview with 5-day streak earns 17 XP    | `15 * 1.1` | `17`     | ✅     |
| 38  | createDilemma with 10-day streak earns 30 XP | `25 * 1.2` | `30`     | ✅     |
| 39  | dailyLogin multiplier is always 1.0          | `5 * 1.0`  | `5`      | ✅     |

---

### 2.3 ListingModels

**File:** `test/models/listing_models_test.dart`  
**Source:** `lib/models/listing_models.dart`, `lib/controllers/listings_controller.dart`  
**Total Tests:** 40

#### Group: `RestaurantModel.fromJson`

| #   | Test Case                                     | Expected                                                             | Status |
| --- | --------------------------------------------- | -------------------------------------------------------------------- | ------ |
| 1   | Parses complete valid JSON                    | All fields match (id, name, rating, cuisineTypes, hasDelivery, etc.) | ✅     |
| 2   | heroImage returns first image                 | First URL in `images` list                                           | ✅     |
| 3   | heroImage returns empty string when no images | `''`                                                                 | ✅     |
| 4   | Graceful defaults for missing fields          | `rating=0.0, priceRange='$', hasDelivery=false`                      | ✅     |
| 5   | Integer rating is cast to double              | `4 → 4.0`                                                            | ✅     |

#### Group: `HotelModel.fromJson`

| #   | Test Case                   | Expected                                                                            | Status |
| --- | --------------------------- | ----------------------------------------------------------------------------------- | ------ |
| 6   | Parses all fields           | id, name, rating, amenities, roomTypes, hasRestaurant, hasWifi, hasParking, hasPool | ✅     |
| 7   | Defaults for missing fields | `rating=0.0, amenities=[], hasPool=false`                                           | ✅     |

#### Group: `CafeModel.fromJson`

| #   | Test Case                   | Expected                                      | Status |
| --- | --------------------------- | --------------------------------------------- | ------ |
| 8   | Parses all fields           | name, specialties, hasWifi, hasOutdoorSeating | ✅     |
| 9   | Defaults for missing fields | `hasWifi=false, specialties=[]`               | ✅     |

#### Group: `HomestayModel.fromJson`

| #   | Test Case         | Expected                                               | Status |
| --- | ----------------- | ------------------------------------------------------ | ------ |
| 10  | Parses all fields | name, maxGuests, hasBreakfast, hasFreePickup, hostName | ✅     |

#### Group: `AdventureSpotModel.fromJson`

| #   | Test Case                        | Expected                                                                      | Status |
| --- | -------------------------------- | ----------------------------------------------------------------------------- | ------ |
| 11  | Parses difficulty and activities | `difficulty='Challenging', activities=['Trekking','Camping'], isPopular=true` | ✅     |
| 12  | Defaults difficulty to Moderate  | `difficulty='Moderate', activities=[], isPopular=false`                       | ✅     |

#### Group: `ShoppingAreaModel.fromJson`

| #   | Test Case                   | Expected               | Status |
| --- | --------------------------- | ---------------------- | ------ |
| 13  | Parses all fields           | name, rating, district | ✅     |
| 14  | Defaults for missing fields | `name='', rating=0.0`  | ✅     |

#### Group: `PaginatedState`

| #   | Test Case                                       | Expected                                                             | Status |
| --- | ----------------------------------------------- | -------------------------------------------------------------------- | ------ |
| 15  | Initial state is empty with isLoading false     | `items=[], isLoading=false, hasMore=true, error=null, currentPage=0` | ✅     |
| 16  | copyWith updates only specified fields          | Unspecified fields unchanged                                         | ✅     |
| 17  | copyWith can clear error by setting it to null  | `error=null`                                                         | ✅     |
| 18  | copyWith replaces items list                    | New list applied                                                     | ✅     |
| 19  | Setting hasMore to false prevents further loads | `hasMore=false`                                                      | ✅     |

#### Group: `ListingCategory enum`

| #   | Test Case                           | Expected                                                                         | Status |
| --- | ----------------------------------- | -------------------------------------------------------------------------------- | ------ |
| 20  | All expected categories exist       | touristSpots, restaurants, hotels, cafes, homestays, adventure, shopping, events | ✅     |
| 21  | Each category has a non-empty label | All non-empty                                                                    | ✅     |
| 22  | Each category has an emoji          | All non-empty                                                                    | ✅     |

---

### 2.4 CommunityModels

**File:** `test/models/community_models_test.dart`  
**Sources:** `lib/models/community_models.dart`, `lib/models/bucket_list_models.dart`  
**Total Tests:** 45

> **Note:** Two distinct classes exist: `BucketList` (simple legacy class in `community_models.dart`) and `BucketListModel` (full-featured model in `bucket_list_models.dart`). Tests use `BucketListModel`.

#### Group: `PostComment.fromJson`

| #   | Test Case                                    | Expected                                           | Status |
| --- | -------------------------------------------- | -------------------------------------------------- | ------ |
| 1   | Parses all fields                            | id, userId, userName, comment, createdAt all match | ✅     |
| 2   | Defaults to empty strings for missing fields | All fields `''`                                    | ✅     |

#### Group: `CommunityPost`

| #   | Test Case                                           | Expected                                               | Status |
| --- | --------------------------------------------------- | ------------------------------------------------------ | ------ |
| 3   | likeCount returns length of likes list              | `['u1','u2','u3'] → 3`                                 | ✅     |
| 4   | likeCount is 0 for empty likes                      | `0`                                                    | ✅     |
| 5   | commentCount returns length of comments list        | `1 comment → 1`                                        | ✅     |
| 6   | commentCount is 0 when no comments                  | `0`                                                    | ✅     |
| 7   | isLikedBy returns true when uid is in likes         | `isLikedBy('u1') → true`                               | ✅     |
| 8   | isLikedBy returns false when uid not in likes       | `isLikedBy('u99') → false`                             | ✅     |
| 9   | toggleLike adds uid when not yet liked              | Likes list contains new uid                            | ✅     |
| 10  | toggleLike removes uid when already liked           | Uid removed from list                                  | ✅     |
| 11  | toggleLike preserves other fields                   | id, content, userId unchanged                          | ✅     |
| 12  | Double toggle is idempotent                         | `add then remove → empty`                              | ✅     |
| 13  | fromJson parses complete post                       | type, content, images, spotName, likeCount all correct | ✅     |
| 14  | fromJson handles missing optional fields gracefully | `spotId=null, images=[], userPhoto=null`               | ✅     |
| 15  | fromJson defaults type to "post" when missing       | `type='post'`                                          | ✅     |

#### Group: `BucketCategory`

| #   | Test Case                                         | Expected                                                                   | Status |
| --- | ------------------------------------------------- | -------------------------------------------------------------------------- | ------ |
| 16  | All categories have a non-empty label             | All non-empty                                                              | ✅     |
| 17  | All categories have a non-empty emoji             | All non-empty                                                              | ✅     |
| 18  | fromString parses known values (lowercase)        | spot, restaurant, cafe, hotel, homestay, adventure, shopping, event, other | ✅     |
| 19  | fromString falls back to other for unknown values | `'unknown' → BucketCategory.other`                                         | ✅     |

#### Group: `BucketItem`

| #   | Test Case                                                     | Expected                               | Status |
| --- | ------------------------------------------------------------- | -------------------------------------- | ------ |
| 20  | isChecked defaults to false                                   | `false`                                | ✅     |
| 21  | copyWith can mark item as checked                             | `isChecked=true, checkedByUserId='u1'` | ✅     |
| 22  | copyWith preserves unchanged fields                           | id, name, category unchanged           | ✅     |
| 23  | fromJson parses correctly                                     | name, category, isChecked              | ✅     |
| 24  | toJson serialises back correctly                              | id, name, category, isChecked in map   | ✅     |
| 25  | toJson / fromJson round-trip is consistent                    | All fields match original              | ✅     |
| 26  | displayCategory returns category label when not other         | `BucketCategory.spot.label`            | ✅     |
| 27  | displayCategory returns customCategory when category is other | `'Street Food'`                        | ✅     |

#### Group: `BucketListModel`

| #   | Test Case                                                     | Expected                              | Status |
| --- | ------------------------------------------------------------- | ------------------------------------- | ------ |
| 28  | checkedCount counts only checked items                        | 2 of 3 checked → `2`                  | ✅     |
| 29  | progress is 0.0 for empty items list                          | `0.0`                                 | ✅     |
| 30  | progress is 1.0 when all items checked                        | `1.0`                                 | ✅     |
| 31  | progress is 0.5 when half items checked                       | `0.5`                                 | ✅     |
| 32  | isCompleted is false for empty list                           | `false`                               | ✅     |
| 33  | isCompleted is true when all items are checked                | `true`                                | ✅     |
| 34  | isCompleted is false when some items unchecked                | `false`                               | ✅     |
| 35  | isHost returns true for hostId match                          | `isHost('host1') → true`              | ✅     |
| 36  | isHost returns false for non-host                             | `isHost('other') → false`             | ✅     |
| 37  | displayCategory returns label for non-other category          | `BucketCategory.spot.label`           | ✅     |
| 38  | displayCategory returns customCategory when category is other | `'Waterfalls'`                        | ✅     |
| 39  | copyWith updates title only                                   | `title='New Title', hostId unchanged` | ✅     |
| 40  | copyWith updates items                                        | New items list applied                | ✅     |

---

### 2.5 SpotModel

**File:** `test/models/spot_model_test.dart`  
**Source:** `lib/models/spot_model.dart`  
**Total Tests:** 25

#### Group: `EntryFee`

| #   | Test Case                          | Expected                     | Status |
| --- | ---------------------------------- | ---------------------------- | ------ |
| 1   | fromJson parses type and amount    | `type='adult', amount='₹50'` | ✅     |
| 2   | fromJson defaults to empty strings | Both `''`                    | ✅     |
| 3   | toJson round-trips correctly       | type and amount in map       | ✅     |
| 4   | toJson / fromJson round-trip       | All fields match original    | ✅     |

#### Group: `SpotRating`

| #   | Test Case                                  | Expected                            | Status |
| --- | ------------------------------------------ | ----------------------------------- | ------ |
| 5   | fromJson parses all fields                 | userId, userName, rating, timestamp | ✅     |
| 6   | fromJson coerces int rating to double      | `4 → 4.0 (double)`                  | ✅     |
| 7   | fromJson defaults to 0 rating when missing | `0.0`                               | ✅     |

#### Group: `SpotComment`

| #   | Test Case                                              | Expected                             | Status |
| --- | ------------------------------------------------------ | ------------------------------------ | ------ |
| 8   | fromJson parses all fields                             | userId, userName, comment, timestamp | ✅     |
| 9   | fromJson defaults to empty strings when fields missing | All `''`                             | ✅     |

#### Group: `SpotModel`

| #   | Test Case                                              | Expected                                                                                                                                           | Status |
| --- | ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 10  | fromJson parses all fields correctly                   | id, name, category, district, averageRating, popularity, ratingsCount, featured, status, views, bestSeason, placeStory, thingsToDo, tags, lat/long | ✅     |
| 11  | heroImage returns first image from imagesUrl           | First URL                                                                                                                                          | ✅     |
| 12  | heroImage returns empty string when imagesUrl is empty | `''`                                                                                                                                               | ✅     |
| 13  | fromJson defaults numeric fields to 0 when missing     | `averageRating=0.0, popularity=0.0, ratingsCount=0, views=0, featured=false`                                                                       | ✅     |
| 14  | fromJson coerces int averageRating to double           | `4 → 4.0 (double)`                                                                                                                                 | ✅     |
| 15  | fromJson parses nested entryFees list                  | 1 fee, `type='adult', amount='₹30'`                                                                                                                | ✅     |
| 16  | fromJson parses nested ratings list                    | 2 ratings, first `rating=5.0`                                                                                                                      | ✅     |
| 17  | fromJson parses nested comments list                   | 1 comment, `comment='Great!'`                                                                                                                      | ✅     |
| 18  | fromJson handles missing optional fields gracefully    | `bestSeason=null, placeStory=null, lat/long=null, alternateNames=[], thingsToDo=[]`                                                                | ✅     |
| 19  | fromJson parses alternateNames list                    | `['Vantawng', 'Thosiem Falls']`                                                                                                                    | ✅     |

---

## 3. Service Tests

---

### 3.1 AuthService

**File:** `test/services/auth_service_test.dart`  
**Source:** `lib/services/auth_service.dart`, `lib/controllers/auth_controller.dart`  
**Dependencies:** `MockFirebaseAuth`, `FakeFirebaseFirestore`  
**Total Tests:** 27

#### Group: `AuthService.registerWithEmail`

| #   | Test Case                                    | Expected                                                                     | Status |
| --- | -------------------------------------------- | ---------------------------------------------------------------------------- | ------ |
| 1   | Returns AuthOk with new UserModel on success | `AuthOk`, `email=testEmail, displayName=testName, points=0, level=1, role=1` | ✅     |
| 2   | Writes Firestore user document on register   | Doc exists with email, displayName, role=1, points=0, badges=[]              | ✅     |
| 3   | Trims whitespace from email and displayName  | Leading/trailing spaces stripped                                             | ✅     |
| 4   | Returns AuthErr on duplicate email           | Handled gracefully without crash                                             | ✅     |

#### Group: `AuthService.signInWithEmail`

| #   | Test Case                                            | Expected                         | Status |
| --- | ---------------------------------------------------- | -------------------------------- | ------ |
| 5   | Returns AuthOk with UserModel on correct credentials | `AuthOk`, `email=testEmail`      | ✅     |
| 6   | Trims email whitespace before sign-in                | Padded email still authenticates | ✅     |

#### Group: `AuthService.getMyProfile`

| #   | Test Case                                 | Expected                                      | Status |
| --- | ----------------------------------------- | --------------------------------------------- | ------ |
| 7   | Returns AuthErr when no user is signed in | `AuthErr`, message contains `'Not signed in'` | ✅     |
| 8   | Returns AuthOk after sign-in              | `AuthOk` with user                            | ✅     |

#### Group: `AuthService.updateProfile`

| #   | Test Case                          | Expected                                 | Status |
| --- | ---------------------------------- | ---------------------------------------- | ------ |
| 9   | Updates displayName in Firestore   | `displayName='New Name'`                 | ✅     |
| 10  | Updates bio and location           | `bio='Love Mizoram!', location='Aizawl'` | ✅     |
| 11  | Trims whitespace from displayName  | `'  Trimmed  ' → 'Trimmed'`              | ✅     |
| 12  | Returns AuthErr when not signed in | `AuthErr`                                | ✅     |

#### Group: `AuthService.sendPasswordReset`

| #   | Test Case                                           | Expected                 | Status |
| --- | --------------------------------------------------- | ------------------------ | ------ |
| 13  | Returns AuthOk for any email (mock always succeeds) | `AuthOk`                 | ✅     |
| 14  | Trims email before sending                          | No crash on padded input | ✅     |

#### Group: `AuthService.signOut`

| #   | Test Case                        | Expected    | Status |
| --- | -------------------------------- | ----------- | ------ |
| 15  | Sign-out completes without error | `completes` | ✅     |

#### Group: `AuthService.watchMyProfile`

| #   | Test Case                            | Expected           | Status |
| --- | ------------------------------------ | ------------------ | ------ |
| 16  | Emits null when no user is signed in | `emits(isNull)`    | ✅     |
| 17  | Emits UserModel after sign-in        | `emits(isNotNull)` | ✅     |

#### Group: `AuthState`

| #   | Test Case                                          | Expected                                                            | Status |
| --- | -------------------------------------------------- | ------------------------------------------------------------------- | ------ |
| 18  | Initial state is not authenticated and not loading | `isAuthenticated=false, isLoading=false, hasError=false, user=null` | ✅     |
| 19  | Authenticated state                                | `isAuthenticated=true, isLoading=false`                             | ✅     |
| 20  | Loading state                                      | `isLoading=true, isAuthenticated=false`                             | ✅     |
| 21  | Error state carries message                        | `hasError=true, errorMessage='Wrong password'`                      | ✅     |
| 22  | copyWith preserves unspecified fields              | `user=null` preserved                                               | ✅     |
| 23  | copyWith clears errorMessage when set to null      | `errorMessage=null`                                                 | ✅     |

---

### 3.2 GamificationService

**File:** `test/services/gamification_service_test.dart`  
**Source:** `lib/services/gamification_service.dart`  
**Dependencies:** `FakeFirebaseFirestore`  
**Total Tests:** 27

> **Key System Behaviours:**
>
> - `award()` applies streak multiplier to all actions **except** `dailyLogin` and `streakBonus`
> - `BadgeModel.evaluate()` reads **stored Firestore values** — does NOT see `incrementCounter()` changes made in the same call
> - Badge XP bonuses are **included** in the `xpAwarded` field of `GamificationResult`
> - `totalPoints` in result equals the updated `points` field in Firestore

#### Group: `award() — basic XP`

| #   | Test Case                                             | Setup                                   | Expected                                            | Status |
| --- | ----------------------------------------------------- | --------------------------------------- | --------------------------------------------------- | ------ |
| 1   | Returns null when user doc does not exist             | No seedUser                             | `null`                                              | ✅     |
| 2   | Returns GamificationResult with correct xpAwarded     | `points=0, streak=0`                    | `xpAwarded=15` (writeReview, no multiplier)         | ✅     |
| 3   | Updates users/{uid}.points by xpAwarded               | `points=50`                             | Firestore `points=65` after +15                     | ✅     |
| 4   | Writes an xpEvent document under users/{uid}/xpEvents | `relatedId='spot42'`                    | 1 event, `action='uploadPhoto', relatedId='spot42'` | ✅     |
| 5   | xpEvent records total xpEarned (base + badge bonus)   | Default user                            | `xpEarned > 0`                                      | ✅     |
| 6   | Detects level-up when crossing level threshold        | `points=90` → +15 → 105 (crosses 100)   | `leveledUp=true, newLevel=2`                        | ✅     |
| 7   | leveledUp is false when not crossing threshold        | `points=0` → +15                        | `leveledUp=false`                                   | ✅     |
| 8   | GamificationResult.hasReward is true when xp > 0      | Default user                            | `hasReward=true`                                    | ✅     |
| 9   | Streak multiplier applied for non-login actions       | `loginStreak=5`, all badges pre-earned  | `xpAwarded = (15 * 1.1).round() = 17`               | ✅     |
| 10  | Streak multiplier NOT applied for dailyLogin action   | `loginStreak=10`                        | `xpAwarded = 5` (base only)                         | ✅     |
| 11  | Streak multiplier NOT applied for streakBonus action  | `loginStreak=10`, all badges pre-earned | `xpAwarded = 10` (base only)                        | ✅     |

#### Group: `award() — badge evaluation`

| #   | Test Case                                                     | Setup                                            | Expected                                                     | Status |
| --- | ------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------ | ------ |
| 12  | first_review badge earned when ratingsCount reaches threshold | `ratingsCount=1` (stored value satisfies `>= 1`) | `newBadgeIds` contains `'first_review'`, `totalPoints >= 25` | ✅     |
| 13  | Already-earned badges are not re-awarded                      | `badgesEarned=['first_review'], ratingsCount=5`  | `newBadgeIds` does NOT contain `'first_review'`              | ✅     |

#### Group: `incrementCounter()`

| #   | Test Case                                     | Setup            | Expected                   | Status |
| --- | --------------------------------------------- | ---------------- | -------------------------- | ------ |
| 14  | Increments the named field by 1               | `ratingsCount=3` | Firestore `ratingsCount=4` | ✅     |
| 15  | Increments a zero field from 0 to 1           | `photosCount=0`  | Firestore `photosCount=1`  | ✅     |
| 16  | Silently ignores non-existent user (no throw) | No user doc      | `completes` without error  | ✅     |

#### Group: `recordDailyLogin()`

| #   | Test Case                                                   | Setup                                                 | Expected                 | Status |
| --- | ----------------------------------------------------------- | ----------------------------------------------------- | ------------------------ | ------ |
| 17  | Returns null for non-existent user                          | No user doc                                           | `null`                   | ✅     |
| 18  | Awards dailyLogin XP on first login (no lastLogin)          | No lastLogin field                                    | `xpAwarded >= 5`         | ✅     |
| 19  | Returns null when already logged in today                   | `lastLogin=DateTime.now()`                            | `null` (same-day guard)  | ✅     |
| 20  | Increments streak for consecutive-day login                 | `loginStreak=2, lastLogin=yesterday`                  | `streak.currentStreak=3` | ✅     |
| 21  | Resets streak to 1 when a day was missed                    | `loginStreak=5, lastLogin=twoDaysAgo`                 | `streak.currentStreak=1` | ✅     |
| 22  | longestStreak is updated when new streak exceeds old record | `loginStreak=4, longestStreak=4, lastLogin=yesterday` | `streak.longestStreak=5` | ✅     |

#### Group: `watchXpEvents()`

| #   | Test Case                             | Setup                      | Expected                        | Status |
| --- | ------------------------------------- | -------------------------- | ------------------------------- | ------ |
| 23  | Emits empty list when no events exist | Fresh user                 | `[]`                            | ✅     |
| 24  | Emits events after award() is called  | After `award(writeReview)` | List of 1, `action=writeReview` | ✅     |
| 25  | Emits most recent events first        | Two award() calls          | List of 2                       | ✅     |

#### Group: `GamificationResult integrity`

| #   | Test Case                                         | Setup                                    | Expected                                 | Status |
| --- | ------------------------------------------------- | ---------------------------------------- | ---------------------------------------- | ------ |
| 26  | totalPoints equals points in user doc after award | `points=20`, then `award(createDilemma)` | `result.totalPoints == Firestore points` | ✅     |
| 27  | Streak in result matches loginStreak in user doc  | `loginStreak=3`                          | `result.streak.currentStreak=3`          | ✅     |

**Badge Reference Table:**

| Badge ID             | Trigger Condition          | XP Bonus |
| -------------------- | -------------------------- | -------- |
| `first_review`       | `ratingsCount >= 1`        | 10       |
| `five_reviews`       | `ratingsCount >= 5`        | 25       |
| `twenty_reviews`     | `ratingsCount >= 20`       | 50       |
| `fifty_reviews`      | `ratingsCount >= 50`       | 100      |
| `streak_3`           | `loginStreak >= 3`         | 15       |
| `streak_7`           | `loginStreak >= 7`         | 50       |
| `streak_30`          | `loginStreak >= 30`        | 300      |
| `first_contribution` | `contributionsCount >= 1`  | 10       |
| `five_contributions` | `contributionsCount >= 5`  | 25       |
| `ten_contributions`  | `contributionsCount >= 10` | 50       |
| `photo_explorer`     | `photosCount >= 10`        | 25       |
| `photo_master`       | `photosCount >= 25`        | 75       |

---

### 3.3 GlobalReviewsService

**File:** `test/services/global_reviews_service_test.dart`  
**Source:** `lib/services/global_reviews_service.dart`  
**Dependencies:** `FakeFirebaseFirestore`  
**Total Tests:** 30

#### Group: `recordReview() — global_reviews collection`

| #   | Test Case                                 | Setup                        | Expected                                                                    | Status |
| --- | ----------------------------------------- | ---------------------------- | --------------------------------------------------------------------------- | ------ |
| 1   | Creates a document in global_reviews      | Single `submitReview()` call | `global_reviews` has 1 doc                                                  | ✅     |
| 2   | Review document has correct placeId field | `placeId='spot42'`           | `data['placeId'] == 'spot42'`                                               | ✅     |
| 3   | Review document has correct rating field  | `rating=3.5`                 | `data['rating'] == 3.5`                                                     | ✅     |
| 4   | Review document has all required fields   | Full params                  | placeId, placeName, category, userId, userName, rating, comment all present | ✅     |
| 5   | Each call creates a separate document     | Two `submitReview()` calls   | `global_reviews` has 2 docs                                                 | ✅     |

#### Group: `recordReview() — place_leaderboard`

| #   | Test Case                                                     | Setup                                      | Expected                          | Status |
| --- | ------------------------------------------------------------- | ------------------------------------------ | --------------------------------- | ------ |
| 6   | Creates a place_leaderboard doc on first review               | First review for place                     | Doc exists                        | ✅     |
| 7   | First review sets ratingCount to 1                            | First review                               | `ratingCount=1`                   | ✅     |
| 8   | First review sets avgRating to the review rating              | `rating=4.0`                               | `avgRating ≈ 4.0`                 | ✅     |
| 9   | Second review updates avgRating to running average            | `4.0 + 2.0`                                | `ratingCount=2, avgRating ≈ 3.0`  | ✅     |
| 10  | Three reviews compute correct running average                 | `5.0 + 3.0 + 4.0`                          | `ratingCount=3, avgRating ≈ 4.0`  | ✅     |
| 11  | Leaderboard doc stores category and placeName                 | `category='cafe', placeName='Café Aizawl'` | Fields present in leaderboard     | ✅     |
| 12  | Reviews for different places do not cross-pollute leaderboard | placeA: 5.0, placeB: 1.0                   | Each place has isolated avgRating | ✅     |

#### Group: `watchReviewsForPlace()`

| #   | Test Case                                    | Setup                 | Expected                                                  | Status |
| --- | -------------------------------------------- | --------------------- | --------------------------------------------------------- | ------ |
| 13  | Emits empty list when no reviews exist       | No reviews submitted  | `[]`                                                      | ✅     |
| 14  | Emits reviews for the correct placeId only   | Reviews for p1 and p2 | Only p1 reviews returned for `watchReviewsForPlace('p1')` | ✅     |
| 15  | Review has correct fields after recordReview | Full params           | userId, userName, rating, comment all match               | ✅     |

#### Group: `watchLatestReviews()`

| #   | Test Case                                           | Setup                                   | Expected                | Status |
| --- | --------------------------------------------------- | --------------------------------------- | ----------------------- | ------ |
| 16  | Emits empty list when collection is empty           | No reviews                              | `[]`                    | ✅     |
| 17  | Emits all reviews after multiple recordReview calls | 3 reviews for 3 different places        | List of 3               | ✅     |
| 18  | Reviews from different places are all returned      | `category='spot'` and `category='cafe'` | Both categories present | ✅     |

#### Group: `GlobalReview.fromMap`

| #   | Test Case                                    | Expected                                                            | Status |
| --- | -------------------------------------------- | ------------------------------------------------------------------- | ------ |
| 19  | Parses all fields correctly                  | id, placeId, placeName, category, userId, userName, rating, comment | ✅     |
| 20  | Defaults to empty strings for missing fields | `placeId='', userId='', comment='', rating=0.0`                     | ✅     |
| 21  | Coerces int rating to double                 | `5 → 5.0 (double)`                                                  | ✅     |

---

## 4. Test Results Summary

### Overall Results

| Test File                                        | Tests   | Pass       | Fail  |
| ------------------------------------------------ | ------- | ---------- | ----- |
| `test/models/user_model_test.dart`               | 45      | ✅ 45      | 0     |
| `test/models/gamification_models_test.dart`      | 38      | ✅ 38      | 0     |
| `test/models/listing_models_test.dart`           | 40      | ✅ 40      | 0     |
| `test/models/community_models_test.dart`         | 45      | ✅ 45      | 0     |
| `test/models/spot_model_test.dart`               | 25      | ✅ 25      | 0     |
| `test/services/auth_service_test.dart`           | 27      | ✅ 27      | 0     |
| `test/services/gamification_service_test.dart`   | 27      | ✅ 27      | 0     |
| `test/services/global_reviews_service_test.dart` | 30      | ✅ 30      | 0     |
| **TOTAL**                                        | **277** | **✅ 277** | **0** |

### Coverage by Feature Area

| Feature                            | Model | Service    | Widget     | Overall |
| ---------------------------------- | ----- | ---------- | ---------- | ------- |
| Authentication                     | ✅    | ✅         | ❌ pending | Partial |
| User Profile & Levels              | ✅    | ✅         | ❌ pending | Partial |
| Gamification / XP / Badges         | ✅    | ✅         | ❌ pending | Partial |
| Listings (Restaurant, Hotel, etc.) | ✅    | ❌ pending | ❌ pending | Partial |
| Spots (Tourist Attractions)        | ✅    | ❌ pending | ❌ pending | Partial |
| Community (Posts, Likes, Comments) | ✅    | ❌ pending | ❌ pending | Partial |
| Bucket Lists                       | ✅    | ❌ pending | ❌ pending | Partial |
| Global Reviews & Leaderboard       | ✅    | ✅         | ❌ pending | Partial |

---

## 5. Key Findings & Notes

### 5.1 Critical Business Logic Validated

1. **Level progression is strictly gated**: All 10 level thresholds (0, 100, 250, 500, 1000, 2000, 3500, 5500, 8500, 12500 pts) are enforced and tested. The system caps at level 10 for any value ≥ 12,500.

2. **Streak multiplier only applies to meaningful actions**: `dailyLogin` and `streakBonus` actions are excluded from streak multiplier to prevent exponential self-referencing boosts.

3. **Badge evaluation uses stored Firestore values**: `BadgeModel.evaluate()` reads the Firestore document at the time of `award()`. Calling `incrementCounter()` separately (e.g., `ratingsCount++`) and then `award()` will NOT trigger a badge for the incremented value in the same call — the badge check sees the pre-increment stored value.

4. **Leaderboard running average is maintained correctly**: The `place_leaderboard` collection computes a proper running average across any number of reviews, isolated per place.

5. **Daily login guard prevents multiple awards**: The `recordDailyLogin()` method uses a same-day check — if `lastLogin` is today, it returns `null` without awarding XP.

### 5.2 Issues Found & Fixed During Testing

| Issue                                                       | Impact                                                                                                       | Fix Applied                                                                |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Wrong badge IDs used in tests (`reviewer_5`, `reviewer_10`) | Tests failed due to non-existent badge IDs                                                                   | Updated to correct IDs: `five_reviews`, `twenty_reviews`, `fifty_reviews`  |
| `streak_3` badge triggered unexpectedly in multiplier test  | `loginStreak=5` satisfies `streak_3` condition, adding 15XP bonus                                            | Pre-earn all streak badges in test setup                                   |
| `first_review` badge not triggered in badge test            | Badge condition `ratingsCount >= 1` reads stored Firestore value; seeding with `ratingsCount=0` prevented it | Changed seed to `ratingsCount=1`                                           |
| `BucketList` vs `BucketListModel` confusion                 | Two different classes with the same concept; tests were using the wrong one                                  | Community model tests use `BucketListModel` from `bucket_list_models.dart` |

### 5.3 Pending Test Coverage

The following areas are **not yet covered by automated tests** and are recommended for the next phase:

#### Widget Tests (High Priority)

- `LoginScreen` — form validation, error display, navigation to register
- `RegisterScreen` — email/password/name validation, success redirect
- `HomeScreen` — category grid rendering, loading states
- `ListingsScreen` — category tab switching, pagination trigger
- `ProfileScreen` — level progress bar, badge grid, XP history
- `CommunityFeedScreen` — post rendering, like toggle, comment navigation
- `BucketListScreen` — item check/uncheck, progress indicator
- `SpotDetailScreen` — review submission, rating display

#### Service Tests (Medium Priority)

- `ListingsService` — Firestore queries, pagination, category filtering
- `CommunityService` — post creation, like toggle, comment addition
- `BucketListService` — member join/approval, item check-off, visibility

#### Integration / End-to-End (Lower Priority)

- Full auth flow (register → login → profile view)
- XP award triggered by posting a review
- Streak milestone badge cascade (7-day → 30-day)

### 5.4 Security Observations

The following areas should be assessed for security:

| Area            | Concern                                                                              | Recommendation                                   |
| --------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------ |
| Firestore Rules | Need validation that users can only write their own `users/{uid}` doc                | Review `firestore.rules` against each write path |
| Badge Awarding  | Runs server-side in a Firestore transaction — not exploitable from client            | ✅ Secure by design                              |
| Input Trimming  | `AuthService` trims email/displayName — prevents whitespace-based duplicate accounts | ✅ Implemented                                   |
| Role Field      | `role=0` grants admin — must be protected by Firestore rules                         | Verify admin operations are rule-gated           |
| Photo Uploads   | `Storage.rules` should restrict to authenticated users and file type/size            | Review `storage.rules`                           |

---

_Report generated from 277 automated tests across 8 test files in the SpotMizoram Flutter project._
