# xplooria — Comprehensive Project Documentation

> **xplooria** (package: `spotmizoram`) is a gamified tourism discovery platform for Mizoram, Northeast India.  
> **Tagline:** *"Spot the Soul of Mizoram. Discover Places. Discover Mizoram."*

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack & Dependencies](#2-technology-stack--dependencies)
3. [Architecture Overview](#3-architecture-overview)
4. [User Roles & Permissions](#4-user-roles--permissions)
5. [Navigation & Routing](#5-navigation--routing)
6. [Design System](#6-design-system)
7. [Data Models](#7-data-models)
8. [Services Layer](#8-services-layer)
9. [State Management — Controllers & Providers](#9-state-management--controllers--providers)
10. [Features & Screens](#10-features--screens)
    - [Onboarding](#101-onboarding)
    - [Authentication](#102-authentication)
    - [Home Screen](#103-home-screen)
    - [Explore / Listings](#104-explore--listings-hub)
    - [Place Detail Screens](#105-place-detail-screens)
    - [Search](#106-search)
    - [Community](#107-community)
    - [Leaderboard](#108-leaderboard)
    - [Profile](#109-profile)
    - [Contribute](#1010-contribute)
    - [Dare & Venture (Tour Packages)](#1011-dare--venture-tour-packages)
    - [Admin Panel](#1012-admin-panel)
11. [Gamification System](#11-gamification-system)
12. [Firebase Collections & Data Structure](#12-firebase-collections--data-structure)
13. [API Integration](#13-api-integration)
14. [District Detection](#14-district-detection)
15. [Widgets Library](#15-widgets-library)
16. [Key Architectural Patterns](#16-key-architectural-patterns)
17. [Security & Environment Configuration](#17-security--environment-configuration)

---

## 1. Project Overview

| Field | Value |
|---|---|
| **Package name** | `spotmizoram` |
| **App display name** | xplooria |
| **Version** | 1.0.0+1 |
| **Dart SDK constraint** | `^3.10.8` |
| **Supported platforms** | Android & iOS |
| **State management** | Flutter Riverpod v3 |
| **Navigation** | GoRouter v17 |
| **Database** | Cloud Firestore (primary) |
| **Auth** | Firebase Authentication |
| **Storage** | Firebase Storage |

xplooria helps travellers and locals discover tourist spots, restaurants, cafes, hotels, homestays, adventure activities, and cultural events across Mizoram. The app rewards user engagement through a gamification layer: XP points, level progression, streak tracking, and a badge system. Users can curate bucket lists, debate "place dilemmas", submit community posts, and contribute new spot discoveries — all while competing on leaderboards.

---

## 2. Technology Stack & Dependencies

### Firebase Services

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.4.0 | Firebase app initialization |
| `firebase_auth` | ^6.1.4 | Email/password authentication, ID token management |
| `cloud_firestore` | ^6.1.2 | Primary database for all app collections |
| `firebase_storage` | ^13.0.6 | Image and file storage |
| `firebase_analytics` | ^12.1.2 | User behaviour analytics |

### State Management

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^3.1.0 | Primary state management (providers, notifiers) |
| `riverpod_annotation` | ^4.0.0 | Code-generation annotations for Riverpod |

### Navigation

| Package | Version | Purpose |
|---|---|---|
| `go_router` | ^17.1.0 | Declarative routing with auth guards and shell routes |

### Networking

| Package | Version | Purpose |
|---|---|---|
| `dio` | ^5.7.0 | HTTP client for REST API calls |
| `pretty_dio_logger` | ^1.4.0 | Debug-mode request/response logging |

### Local Storage

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | ^2.3.2 | Persists theme mode, onboarding completion flag |
| `flutter_secure_storage` | ^10.0.0 | Secure key-value store for sensitive data |

### UI & Animations

| Package | Version | Purpose |
|---|---|---|
| `google_fonts` | ^8.0.2 | Inter font family throughout the app |
| `cached_network_image` | ^3.4.1 | Cached image loading with shimmer placeholders |
| `shimmer` | ^3.0.0 | Skeleton loading effect for images |
| `lottie` | ^3.1.2 | Lottie JSON animation files |
| `flutter_animate` | ^4.5.0 | Declarative widget animation chains |
| `flutter_svg` | ^2.0.9 | SVG icon and illustration rendering |
| `percent_indicator` | ^4.2.4 | XP progress bar (`LinearPercentIndicator`) |
| `fl_chart` | ^1.1.1 | Analytics bar/pie charts in Admin panel |
| `confetti` | ^0.8.0 | Confetti particle effect for level-up celebrations |
| `cupertino_icons` | ^1.0.8 | iOS-style icon set |

### Forms & Validation

| Package | Version | Purpose |
|---|---|---|
| `flutter_form_builder` | ^10.3.0+2 | Rich form widgets (dropdowns, date pickers, etc.) |
| `form_builder_validators` | ^11.3.0 | Validation rules for form fields |

### Image Handling

| Package | Version | Purpose |
|---|---|---|
| `image_picker` | ^1.1.2 | Camera and gallery image selection |
| `image_cropper` | ^11.0.0 | Image cropping UI |
| `image` | ^4.3.0 | Image manipulation and processing |

### Maps & Location

| Package | Version | Purpose |
|---|---|---|
| `flutter_map` | ^8.2.2 | OpenStreetMap-based map tiles (community map) |
| `latlong2` | ^0.9.1 | Latitude/longitude coordinate types |
| `geolocator` | ^14.0.2 | Device GPS location access |
| `geocoding` | ^4.0.0 | Reverse geocoding (coordinates → address) |

### Serialization

| Package | Version | Purpose |
|---|---|---|
| `freezed_annotation` | ^3.1.0 | Immutable data class code generation |
| `json_annotation` | ^4.9.0 | JSON serialization code generation |
| `equatable` | ^2.0.5 | Value equality for state objects |

### Utilities

| Package | Version | Purpose |
|---|---|---|
| `intl` | ^0.20.2 | Date/number formatting, internationalization |
| `timeago` | ^3.7.0 | Human-readable relative timestamps ("2 hours ago") |
| `uuid` | ^4.5.1 | UUID generation for document IDs |
| `url_launcher` | ^6.3.0 | Open URLs, phone dialer, email client |
| `share_plus` | ^12.0.1 | Native OS share sheet |
| `connectivity_plus` | ^7.0.0 | Network connectivity detection |
| `package_info_plus` | ^9.0.0 | App version and build number |
| `path_provider` | ^2.1.1 | Platform file system paths |
| `logger` | ^2.0.2+1 | Structured logging |
| `dartz` | ^0.10.1 | Functional programming Either/Option types |

### Admin / Bulk Operations

| Package | Version | Purpose |
|---|---|---|
| `file_picker` | ^8.1.7 | File picker for CSV upload in admin |
| `csv` | ^6.0.0 | CSV parsing for bulk listing import |

### Dev Dependencies

| Package | Purpose |
|---|---|
| `build_runner` | Code generation runner |
| `freezed` | Immutable class code generation |
| `json_serializable` | JSON serialization code generation |
| `riverpod_generator` | Riverpod provider code generation |
| `mockito` | Test mocking framework |
| `fake_cloud_firestore` | Firestore in-memory mock for unit tests |
| `firebase_auth_mocks` | Firebase Auth mock for unit tests |
| `flutter_launcher_icons` | App icon generation tool |

---

## 3. Architecture Overview

The app follows a **service → controller → screen** layered architecture using Flutter Riverpod for dependency injection and state management.

```
lib/
├── main.dart                        Entry point — Firebase init, ProviderScope, MaterialApp.router
├── firebase_options.dart            FlutterFire-generated platform configuration
├── core/
│   ├── constants/app_constants.dart API URL, pagination limits, XP values, categories
│   ├── providers/district_provider.dart  GPS-based district detection
│   ├── router/app_router.dart       GoRouter — all routes, auth guards, shell routes
│   └── theme/
│       ├── app_theme.dart           AppColors, AppTheme.light/.dark, AppColorScheme
│       └── theme_controller.dart    ThemeMode persisted to SharedPreferences
├── models/                          Pure data classes (fromJson/fromFirestore/toJson)
├── services/                        Firestore + REST API data access layer
├── controllers/                     Riverpod Notifiers providing state to UI
├── screens/                         ConsumerWidget / ConsumerStatefulWidget pages
└── widgets/                         Reusable widget library
```

### State Management Patterns

| Pattern | Use Case |
|---|---|
| `AsyncNotifier<T>` | Auth state (async loading states) |
| `Notifier<T>` | Most domain controllers (spots, events, listings) |
| `StreamProvider` | Live Firestore collection streams |
| `FutureProvider` | One-shot async data fetches |
| `FutureProvider.family` | Parameterised async lookups (e.g., spot by ID) |
| `StreamProvider.family` | Parameterised live streams |

---

## 4. User Roles & Permissions

### Role Overview

| Role | Identifier | Description |
|---|---|---|
| **Regular User** | `role: 1` (Firestore) | Default for all registered users |
| **Admin** | `role: 0` (Firestore, legacy) | Superseded by Firebase custom claim |
| **Super Admin** | `superAdmin: true` (Firebase custom claim) | Full admin panel access |

---

### Regular User — Full Capability List

**Discovery & Browsing**
- Browse all tourist spots, restaurants, cafes, hotels, homestays, adventure spots, shopping areas
- View full detail pages for any listing including photos, reviews, entry fees, location map
- Browse and filter events by type, category, date
- Browse Dare & Venture tour packages with category/season/difficulty filters
- View all community posts in the community feed

**Search**
- Search tourist spots by name/keyword via the search screen (REST API backed)

**Reviews & Ratings**
- Write star ratings and comment reviews on any listing (tourist spots, restaurants, hotels, cafes, etc.)
- Reviews are stored in subcollections under each listing; avg rating is recalculated on each submission

**Bookmarks**
- Bookmark/save any spot — stored as a list of spot IDs in the user's Firestore document
- View all bookmarked spots in the Profile → Saved tab

**Community**
- Create community posts (type: post, review, tip, or question) with optional images and spot tagging
- Like and comment on other users' community posts
- Delete and edit own posts

**Bucket Lists**
- Create personal or shared bucket lists with a title, description, banner image, visibility setting, and max member count
- Each bucket list contains items (spots, restaurants, cafes, hotels, etc.) with notes
- Check off bucket items to mark them as visited (earns XP)
- Join public bucket lists by join code
- Manage members (host can approve/decline join requests)

**Dilemmas**
- Create "Which do you prefer?" dilemma polls with two place options
- Vote on other users' dilemmas (earns 5 XP per vote)
- View vote percentages in real time

**Gamification**
- Earn XP for all interactive actions (reviews, photos, daily logins, dilemmas, bucket lists)
- Progress through 10 named levels (Explorer → Guardian)
- Unlock 22 badges across 5 categories
- Maintain daily login streaks for bonus XP and streak badges
- View personal XP history in the Activity tab

**Profile Management**
- Set display name, bio, location, and profile photo
- Toggle between light and dark themes

**Contribute**
- Submit new tourist spot discovery (name, category, description, location, up to 5 photos)
- Earn 10 XP when the submitted spot is approved by an admin

**Map**
- View community map (OpenStreetMap) with pins for known spots
- Tap map pins to view a place detail bottom sheet

---

### Super Admin — Full Capability List

Super Admin requires both Firebase Authentication AND a `superAdmin: true` custom claim set on the account. The super admin email is `hillstechadmin@xplooria.com`.

Super Admins have ALL regular user capabilities PLUS:

**Admin Dashboard**
- View real-time counts for 10 Firestore collections (spots, restaurants, hotels, cafes, homestays, adventure spots, shopping areas, events, ventures, tour packages)
- View admin profile card with role badge and active permissions

**Listings Management (8 Collection Types)**
- **Create** new listings for: Tourist Spots, Restaurants, Hotels/Accommodations, Cafes, Homestays, Adventure Spots, Shopping Areas, Events
- **Edit** any existing listing including all fields (images, descriptions, metadata, etc.)
- **Delete** any listing with confirmation dialog
- **Bulk import** any collection from a CSV file (upload → parse → preview → write to Firestore)

**Ventures Management**
- Full CRUD on the `ventures` collection (Dare & Venture tour packages)
- Manage pricing tiers, addons, challenges, achievement medals, availability, featured status

**Users Management**
- View all registered users with display name, email, level, XP, and role
- Search/filter the user list
- View full user detail (all stats)

**Analytics**
- Real-time `AppAnalyticsSnapshot` stream showing:
  - Total users, new users today, new users this week
  - Total spots, listings, events, ventures
  - Total community posts, reviews, booking requests (pending/total)
  - Total XP points awarded
- Visual charts via `fl_chart`

**Moderation**
- Review community-submitted spot contributions (approve/reject)
- Manage community reports

**Admin Activity Log**
- Every admin action (create/update/delete) is logged to `app_admins/{uid}/activityLog`

---

### `AdminRole` Enum (Fine-Grained Future Use)

| Enum Value | Label | Permissions |
|---|---|---|
| `superAdmin` | 👑 Super Admin | All permissions true |
| `moderator` | 🛡️ Moderator | `canManageCommunity`, `canViewAnalytics` |
| `analyst` | 📊 Analyst | `canViewAnalytics` only |

### `AdminPermissions` Flags

`canManageSpots` · `canManageListings` · `canManageEvents` · `canManageVentures` · `canManageUsers` · `canViewAnalytics` · `canManageCommunity` · `canManageAdmins`

---

## 5. Navigation & Routing

The app uses **GoRouter v17** (`appRouterProvider`) for declarative routing with type-safe route constants.

### Route Constants — Complete Table

| Route Constant | Path | Description |
|---|---|---|
| `onboarding` | `/onboarding` | First-launch 3-page carousel |
| `login` | `/login` | Email/password login (slide transition) |
| `register` | `/register` | New account registration (slide transition) |
| `forgotPassword` | `/forgot-password` | Password reset email |
| `home` | `/` | Main home screen |
| `spots` | `/spots` | Redirects to `/listings` |
| `spotDetail` | `/spots/:id` | Tourist spot detail (fade transition) |
| `search` | `/search` | Spot search screen |
| `listings` | `/listings` | Explore hub (tab index via `?tab=N`) |
| `listingDetail` | `/listings/:type/:id` | Generic listing detail |
| `community` | `/community` | Community screen (3 tabs) |
| `createPost` | `/community/new` | Create post (auth-protected) |
| `createBucketList` | `/community/bucket-lists/new` | Create bucket list |
| `bucketListDetail` | `/community/bucket-lists/:id` | Bucket list detail |
| `editBucketList` | `/community/bucket-lists/:id/edit` | Edit bucket list metadata |
| `addBucketItem` | `/community/bucket-lists/:listId/add-item` | Add item to bucket list |
| `contribute` | `/contribute` | Spot contribution form (auth-protected) |
| `leaderboard` | `/leaderboard` | Place quality leaderboard |
| `profile` | `/profile` | User profile (auth-protected) |
| `editProfile` | `/profile/edit` | Edit profile details |
| `tourPackages` | `/packages` | Dare & Venture packages |
| `packageDetail` | `/packages/:id` | Venture detail (fade transition) |
| `ventureDetail` | `/ventures/:id` | Public venture detail (raw Firestore) |
| `eventDetail` | `/events/:id` | Event detail screen |
| `allReviews` | `/reviews/:collection/:id` | All reviews for any listing |
| `admin` | `/admin` | Admin dashboard (super admin gate) |
| `adminListings` | `/admin/listings` | Listings management |
| `adminUsers` | `/admin/users` | Users management |
| `adminAnalytics` | `/admin/analytics` | Analytics screen |
| `adminVentures` | `/admin/ventures` | Ventures management |
| `adminModeration` | `/admin/moderation` | Content moderation |
| `adminAddListing` | `/admin/listings/add/:collection` | Add new listing by collection type |
| `adminEditListing` | `/admin/listings/edit/:collection/:docId` | Edit existing listing |
| `adminAddVenture` | `/admin/ventures/add` | Add new venture |
| `adminEditVenture` | `/admin/ventures/edit/:docId` | Edit existing venture |

### Auth Guard Logic

- **Unauthenticated → protected route** → redirect to `/login`
- **Authenticated → auth routes** (login/register) → redirect to `/`
- **`/admin/*`** → requires authenticated + `superAdmin` custom claim == `true`
- **Onboarding** → shown once; completion flag stored in `SharedPreferences` under key `onboarding_done`

### Shell Structure

**`MainShell`** — Wraps all primary app routes. Provides bottom navigation bar with 5 tabs:

| Tab | Label | Icon | Route |
|---|---|---|---|
| 0 | Home | Home icon | `/` |
| 1 | Explore | Map icon | `/listings` |
| 2 | Rankings | Trophy icon | `/leaderboard` |
| 3 | Community | People icon | `/community` |
| 4 | Profile | Person icon | `/profile` |

- `initState` of `MainShell` calls `gamificationController.recordDailyLogin()` on every app foreground
- Wraps child widget in `XpToastOverlay` for global XP reward notifications

**`AdminShell`** — Separate shell for all `/admin/*` routes:
- No bottom nav conflict with the main shell
- Side-drawer navigation on large screens
- Wraps content in `HeroControllerScope` with new `MaterialHeroController` to prevent Hero tag conflicts

---

## 6. Design System

### Brand Colours (`AppColors`)

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#00E5A0` | Primary actions, buttons, active nav, highlights |
| `primaryDim` | `#00B37A` | Dimmed/pressed primary |
| `secondary` | `#6C63FF` | Indigo — secondary accents, badges |
| `accent` / `gold` | `#FFB300` | XP chips, star ratings, legendary badge rewards |
| `bg` | `#0A0E1A` | App background (dark theme) |
| `surface` | `#121827` | Card backgrounds (dark theme) |
| `surfaceElevated` | `#1C2333` | Elevated card backgrounds (dark theme) |
| `border` | `#2A3347` | Dividers, card borders |
| `textPrimary` | `#F0F4FF` | Primary text (dark theme) |
| `textSecondary` | `#8892A4` | Secondary/subtitle text |
| `textMuted` | `#4A5568` | Disabled/placeholder text |
| `success` | `#22C55E` | Success states, approved indicators |
| `error` | `#EF4444` | Error states, destructive actions |
| `warning` | `#F59E0B` | Warning states |
| `info` | `#3B82F6` | Informational states |
| `rarityCommon` | `#9E9E9E` | Common badge colour |
| `rarityRare` | `#42A5F5` | Rare badge colour (blue) |
| `rarityEpic` | `#AB47BC` | Epic badge colour (purple) |
| `rarityLegendary` | `#FFB300` | Legendary badge colour (gold) |
| `silverMedal` | `#C0C0C0` | Leaderboard #2 podium |
| `bronzeMedal` | `#CD7F32` | Leaderboard #3 podium |

Light theme has equivalent `*Light` variants; `AppColorScheme` extension on `BuildContext` resolves the correct colour.

### Typography

Inter font family via `google_fonts`, applied as a Material 3 text theme override.

### Spacing & Radius Constants

| Constant | Value | Usage |
|---|---|---|
| `borderRadius` | 16.0 | General container radius |
| `cardRadius` | 16.0 | Card widget radius |
| `chipRadius` | 20.0 | Chip/pill widget radius |
| `buttonRadius` | 14.0 | Button radius |

### Theme Toggle

`ThemeController` (`Notifier<ThemeMode>`) persists dark/light mode to `SharedPreferences` (key: `app_theme`). Default: dark mode. Toggle available in Profile screen and Admin settings.

---

## 7. Data Models

### `UserModel`

Stored in Firestore `users/{uid}`.

| Field | Type | Description |
|---|---|---|
| `id` | String | Firebase UID |
| `email` | String | User email |
| `displayName` | String | Display name |
| `photoURL` | String? | Profile photo URL |
| `bio` | String? | Short bio |
| `location` | String? | User-entered location string |
| `role` | int | 0 = admin (legacy), 1 = regular user |
| `points` | int | Total accumulated XP |
| `level` | int | Current level (1–10) |
| `levelTitle` | String | Level title ("Wanderer", "Guardian", etc.) |
| `badges` | List\<String\> | Currently displayed badge IDs |
| `badgesEarned` | List\<String\> | All-time unlocked badge IDs |
| `contributionsCount` | int | Number of spot submissions |
| `ratingsCount` | int | Number of reviews written |
| `photosCount` | int | Number of community photos uploaded |
| `dilemmasCreated` | int | Number of dilemmas created |
| `dilemmasVoted` | int | Number of dilemma votes cast |
| `bucketListsCreated` | int | Number of bucket lists created |
| `bucketItemsCompleted` | int | Number of bucket items checked off |
| `loginStreak` | int | Current consecutive login days |
| `longestStreak` | int | All-time best login streak |
| `lastLogin` | DateTime? | Timestamp of last login |
| `bookmarks` | List\<String\> | Bookmarked spot IDs |
| `createdAt` | String | Account creation timestamp |

**Computed Properties:**

| Property | Description |
|---|---|
| `isAdmin` | `role == 0` |
| `isSuperAdminEmail` | Checks against hardcoded super admin email |
| `pointsToNextLevel` / `xpToNextLevel` | XP needed to reach next level |
| `levelProgress` | Float 0.0–1.0 for the XP progress bar |

**Static Methods:**
- `calculateLevel(int pts)` → returns level 1–10
- `getLevelTitle(int lvl)` → returns the level title string

---

### `SpotModel`

Stored in Firestore `spots/{id}`.

| Field | Type | Description |
|---|---|---|
| `id` | String | Firestore document ID |
| `name` | String | Spot name |
| `category` | String | waterfall, mountain, viewpoint, cultural-site, etc. |
| `locationAddress` | String | Full address string |
| `district` | String | Mizoram district name |
| `averageRating` | double | Aggregate average calculated on each review |
| `popularity` | double | Sort weight (used for featured order) |
| `ratingsCount` | int | Total number of reviews |
| `imagesUrl` | List\<String\> | Image URLs (carousel) |
| `featured` | bool | Whether shown in the featured section |
| `status` | String | `'Approved'` / `'Pending'` / `'Rejected'` |
| `views` | int | View count |
| `distance` | String? | Distance from city centre |
| `bestSeason` | String? | Recommended visiting season |
| `openingHours` | String? | Hours of operation |
| `facilities` | String? | Available facilities |
| `accessibility` | String? | Accessibility notes |
| `safetyNotes` | String? | Safety guidance |
| `officialSourceUrl` | String? | External info URL |
| `alternateNames` | List\<String\> | Other names for the spot |
| `placeStory` | String? | Long-form descriptive content |
| `thingsToDo` | List\<String\> | Activity suggestions |
| `entryFees` | List\<EntryFee\> | Fee type + amount pairs |
| `addOns` | List\<String\> | Optional extras |
| `ratings` | List\<SpotRating\> | Embedded review objects |
| `comments` | List\<SpotComment\> | Embedded comment objects |
| `tags` | List\<String\> | Searchable tags |
| `latitude` | double? | GPS latitude (for map) |
| `longitude` | double? | GPS longitude (for map) |

**Sub-models:** `EntryFee(type, amount)` · `SpotRating(userId, userName, rating, timestamp)` · `SpotComment(userId, userName, comment, timestamp)`

---

### `EventModel`

Stored in Firestore `events/{id}`.

| Field | Type | Description |
|---|---|---|
| `id` | String | Document ID |
| `title` | String | Event title |
| `description` | String | Full description |
| `location` | String | Venue address |
| `date` | DateTime? | Start date |
| `endDate` | DateTime? | End date |
| `time` | String | Start time string (e.g. "10:00 AM") |
| `endTime` | String | End time string |
| `attendees` | int | Expected attendee count |
| `category` | String | Event category |
| `imageUrl` | String | Hero/cover image |
| `type` | String | festival, cultural, adventure, personal, sports, music, food |
| `status` | String | `'Published'` / `'Draft'` |
| `tags` | List\<String\> | |
| `featured` | bool | Featured in listings |
| `createdBy` | String | Creator UID |
| `createdAt` | DateTime? | |
| `updatedAt` | DateTime? | |
| `ticketingEnabled` | bool | Phase 2 ticketing feature flag |
| `ticketPrice` | double? | Ticket price |
| `ticketCurrency` | String | Default `'INR'` |
| `totalTickets` | int? | null = unlimited |
| `ticketsBooked` | int | Bookings count |
| `ticketingDeadline` | DateTime? | Booking cutoff |

**Computed Properties:** `isUpcoming`, `isOngoing`, `isPast`, `ticketsRemaining`, `isSoldOut`, `isFree`, `canBookTicket`

---

### Listing Models (`listing_models.dart`)

#### `RestaurantModel`
`id, name, description, location, images, rating, priceRange ($–$$$$), cuisineTypes, openingHours, hasDelivery, hasReservation, district, contactPhone, website, ratingsCount, latitude, longitude`

#### `HotelModel`
`id, name, description, location, images, rating, priceRange, amenities, roomTypes, hasRestaurant, hasWifi, hasParking, hasPool, district, contactPhone, website, ratingsCount`

#### `CafeModel`
`id, name, description, location, images, rating, priceRange, specialties, openingHours, hasWifi, hasOutdoorSeating, district, contactPhone, ratingsCount, latitude, longitude`

#### `HomestayModel`
`id, name, description, location, images, rating, priceRange, amenities, district, contactPhone, website, ratingsCount`

#### `AdventureSpotModel`
`id, name, description, location, images, rating, difficulty, activities, district, contactPhone, website, ratingsCount`

#### `ShoppingAreaModel`
`id, name, description, location, images, rating, shopTypes, openingHours, district, ratingsCount`

---

### `CommunityPost` (`community_models.dart`)

| Field | Type | Description |
|---|---|---|
| `id` | String | Document ID |
| `userId` | String | Author UID |
| `userName` | String | Author display name |
| `userPhoto` | String? | Author avatar URL |
| `type` | String | post / review / tip / question |
| `content` | String | Post text body |
| `images` | List\<String\> | Attached image URLs |
| `spotId` | String? | Tagged spot/listing ID |
| `spotName` | String? | Tagged spot/listing name |
| `location` | String? | Optional location text |
| `likes` | List\<String\> | List of UIDs who liked this post |
| `comments` | List\<PostComment\> | Embedded comment objects |
| `createdAt` | DateTime | |

**Computed:** `likeCount`, `commentCount`, `isLikedBy(uid)`, `toggleLike(uid)`  
**Sub-model `PostComment`:** `id, userId, userName, comment, createdAt`

---

### `BucketListModel` (`bucket_list_models.dart`)

Full Firestore-backed bucket list model.

| Field | Type | Description |
|---|---|---|
| `id` | String | Document ID |
| `title` | String | List title |
| `description` | String | Description |
| `bannerUrl` | String | Cover image URL |
| `category` | `BucketCategory` | spot / restaurant / cafe / hotel / homestay / adventure / shopping / event / other |
| `customCategory` | String? | Custom category label |
| `visibility` | `BucketVisibility` | public / private / invite-only |
| `maxMembers` | int | Maximum member count |
| `joinCode` | String | 6-character join code for sharing |
| `hostId` | String | Creator UID |
| `hostName` | String | Creator display name |
| `hostPhoto` | String? | Creator avatar |
| `items` | List\<BucketItem\> | Individual places to visit |
| `members` | List\<BucketMember\> | Current members |
| `joinRequests` | List\<BucketMember\> | Pending join requests |
| `createdAt` | DateTime | |
| `completedAt` | DateTime? | Completion timestamp |
| `xpReward` | int | XP reward for completing the list |
| `badges` | List\<String\> | Badge IDs awarded on completion |
| `challengeTitle` | String? | Special challenge label |

**`BucketItem`:** `id, name, imageUrl?, category, customCategory?, listingId?, listingType?, note?, isChecked, checkedByUserId?, checkedByUserName?, checkedAt?`  
**`BucketMember`:** `userId, userName, userPhoto?, role (host/member), status (pending/approved/declined), joinedAt`

---

### `Dilemma` (`community_models.dart`)

| Field | Type | Description |
|---|---|---|
| `id` | String | Document ID |
| `question` | String | Poll question text |
| `optionA` | `DilemmaOption` | First place option |
| `optionB` | `DilemmaOption` | Second place option |
| `votesA` | int | Votes for option A |
| `votesB` | int | Votes for option B |
| `authorId` | String | Creator UID |
| `authorName` | String | Creator display name |
| `authorPhoto` | String? | Creator avatar |
| `status` | String | active / closed |
| `expiresAt` | DateTime? | Optional expiry |
| `createdAt` | DateTime | |

**Computed:** `totalVotes`, `percentA`, `percentB`, `isExpired`, `isActive`, `userVote(uid)` → `'A'` / `'B'` / `null`  
**`DilemmaOption`:** `spotId?, name, category?, imageUrl?, district?`

---

### `TourVentureModel` (`tour_venture_models.dart`)

Full-featured model for Dare & Venture activity packages.

**Enums:**

| Enum | Values |
|---|---|
| `PackageCategory` | birdWatching, fishing, hiking, sunrise, ecoTourism, trekking, camping, photography, cultural, wildlifeSafari, rafting, cycling, running, wellness, stargazing, other |
| `DifficultyLevel` | easy, moderate, challenging, extreme |
| `PackageSeason` | allYear, spring, summer, autumn, winter, monsoon, preMonsoon, postMonsoon |
| `MedalTier` | bronze, silver, gold, platinum, legendary |

**Core Fields:** `id, title, tagline, description, location, district, category, difficulty, season(s), images, duration, maxGroupSize, minGroupSize, pricingTiers, basePrice, organizerInfo, isAvailable, isFeatured, rating, reviewCount, tags, includedItems, excludedItems, addons, challenges, achievementMedals, registrations`

**Sub-models:**

| Sub-model | Key Fields |
|---|---|
| `PricingTier` | id, name, pricePerPerson, minPersons, maxPersons, description, includes, excludes, isPopular, isAvailable |
| `VentureAddon` | id, name, emoji, pricePerUnit, unit, description, isAvailable |
| `RentalPartner` | Partner info for gear rental |
| `VentureChallenge` | Challenge details and completion criteria |
| `VentureAchievementMedal` | medal tier, name, description, unlockCondition |
| `VentureRegistration` | userId, userName, tier, addons, status, amount, createdAt |
| `VentureFeedback` | userId, rating, comment, createdAt |

---

### `AdminModel` (`admin_model.dart`)

Stored in Firestore `app_admins/{uid}`.

| Field | Type | Description |
|---|---|---|
| `uid` | String | Firebase UID |
| `email` | String | Admin email |
| `displayName` | String | Admin display name |
| `role` | `AdminRole` | superAdmin / moderator / analyst |
| `permissions` | `AdminPermissions` | Bitfield of capability flags |
| `isActive` | bool | Account active status |
| `lastLogin` | DateTime? | Last admin login timestamp |
| `createdAt` | DateTime? | Account creation timestamp |
| `createdBy` | String | Who granted admin access |

---

### Gamification Models (`gamification_models.dart`)

#### `XpAction` Enum

| Action | XP | Trigger |
|---|---|---|
| `writeReview` | +15 | Review submission from `PlaceDetailSheet` |
| `uploadPhoto` | +10 | Community photo upload |
| `createBucketList` | +20 | `BucketListController.create()` |
| `completeBucketItem` | +10 | `BucketListController.toggleItem()` (check=true) |
| `createDilemma` | +25 | `DilemmasController.createDilemma()` |
| `voteDilemma` | +5 | `DilemmasController.vote()` |
| `dailyLogin` | +5 | `MainShell.initState()` → once per calendar day |
| `streakBonus` | +10 | Auto-triggered at streak ≥ 3 days |
| `weeklyStreak` | +30 | Auto-triggered at exactly day 7 |
| `monthlyStreak` | +100 | Auto-triggered at exactly day 30 |

#### `GamificationResult`

Returned from `GamificationService.award()`:

| Field | Type | Description |
|---|---|---|
| `xpAwarded` | int | XP earned from this action |
| `newBadgeIds` | List\<String\> | Badges unlocked this action |
| `leveledUp` | bool | Whether user leveled up |
| `newLevel` | int | New level if leveled up |
| `totalPoints` | int | New total XP |
| `streak` | int | Current streak count |

#### `XpEvent`

Written to `users/{uid}/xpEvents` subcollection on every XP award.

| Field | Description |
|---|---|
| `id` | Auto-generated document ID |
| `action` | `XpAction` string label |
| `xpEarned` | Points earned |
| `createdAt` | Timestamp |
| `relatedId` | Optional related entity ID |

#### `LeaderboardEntry`

| Field | Description |
|---|---|
| `rank` | Calculated rank number |
| `userId` | User UID |
| `userName` | Display name |
| `userPhoto` | Avatar URL |
| `points` | Total XP |
| `level` | Current level |
| `levelTitle` | Level title string |
| `badgesCount` | Number of earned badges |

#### `AppAnalyticsSnapshot`

`totalUsers, newUsersToday, newUsersThisWeek, totalSpots, totalListings, totalEvents, totalVentures, totalCommunityPosts, totalReviews, totalBookingRequests, pendingBookingRequests, totalPointsAwarded, updatedAt`

---

## 8. Services Layer

### `AuthService`

Wraps Firebase Auth + Firestore `users` collection.

| Method | Description |
|---|---|
| `signInWithEmail(email, pw)` | Email/password sign-in. Creates Firestore user doc if missing. Returns `AuthResult<UserModel>` |
| `registerWithEmail(email, pw, displayName)` | Creates Firebase Auth account, sets displayName, writes `users/{uid}` with all default fields (role=1, points=0, level=1) |
| `getMyProfile()` | Fetches or creates the Firestore user profile doc |
| `watchMyProfile()` | `Stream<UserModel?>` — live Firestore listener |
| `updateProfile(displayName?, photoURL?, bio?, location?)` | Updates Firestore doc + Firebase Auth displayName |
| `signOut()` | Signs out of Firebase Auth |
| `sendPasswordReset(email)` | Sends Firebase password reset email |
| `_fetchOrCreateProfile(user)` | Internal: creates missing Firestore docs for externally created accounts |

---

### `ApiClient` / `BaseApiService`

Dio singleton configured with:
- Base URL from `AppConstants.apiBaseUrl` (env-injected via `--dart-define`)
- `Authorization: Bearer <Firebase ID token>` auto-attached to every request
- Automatic 401 retry with a refreshed Firebase token
- `PrettyDioLogger` enabled in debug mode only
- `ApiResult<T>` wrapper with `ok`/`err` branches and `ApiMeta` pagination info
- `BaseApiService.unwrap()` — parses `{success, data, error, meta}` response envelope
- `BaseApiService.safeCall()` — converts Dio errors to typed `ApiResult.err`

---

### `CommunityService`

REST API client for `/api/community/*` endpoints.

| Method | Endpoint |
|---|---|
| `getPosts(page, pageSize)` | `GET /api/community/posts` |
| `createPost(content, type, images?, spotId?, spotName?, location?)` | `POST /api/community/posts` |
| `toggleLike(postId)` | `POST /api/community/posts/:id/like` |
| `deletePost(postId)` | `DELETE /api/community/posts/:id` |
| `updatePost(postId, content, type)` | `PUT /api/community/posts/:id` |
| `getMyPosts(userId)` | `GET /api/community/posts?userId=...` |
| `addComment(postId, comment)` | `POST /api/community/posts/:id/comment` |
| `getBucketLists(page, pageSize)` | `GET /api/community/bucket-lists` |
| `createBucketList(title, desc?, maxParticipants, dates?)` | `POST /api/community/bucket-lists` |
| `getDilemmas(page, pageSize)` | `GET /api/community/dilemmas` |
| `voteDilemma(id, option)` | `POST /api/community/dilemmas/:id/vote` |
| `createContribution(...)` | `POST /api/community/contributions` (multipart — spot submission with photos) |

---

### `GamificationService`

Manages all XP, badge, and streak logic via atomic Firestore transactions.

| Method | Description |
|---|---|
| `award(userId, action, relatedId?)` | Full atomic transaction: calculates streak-multiplied XP, increments points, recalculates level, checks all 22 badge thresholds, adds bonus XP from new badges, writes XP event log. Returns `GamificationResult?` |
| `incrementCounter(userId, field)` | `FieldValue.increment(1)` for named stat counter fields |
| `recordDailyLogin(userId)` | Checks if today's login is already recorded. If not, calls `award(dailyLogin)`. Also checks and awards streak milestones (3-day, 7-day, 30-day) |
| `watchXpEvents(uid)` | `Stream<List<XpEvent>>` from `users/{uid}/xpEvents` subcollection |

---

### `AdminService`

Manages `app_admins` collection and admin operations.

| Method | Description |
|---|---|
| `checkSuperAdminClaim()` | Force-refreshes Firebase ID token, reads `superAdmin` custom claim boolean |
| `fetchAdminProfile(uid)` | One-shot fetch from `app_admins/{uid}` |
| `watchAdminProfile(uid)` | Live stream of admin document |
| `seedSuperAdmin()` | Creates/updates `app_admins/{uid}` on first super admin sign-in |
| `recordAdminLogin(uid)` | Updates `lastLogin` timestamp in admin doc |
| `logAdminActivity(action, collection, id?, detail?)` | Writes action log to `app_admins/{uid}/activityLog` |
| `watchRecentActivity(uid)` | Stream of recent admin activity log entries |
| `fetchCollectionCounts()` | Firestore `count()` aggregation queries for 10 collections |
| `watchAnalyticsSnapshot()` | Stream from `app_analytics/daily_snapshot` document |
| `watchAllUsers(limit)` | Stream of all user documents |
| `watchSpots()` | Stream of `spots` collection `QuerySnapshot` |
| `watchRestaurants()` | Stream of `restaurants` collection |
| `watchHotels()` | Stream of `hotels`/`accommodations` collection |
| `watchCafes()` | Stream of `cafes` collection |
| `watchHomestays()` | Stream of `homestays` collection |
| `watchAdventureSpots()` | Stream of `adventureSpots` collection |
| `watchShoppingAreas()` | Stream of `shoppingAreas` collection |
| `watchEvents()` | Stream of `events` collection |
| `watchVentures()` | Stream of `ventures` collection |
| `createListing(collection, data)` | `collection.add(data)` — creates a new document |
| `updateListing(collection, docId, data)` | `doc.update(data)` — updates existing document |
| `deleteListing(collection, docId)` | `doc.delete()` — removes document |

---

### `FirestoreSpotsService`

Direct Firestore access for tourist spots.

| Method | Description |
|---|---|
| `getFeaturedSpots(category?, limit)` | Queries `spots` with `status == 'approved'`, sorts featured first then by popularity desc |
| `watchFeaturedSpots(category?, limit)` | Live stream version of the above |
| `getSpotById(id)` | Single document fetch |
| `watchReviews(spotId, limit)` | Stream from `spots/{id}/reviews` subcollection |
| `submitReview(spotId, userId, userName, userAvatar, rating, comment)` | Writes review to subcollection, atomically updates `averageRating` and `ratingsCount` on parent doc, calls `FirestorePlaceRankingsService.updateRankingAfterReview()` and `GlobalReviewsService.recordReview()` |

---

### Per-Collection Listing Services

Each service exposes: `getXxx(limit?)`, `watchXxx()`, `getById(id)`, `submitReview(...)`

| Service | Firestore Collection |
|---|---|
| `FirestoreRestaurantsService` | `restaurants` |
| `FirestoreHotelsService` | `hotels` / `accommodations` |
| `FirestoreCafesService` | `cafes` |
| `FirestoreHomestaysService` | `homestays` |
| `FirestoreAdventureService` | `adventureSpots` |
| `FirestoreShoppingService` | `shoppingAreas` |
| `FirestoreEventsService` | `events` |

---

### `FirestoreDilemmasService`

| Method | Description |
|---|---|
| `watchDilemmas()` | Stream of all active dilemmas |
| `createDilemma(question, optionA, optionB, expiresAt?, authorId, authorName, authorPhoto?)` | Creates new dilemma document |
| `vote(id, option, uid)` | Atomic Firestore transaction updating `votesA` or `votesB` integer fields |

---

### `FirestoreBucketListService`

| Method | Description |
|---|---|
| `create(model)` | Writes new bucket list document |
| `getMyLists(userId)` | All bucket lists where user is host or member |
| `getPublicLists()` | All lists with `visibility == 'public'` |
| `getById(id)` | Single document fetch |
| `update(id, data)` | Partial update |
| `toggleItem(listId, itemIndex, newChecked, userId, userName)` | Updates item checked state with checker identity |
| `addMember(listId, member)` | Appends to members array |
| `removeMember(listId, userId)` | Removes member from array |
| `generateJoinCode()` | Returns random 6-character alphanumeric string |
| `getByJoinCode(code)` | Firestore query on `joinCode` field |
| `delete(id)` | Deletes the bucket list document |

---

### `FirestoreLeaderboardService`

`watchAll(limit=200)` — Stream from `place_leaderboard` collection sorted by `avgRating` desc.

### `FirestorePlaceRankingsService`

`updateRankingAfterReview(category, placeId, placeName, heroImage, newRating, newRatingsCount)` — Upserts document in `place_rankings` collection.

### `GlobalReviewsService`

`recordReview(placeId, placeName, category, heroImage, userId, userName, userAvatar, rating, comment)` — Writes to `global_reviews` collection and calls `_updateLeaderboard()` which upserts `place_leaderboard/{category}_{placeId}`.

### `TourVentureService`

| Method | Description |
|---|---|
| `watchFeatured(limit)` | Stream of featured ventures |
| `watchByCategory(category?)` | Stream filtered by `PackageCategory` |
| `watchBySeason(season)` | Stream filtered by season |
| `fetchById(id)` | One-shot venture document fetch |

### `EventService`

| Method | Description |
|---|---|
| `getEvents(limit, upcomingOnly)` | Fetches events from Firestore with optional upcoming filter |
| `getEventsForMonth(year, month)` | Date range query for calendar month view |
| `eventDetailProvider` | `FutureProvider.family` for single event |

### `SpotsService`

REST API service for `/api/spots` — paginated list, search, featured, bookmarks.

### `ListingsService`

REST API service for `/api/listings`.

### `CsvUploadService`

Admin-only service. Picks a CSV file via `file_picker`, parses rows using the `csv` package, previews data in a bottom sheet, then batch-writes all rows to a specified Firestore collection.

---

## 9. State Management — Controllers & Providers

### `AuthController` (`AsyncNotifier<AuthState>`)

| Method / Provider | Description |
|---|---|
| `authControllerProvider` | Main auth controller provider |
| `currentUserProvider` | `Provider<UserModel?>` shortcut |
| `isAuthenticatedProvider` | `Provider<bool>` |
| `firebaseAuthStreamProvider` | `StreamProvider<User?>` |
| `signIn(email, pw)` | Returns `SignInResult` with either error string or redirect route (`/admin` for super admin, `/` for user) |
| `register(email, pw, displayName)` | Returns `null` on success or error string |
| `signOut()` | Clears auth state |
| `sendPasswordReset(email)` | Returns `null` or error string |
| `updateProfile(...)` | Updates Firestore + Firebase Auth, refreshes state |
| `refreshProfile()` | Force reloads from Firestore |

---

### `SpotsController` & `SearchController`

| Provider | Description |
|---|---|
| `featuredSpotsProvider` | `AsyncNotifierProvider` — loads 8 featured spots via REST API |
| `featuredSpotsByCategoryProvider` | `FutureProvider.family<List<SpotModel>, String?>` — filtered by category |
| `featuredSpotsByCategoryStreamProvider` | `StreamProvider.family` — live Firestore updates |
| `allSpotsByCategoryStreamProvider` | `StreamProvider.family` — up to 100 spots |
| `spotDetailProvider` | `FutureProvider.family<SpotModel?, String>` — single spot |
| `SpotsController` | Paginated list with `loadMore()`, `setCategory()`, `refresh()` |
| `searchControllerProvider` | `NotifierProvider<SearchController, SearchState>` — debounced REST API search (min 2 chars) |

---

### `ListingsController`

Generic `PaginatedState<T>` for each of 8 listing types. Each loads up to 100 records from Firestore.

| Provider | Type |
|---|---|
| `touristSpotsProvider` | `TouristSpotsNotifier` |
| `restaurantsProvider` | `RestaurantsNotifier` |
| `hotelsProvider` | `HotelsNotifier` |
| `cafesProvider` | `CafesNotifier` |
| `homestaysProvider` | `HomestaysNotifier` |
| `adventureSpotsProvider` | `AdventureSpotsNotifier` |
| `shoppingAreasProvider` | `ShoppingAreasNotifier` |
| `eventsListingProvider` | `EventsNotifier` |

---

### `EventController` (`Notifier<EventState>`)

| Method / Property | Description |
|---|---|
| `loadAll()` | All events (past + upcoming) |
| `loadUpcoming()` | Upcoming events only |
| `loadMonth(year, month)` | Firestore date range query |
| `upcoming` | Derived list of events with future dates |
| `past` | Derived list of events with past dates |
| `featured` | Featured events |
| `eventsForDay(day)` | Events on a specific calendar day |
| `eventDays` | `Set<DateTime>` for calendar "has events" indicators |
| `byMonth` | `Map<String, List<EventModel>>` grouped by month |
| `byType` / `byCategory` | Grouped derived maps |

---

### `CommunityController` (3 controllers)

| Controller / Provider | Description |
|---|---|
| `PostsController` | Paginated community posts with optimistic like toggle, create, delete, update |
| `bucketListsProvider` | `FutureProvider` via REST API (legacy bucket list data) |
| `DilemmasController` | Mirrors Firestore dilemma stream; optimistic vote toggle; `createDilemma(...)` |
| `dilemmasStreamProvider` | `StreamProvider<List<Dilemma>>` — raw Firestore stream |
| `leaderboardStreamProvider` | `StreamProvider<List<PlaceLeaderboardEntry>>` from `FirestoreLeaderboardService` |

---

### `GamificationController` (`Notifier<void>`)

Stateless controller that proxies calls to `GamificationService` and broadcasts results.

| Method / Provider | Description |
|---|---|
| `award(action, relatedId?)` | Calls `GamificationService.award()`, pushes to `_rewardStreamController`, refreshes user profile |
| `recordDailyLogin()` | Checks and awards daily login XP |
| `incrementCounter(field)` | Increments a named stat counter on the user doc |
| `gamificationRewardStreamProvider` | Broadcast `StreamProvider<GamificationResult>` consumed by `XpToastOverlay` |
| `xpEventsProvider` | `StreamProvider<List<XpEvent>>` for profile Activity tab |

---

### `AdminController`

| Provider | Description |
|---|---|
| `isSuperAdminProvider` | `FutureProvider<bool>` — force-refreshes token, checks custom claim |
| `adminProfileProvider` | `StreamProvider<AdminModel?>` from `app_admins` collection |
| `collectionCountsProvider` | Firestore aggregation count queries for all collections |
| `analyticsSnapshotProvider` | `StreamProvider<AppAnalyticsSnapshot>` |
| `adminUsersProvider` | Stream of all user documents |
| `adminSpotsProvider` (etc.) | Per-collection `QuerySnapshot` streams for each listing type |
| `selectedListingTabProvider` | `StateProvider<int>` for active admin listings tab |
| `AdminListingNotifier` | CRUD state machine: `createListing`, `updateListing`, `deleteListing` with `loading / success / error` states |

---

### `BucketListController` (`Notifier<BucketListState>`)

| Method | Description |
|---|---|
| `loadMyLists(userId)` | Loads user's bucket lists from Firestore |
| `loadPublicLists()` | Loads all public bucket lists |
| `create(...)` | Creates bucket list, auto-generates 6-char join code, adds host as first member, awards `createBucketList` (+20 XP), increments `bucketListsCreated` |
| `addItem(listId, item)` | Adds new item to bucket list |
| `toggleItem(listId, itemIndex, newChecked, userId, userName)` | Checks/unchecks item; awards `completeBucketItem` (+10 XP) on check; increments `bucketItemsCompleted` |
| `update(listId, data)` / `delete(listId)` | Update/delete bucket list |
| `joinByCode(code, member)` | Joins via 6-char code; adds member with `pending` status |
| `approveMember(listId, userId)` | Host approves pending member request |
| `declineMember(listId, userId)` | Host declines pending member request |
| `leaveBucket(listId, userId)` | Member leaves a bucket list |

---

### `TourVentureController`

| Provider | Description |
|---|---|
| `featuredVenturesProvider` | Firestore stream — available ventures only, sorted by date |
| `ventureByIdProvider` | Stream for single venture document |
| `featuredPackagesStreamProvider` | Typed `List<TourVentureModel>` stream |
| `packagesByCategoryStreamProvider` | Category-filtered stream |
| `packagesBySeasonStreamProvider` | Season-filtered stream |
| `packageDetailProvider` | `FutureProvider.family` |
| `PackageFilterNotifier` | Filter state: category, season, difficulty, searchQuery |
| `filteredPackagesProvider` | Derived stream applying all active client-side filters |

---

## 10. Features & Screens

### 10.1 Onboarding

**Screen:** `OnboardingScreen` · **Route:** `/onboarding`

A 3-page animated carousel shown on first app launch.

| Page | Title | Description |
|---|---|---|
| 1 | 🗺️ Discover Mizoram | Waterfalls, viewpoints, and cultural spots |
| 2 | ✨ Earn XP & Badges | Levels, badges, and leaderboard |
| 3 | 🤝 Join the Community | Bucket lists, dilemmas, and posts |

- Skip and Next buttons on every page
- Page indicator dots with animated active state
- On completion: writes `onboarding_done = true` to `SharedPreferences` → navigates to `/login`
- Shown only once; future launches skip directly to home or login

---

### 10.2 Authentication

#### `LoginScreen` · `/login`
- Email and password form
- "Sign In" button → calls `authController.signIn()`
- Redirect: `/admin` for super admin, `/` for regular users
- Displays error messages from auth controller
- Links to: Register screen, Forgot Password screen

#### `RegisterScreen` · `/register`
- Fields: Display Name, Email, Password, Confirm Password
- Real-time confirm password match validation
- Calls `authController.register(email, pw, displayName)`
- On success: redirects to home

#### `ForgotPasswordScreen` · `/forgot-password`
- Email input
- Calls `authController.sendPasswordReset(email)`
- Shows success alert with instructions to check email

---

### 10.3 Home Screen

**Screen:** `HomeScreen` · **Route:** `/`

| Section | Description |
|---|---|
| SliverAppBar | xplooria logo + notifications icon |
| Greeting | Personalised "Hello, [FirstName] 👋" with XP chip (when authenticated) |
| Headline | "Discover Mizoram" tagline (when unauthenticated) |
| Search bar | Non-functional input bar — tap navigates to `/search` |
| Category pills | Horizontal scroll of 12 category chips; tapping navigates to `/listings?tab=N` |
| Featured Spots | Horizontal card list from `featuredSpotsByCategoryStreamProvider`; "See All" → listings |
| Dare & Venture | Horizontal package cards from `featuredPackagesStreamProvider`; "See All" → `/packages` |
| State picker | "Discover Northeast India" tappable label (placeholder for future multi-state expansion) |

**12 Category Pills:**
All · Waterfall · Mountain · Restaurant · Café · Hotel · Cultural Site · Adventure · Viewpoint · Park · Shopping · Religious

---

### 10.4 Explore / Listings Hub

**Screen:** `ListingsScreen` · **Route:** `/listings` · **`?tab=N`** selects the initial tab

A tabbed scroll view with 8 content tabs wrapped in a `SliverAppBar` that shows an animated **"Explore [GPS District]"** title that updates as the app detects the user's nearest Mizoram district.

| Tab | Label | Data Source | Card Features |
|---|---|---|---|
| 0 | 🗺️ Tourist Spots | `touristSpotsProvider` (Firestore) | SpotCard: image, name, category, rating, district |
| 1 | 🍽️ Restaurants | `restaurantsProvider` (Firestore) | Cuisine types, price range (\$–\$\$\$\$), delivery/reservation badges |
| 2 | 🏨 Hotels | `hotelsProvider` (Firestore) | Star rating, amenity icons (WiFi, parking, pool) |
| 3 | ☕ Cafes | `cafesProvider` (Firestore) | Specialties, outdoor seating, WiFi badge |
| 4 | 🏡 Homestays | `homestaysProvider` (Firestore) | Price range, amenities |
| 5 | 🧗 Adventure | `adventureSpotsProvider` (Firestore) | Difficulty badge, activity types |
| 6 | 🛍️ Shopping | `shoppingAreasProvider` (Firestore) | Shop types, opening hours |
| 7 | 📅 Events | `eventsListingProvider` (Firestore) | Date badge, event type, ticketing indicator |

- Search icon in app bar → `/search`
- Category-filtered navigation from Home screen opens the appropriate tab

---

### 10.5 Place Detail Screens

#### `SpotDetailScreen` · `/spots/:id`

| Section | Details |
|---|---|
| Image Carousel | Swipeable `PageView` with page indicator dots and `Hero` animation |
| Bookmark button | Requires auth; toggles spot ID in user's `bookmarks` array |
| Header | Spot name, district badge, category chip, avg rating, view count |
| Tags | Horizontal scrollable tag row |
| Place Story | Long-form description text |
| Things To Do | Bulleted activity list |
| Entry Fees | Type + amount pairs |
| Practical Info | Best season, opening hours, facilities, accessibility, safety notes |
| Map | `flutter_map` tile view centred on lat/lng (if available) |
| Reviews | Star distribution summary + individual review cards with user avatar and timestamp |
| "See All Reviews" | Link → `/reviews/spots/:id` |
| Alternate Names | Other localised names |
| Official Source | External URL via `url_launcher` |

#### `RestaurantDetailScreen`
Name, image gallery, location, cuisine types, price range, opening hours, delivery/reservation badges, contact phone, website, full reviews section.

#### `HotelDetailScreen`
Name, image gallery, star rating, price range, amenities grid (icons), room types, facility badges (restaurant/WiFi/parking/pool), contact, website, full reviews section.

#### `CafeDetailScreen`
Name, image gallery, rating, specialties list, opening hours, WiFi/outdoor seating badges, contact, full reviews section.

#### `ListingDetailScreen`
Generic fallback detail screen for listing types without dedicated screens.

#### `EventDetailScreen` · `/events/:id`
Hero image, status bar (upcoming/ongoing/past), event type badge, date/time, venue location, attendee count, full description, tags row, ticketing section (price, seats remaining / sold out indicator, "Book Now" CTA), organizer info.

#### `AllReviewsScreen` · `/reviews/:collection/:id`
Paginated full review list for any listing type. Shows:
- Summary statistics: average rating, total count, star distribution bar chart
- Individual review cards: user avatar, display name, star rating, comment text, relative timestamp

---

### 10.6 Search

**Screen:** `SearchScreen` · **Route:** `/search`

- Auto-focused `TextField` with clear button
- Calls `SearchController.search(query)` with 300ms debounce on text change
- Minimum 2 characters to trigger search
- Searches against REST API (`GET /api/spots/search`)
- Results displayed as a 2-column `SpotCard` grid
- States: empty hint → loading shimmer → "No results" empty state → results grid

---

### 10.7 Community

**Screen:** `CommunityScreen` · **Route:** `/community`

Three-tab community hub:

#### Tab 0: Community Map

An interactive **OpenStreetMap** (via `flutter_map`) showing pins for known spots across Mizoram. Tapping a pin opens a `PlaceDetailSheet` bottom sheet containing:
- Full place name, category, location
- Star rating form for submitting a review (awards +15 XP via `gamificationController`)
- Photo upload option (awards +10 XP via `gamificationController`)
- Triggers `incrementCounter('ratingsCount')` and `incrementCounter('photosCount')` on the user doc

#### Tab 1: Bucket Lists

Displays two sections: **My Lists** and **Public Lists**.

Each bucket list card shows:
- Banner image, title, category chip
- Completion progress bar (visited items / total items)
- Member count
- Host display name

**FAB actions:**
- ➕ Create new bucket list → `/community/bucket-lists/new`
- 🔗 Join by code → shows 6-character join code dialog

**`CreateBucketListScreen`** (`/community/bucket-lists/new`):
- Title, description, banner image upload (Firebase Storage)
- Category dropdown, visibility picker, max members
- XP reward amount, optional challenge title

**`BucketListDetailScreen`** (`/community/bucket-lists/:id`):
- Full item list with checked/unchecked state
- Check item → awards +10 XP and updates `bucketItemsCompleted`
- Members tab: member list with host/member roles
- Join requests (host sees approve/decline controls)
- Leave list option (non-host members)

**`AddBucketItemScreen`** (`/community/bucket-lists/:listId/add-item`):
- Item name, category, optional listing ID, notes

**`EditBucketListScreen`** (`/community/bucket-lists/:id/edit`):
- Edit title, description, visibility, max members

#### Tab 2: Dilemmas

Horizontal scrollable list of "Which do you prefer?" polls.

Each dilemma card shows:
- Poll question text
- Two place options with images and names
- Vote buttons that show percentage bars after voting
- Total vote count, expiry (if set)
- "This or That?" visual design

**Voting:** Optimistic UI update → `DilemmasController.vote()` → awards +5 XP.

**`CreateDilemmaScreen`** (pushed from FAB when on this tab via community):
- Question text input
- Option A and B with spot/listing picker
- Optional expiry date picker

---

### 10.8 Leaderboard

**Screen:** `LeaderboardScreen` · **Route:** `/leaderboard`

**Note:** This is a *place quality* leaderboard, not a user XP ranking. Data source: `place_leaderboard` Firestore collection, sorted by `avgRating` descending.

Displays top-3 per category in a visually styled podium:

| Category | Icon |
|---|---|
| Top Spots (tourist) | 🏔️ |
| Top Cafés | ☕ |
| Top Restaurants | 🍽️ |
| Top Hotels | 🏨 |
| Top Homestays | 🏡 |

Each category section shows:
- Animated podium reveal
- Rank positions with medal colours: Gold (#1), Silver (#2), Bronze (#3)
- Hero image, place name, average star rating, review count

---

### 10.9 Profile

**Screen:** `ProfileScreen` · **Route:** `/profile`

#### Unauthenticated View
Prompt card with "Sign In" button → `/login`

#### Authenticated View

`NestedScrollView` with expanding `SliverAppBar` (expanded height 320):

**Header section:**
- Circular profile photo (tap to edit via `image_picker`)
- Display name, level title, location
- `XpProgressBar` — gradient bar showing current level XP progress
- Key stats row: contributions, ratings, photos, dilemmas, bucket items, login streak

**Action buttons:**
- Theme toggle (dark/light mode)
- Admin Panel button (visible only to `isSuperAdminEmail` users) → `/admin`
- Sign Out

**4 Profile Tabs:**

| Tab | Contents |
|---|---|
| Stats | Points, level, login streak, longest streak, contributions, ratings, photos count cards |
| Badges | Grid of all 22 badges — earned badges highlighted with rarity colour, locked badges greyed out |
| Saved | Bookmarked spots loaded from `bookmarksProvider(userId)` — `SpotCard` grid |
| Activity | XP history stream (`xpEventsProvider`) — chronological list of `XpEvent` items with action label, XP amount, relative timestamp |

#### `EditProfileScreen` · `/profile/edit`
- Display name, bio, location text fields
- Avatar image picker with `image_picker` + Firebase Storage upload
- Saves to Firestore via `authController.updateProfile()`

---

### 10.10 Contribute

**Screen:** `ContributeScreen` · **Route:** `/contribute` (auth-protected)

Multi-step spot submission form using an animated `PageView` with 4 steps:

| Step | Fields |
|---|---|
| 1. Details | Name (required), Category dropdown (12 options), Description (min 20 characters) |
| 2. Location | City/district (required), Full address, Latitude (optional), Longitude (optional) |
| 3. Photos | Up to 5 images via `image_picker.pickMultiImage()` — shows thumbnails with remove option |
| 4. Submit | Summary review card + "Submit Contribution" button |

On submit:
- Calls `communityService.createContribution(...)` as multipart form data
- Shows success dialog: *"Your contribution has been submitted! Earn 10 XP when your spot is approved."*
- Admin reviews in Moderation screen; approval triggers XP award

---

### 10.11 Dare & Venture (Tour Packages)

**Screen:** `TourPackagesScreen` · **Route:** `/packages`

**Branding:** `⚡ Dare & Venture` with "Exclusive" gradient badge

**Filtering system (3 layers):**

| Filter | Options |
|---|---|
| Search | Client-side text filter on title and tagline |
| Category chips | 16 categories: Bird Watching, Fishing, Hiking, Sunrise, Eco Tourism, Trekking, Camping, Photography, Cultural, Wildlife Safari, Rafting, Cycling, Running, Wellness, Stargazing, Other |
| Season row | All Year / Spring / Summer / Autumn / Winter / Monsoon |
| Difficulty | Easy / Moderate / Challenging / Extreme |

**Package card shows:** Hero image, title, tagline, category emoji, difficulty badge, season badge, duration, group size, base price, rating, "Book Now" CTA.

Powered by `PackageFilterNotifier` + `filteredPackagesProvider`.

#### `VentureDetailScreen` · `/packages/:id`

For typed `TourVentureModel` packages:

| Section | Details |
|---|---|
| Hero gallery | Swipeable image carousel |
| Header | Title, organizer, location, difficulty badge, season, duration, group size min/max |
| Description | Full activity description |
| Pricing tiers | Cards showing price per person, min/max group size, included/excluded items, popular badge |
| Addons | Optional extras with emoji, price per unit |
| Challenges | Special activity challenges within the package |
| Achievement medals | Medal tier, unlock condition, reward description |
| CTA | "Book / Register" button (booking transaction: Phase 2) |

#### `VenturePublicDetailScreen` · `/ventures/:id`

Raw Firestore map version used for ventures created via the admin form. Dynamically renders all available fields from the `ventures` document.

---

### 10.12 Admin Panel

**Shell:** `AdminShell` · **Route prefix:** `/admin`

Accessible only to users with `superAdmin: true` Firebase custom claim (`hillstechadmin@xplooria.com`).

#### `AdminDashboardScreen` · `/admin`

- Collection counts grid (8 listing types + users + packages) via `collectionCountsProvider`
- "Listing Categories" overview cards with type icons
- Admin profile info card (role badge, permissions list)
- Refresh button to re-fetch counts

---

#### `AdminListingsScreen` · `/admin/listings`

Tabbed interface with 8 tabs mirroring the public Explore screen.

For each tab:
- Live `QuerySnapshot` stream of that collection
- Each row shows: document ID, name field, status indicator, edit/delete actions
- **Add** button → `AdminAddListingScreen`
- **CSV Upload** button → `CsvUploadSheet` bottom sheet
- **Edit** icon → pre-fills `AdminAddListingScreen` form with existing data
- **Delete** icon → confirmation dialog before `adminService.deleteListing()`

**`AdminAddListingScreen`** · `/admin/listings/add/:collection` and `/admin/listings/edit/:collection/:docId`

Dynamic form that adapts its fields based on the `collection` parameter:
- Text fields for name, description, location, etc.
- Image URL arrays (comma-separated or line-separated input)
- Boolean toggles for amenity flags (hasWifi, hasParking, etc.)
| Cuisine/specialty array fields
- Dropdown selectors for category, status, type

**`CsvUploadSheet`** (bottom sheet):
1. `file_picker` to select a `.csv` file from device
2. Parse with `csv` package
3. Preview table of first N rows
4. "Import All" button → batch-writes to specified Firestore collection

---

#### `AdminUsersScreen` · `/admin/users`

- Live stream of all user documents (`adminUsersProvider`)
- User list cards: avatar, display name, email, level badge, XP points
- Search/filter by name or email
- Tap user → detail view showing all stats (streak, contributions, ratings, badges, created at)

---

#### `AdminAnalyticsScreen` · `/admin/analytics`

Real-time `AppAnalyticsSnapshot` stream showing:

| Metric | Description |
|---|---|
| Total Users | All registered users count |
| New Users Today | Users registered today |
| New Users This Week | Users registered in the last 7 days |
| Total Spots | Count from `spots` collection |
| Total Listings | Sum of all listing collection counts |
| Total Events | Count from `events` collection |
| Total Ventures | Count from `ventures` collection |
| Total Community Posts | Count from community posts |
| Total Reviews | Cross-collection review count |
| Booking Requests | Total / Pending breakdown |
| Total XP Awarded | Aggregate XP across all users |

Visual `fl_chart` bar charts for user registration trends.

---

#### `AdminVenturesScreen` · `/admin/ventures`

- Live stream of `ventures` collection
- Card list with title, category, price, availability status, featured toggle
- Add → `AdminVentureFormScreen`
- Edit → pre-filled `AdminVentureFormScreen`
- Delete → confirmation dialog

**`AdminVentureFormScreen`** · `/admin/ventures/add` and `/admin/ventures/edit/:docId`

Comprehensive form matching all `TourVentureModel` fields:
- Basic info (title, tagline, description, category, difficulty, season, duration, group size)
- Location and district
- Images (URL array)
- Pricing tiers (dynamic list — add/remove tiers with included/excluded items)
- Addons (dynamic list with emoji picker)
- Challenges (dynamic list)
- Achievement medals (tier, name, condition)
- Availability toggle, featured toggle

---

#### `AdminModerationScreen` · `/admin/moderation`

- Lists pending community-submitted spot contributions
- Shows: submission title, category, submitted by, submitted date, photos preview
- Approve → sets status to `'Approved'` on the contribution, triggers contributor XP award
- Reject → sets status to `'Rejected'` with optional rejection reason

---

#### `AdminSettingsScreen`

- Theme toggle (dark/light for the admin session)
- Admin account info display (email, role, last login)
- Sign Out button

---

## 11. Gamification System

### Overview

Every interactive action in the app triggers the `GamificationService.award()` method which runs an atomic Firestore transaction, calculates XP (with streak multiplier), updates the user document, checks badge thresholds, and returns a `GamificationResult`.

---

### XP Actions & Values

| Action | Base XP | Where Triggered |
|---|---|---|
| Write a review | +15 | `PlaceDetailSheet` → submit review |
| Upload a photo | +10 | `PlaceDetailSheet` → upload community photo |
| Create a bucket list | +20 | `BucketListController.create()` |
| Complete a bucket item | +10 | `BucketListController.toggleItem()` (check = true) |
| Create a dilemma | +25 | `DilemmasController.createDilemma()` |
| Vote on a dilemma | +5 | `DilemmasController.vote()` |
| Daily login | +5 | `MainShell.initState()` — once per calendar day |
| Streak bonus (3+ days) | +10 | Auto-triggered inside `recordDailyLogin()` |
| Weekly streak (day 7) | +30 | Auto-triggered inside `recordDailyLogin()` |
| Monthly streak (day 30) | +100 | Auto-triggered inside `recordDailyLogin()` |

---

### Streak Multiplier

Applied to all XP actions **except** streak milestone bonuses themselves:

$$\text{multiplier} = \text{clamp}\left(1.0 + \left\lfloor\frac{\text{streak}}{5}\right\rfloor \times 0.10,\; 1.0,\; 2.0\right)$$

- Day 1–4: ×1.0 (no bonus)
- Day 5–9: ×1.1
- Day 10–14: ×1.2
- ...
- Day 50+: ×2.0 (maximum)

---

### Level Thresholds

| Level | Min XP | Title |
|---|---|---|
| 1 | 0 | Explorer |
| 2 | 100 | Wanderer |
| 3 | 250 | Adventurer |
| 4 | 500 | Pathfinder |
| 5 | 1,000 | Guide |
| 6 | 2,000 | Expert |
| 7 | 3,500 | Master |
| 8 | 5,500 | Legend |
| 9 | 8,500 | Champion |
| 10 | 12,500 | Guardian |

---

### Badge System — All 22 Badges

#### Exploration Badges

| Badge ID | Name | Rarity | Condition | Bonus XP |
|---|---|---|---|---|
| `first_review` | First Review | ⚪ Common | `ratingsCount ≥ 1` | +10 |
| `ten_reviews` | Regular Reviewer | 🔵 Rare | `ratingsCount ≥ 10` | +25 |
| `fifty_reviews` | Review Master | 🟣 Epic | `ratingsCount ≥ 50` | +75 |
| `first_contribution` | First Contributor | ⚪ Common | `contributionsCount ≥ 1` | +10 |
| `ten_contributions` | Active Explorer | 🟣 Epic | `contributionsCount ≥ 10` | +50 |
| `twenty_five_contributions` | Mizoram Guide | 🔵 Rare | `contributionsCount ≥ 25` | +40 |

#### Photography Badges

| Badge ID | Name | Rarity | Condition | Bonus XP |
|---|---|---|---|---|
| `first_photo` | Shutterbug | ⚪ Common | `photosCount ≥ 1` | +10 |
| `photo_master` | Photo Master | 🟣 Epic | `photosCount ≥ 10` | +50 |

#### Streak Badges

| Badge ID | Name | Rarity | Condition | Bonus XP |
|---|---|---|---|---|
| `streak_3` | On a Roll 🔥 | ⚪ Common | `loginStreak ≥ 3` | +15 |
| `streak_7` | Week Warrior | 🔵 Rare | `loginStreak ≥ 7` | +40 |
| `streak_30` | Unstoppable 💎 | 🟡 Legendary | `loginStreak ≥ 30` | +150 |

#### Dilemma Badges

| Badge ID | Name | Rarity | Condition | Bonus XP |
|---|---|---|---|---|
| `first_dilemma` | Question Master | ⚪ Common | `dilemmasCreated ≥ 1` | +10 |
| `dilemma_voter` | Decision Maker | 🔵 Rare | `dilemmasVoted ≥ 10` | +30 |

#### Bucket List Badges

| Badge ID | Name | Rarity | Condition | Bonus XP |
|---|---|---|---|---|
| `bucket_complete_1` | Bucket Starter ✅ | ⚪ Common | `bucketItemsCompleted ≥ 1` | +15 |
| `bucket_complete_10` | Bucket Champion 🏁 | 🔵 Rare | `bucketItemsCompleted ≥ 10` | +50 |

#### Special / Level Badges

| Badge ID | Name | Rarity | Condition | Bonus XP |
|---|---|---|---|---|
| `early_adopter` | Early Adopter 🚀 | 🟡 Legendary | `level ≥ 2` (first 100 users) | +100 |
| `level_5` | Rising Star | ⚪ Common | `level ≥ 5` | +20 |
| `level_10` | Guardian | 🟡 Legendary | `level ≥ 10` | +200 |
| `top_10` | Top Explorer | 🔵 Rare | `rank ≤ 10` on leaderboard | +50 |
| `bookworm` | Well-Travelled | ⚪ Common | `bookmarks.length ≥ 10` | +15 |
| `social_butterfly` | Community Pillar | 🔵 Rare | Various community actions | +30 |

---

### Gamification Transaction Flow

```
GamificationController.award(action, relatedId?)
  │
  ▼
GamificationService.award()
  ├─ Firestore.runTransaction()
  │   ├─ 1. Read users/{uid}
  │   ├─ 2. Calculate new streak from lastLogin vs today
  │   ├─ 3. Compute XP multiplier from streak
  │   ├─ 4. Multiply action.baseXp by multiplier
  │   ├─ 5. new points = old points + XP
  │   ├─ 6. Recalculate level via UserModel.calculateLevel()
  │   ├─ 7. BadgeModel.evaluate() → compare all 22 badge thresholds
  │   ├─ 8. Sum bonus XP from newly unlocked badges
  │   ├─ 9. Atomic tx.update on users/{uid} (points, level, levelTitle, badges, streak)
  │   └─ 10. tx.set new XpEvent in users/{uid}/xpEvents
  │
  ▼
Returns GamificationResult
  │
  ├─ GamificationController pushes to _rewardStreamController (broadcast stream)
  ├─ GamificationController calls authController.refreshProfile()
  │
  ▼
XpToastOverlay (wraps MainShell child)
  ├─ Listens to gamificationRewardStreamProvider
  ├─ Shows animated XP toast popup ("+15 XP")
  └─ Shows confetti + level-up dialog if leveledUp == true
```

---

## 12. Firebase Collections & Data Structure

| Collection | Purpose | Key Fields |
|---|---|---|
| `users` | All user profiles with XP, stats, bookmarks | id, email, points, level, badges, streak, all counters |
| `users/{uid}/xpEvents` | XP event audit log per user | action, xpEarned, createdAt, relatedId |
| `spots` | Tourist spot listings | name, category, district, featured, status, averageRating, lat/lng |
| `spots/{id}/reviews` | Reviews per spot | userId, userName, rating, comment, timestamp |
| `restaurants` | Restaurant listings | name, cuisineTypes, priceRange, rating |
| `hotels` / `accommodations` | Hotel and accommodation listings | name, amenities, roomTypes, rating |
| `cafes` | Café listings | name, specialties, rating |
| `homestays` | Homestay listings | name, amenities, rating |
| `adventureSpots` | Adventure activity listings | name, difficulty, activities |
| `shoppingAreas` | Shopping area listings | name, shopTypes |
| `events` | Events with ticketing metadata | title, type, date, ticketingEnabled |
| `ventures` | Dare & Venture tour packages | title, category, difficulty, pricingTiers |
| `tour_packages` | Legacy collection (referenced in admin counts) | — |
| `dilemmas` | Community dilemma polls | question, optionA, optionB, votesA, votesB |
| `bucket_lists` | User bucket lists (full version) | title, items, members, joinCode, visibility |
| `place_leaderboard` | Place rankings by avg rating | category, placeId, avgRating, ratingCount |
| `place_rankings` | Ranking entries per listing | category, placeId, placeName, avg |
| `global_reviews` | Cross-collection review log | placeId, category, userId, rating, comment |
| `app_admins` | Super admin account documents | uid, role, permissions, isActive |
| `app_admins/{uid}/activityLog` | Admin action audit trail | action, collection, timestamp, detail |
| `app_analytics/daily_snapshot` | Aggregate app statistics document | totalUsers, totalSpots, totalListings, etc. |

### Firestore Security Rules

- `users/{userId}`: Read by authenticated users, write only by document owner
- `spots`, `restaurants`, etc.: Read by all (public), write only by super admin
- `app_admins`: Read/write only by super admin claim
- `dilemmas`, `bucket_lists`: Read by authenticated, write by owner
- Reviews subcollections: Write by authenticated user with valid UID

---

## 13. API Integration

### Base URL

Configured via `--dart-define=API_BASE_URL=...` at build time.  
Default: `http://10.0.2.2:3000` (Android emulator localhost).

### Authentication

All API requests automatically include:
```
Authorization: Bearer <Firebase ID Token>
```
On 401 response: automatically refreshes the Firebase ID token and retries the request once.

### REST Endpoints Used

| Method | Endpoint | Feature |
|---|---|---|
| `GET` | `/api/spots` | Paginated spot list with category filter |
| `GET` | `/api/spots/search` | Text search for spots |
| `GET` | `/api/spots/featured` | Featured spots for home screen |
| `GET` | `/api/listings` | Listing data |
| `GET` | `/api/community/posts` | Community feed posts |
| `POST` | `/api/community/posts` | Create new post |
| `PUT` | `/api/community/posts/:id` | Update post |
| `DELETE` | `/api/community/posts/:id` | Delete post |
| `POST` | `/api/community/posts/:id/like` | Toggle post like |
| `POST` | `/api/community/posts/:id/comment` | Add comment |
| `GET` | `/api/community/bucket-lists` | Browse bucket lists (legacy) |
| `POST` | `/api/community/bucket-lists` | Create bucket list (legacy) |
| `GET` | `/api/community/dilemmas` | Fetch dilemmas (legacy) |
| `POST` | `/api/community/dilemmas/:id/vote` | Vote on dilemma (legacy) |
| `POST` | `/api/community/contributions` | Submit new spot (multipart with photos) |
| `GET` | `/api/auth/me` | Current user info |

**Note:** Direct Firestore reads are the primary data path for most features. The REST API is used for community posts, search, and spot contributions. The app is migrating toward full Firestore direct access.

---

## 14. District Detection

**Provider:** `DistrictNotifier` (`districtNotifierProvider`) in `lib/core/providers/district_provider.dart`

### Supported Mizoram Districts (11)

Aizawl · Champhai · Hnahthial · Khawzawl · Kolasib · Lawngtlai · Lunglei · Mamit · Saiha · Saitual · Serchhip

### Detection Flow

1. App init triggers `DistrictNotifier.init()`
2. Requests `Geolocator` permission and GPS position
3. Applies Haversine distance formula against 11 district capital coordinates
4. Sets `DistrictState.district` to the nearest district name
5. Used by `ListingsScreen` to show animated **"Explore [District]"** title

### `districtNotifierProvider` State

```dart
class DistrictState {
  final String? district;   // Detected district name
  final bool loading;       // Permission/GPS pending
  final String? error;      // Permission denied or GPS unavailable
}
```

---

## 15. Widgets Library

### `gamification_widgets.dart`

| Widget | Description |
|---|---|
| `XpProgressBar` | Animated gradient linear progress bar. Shows: Level N label, current XP / max XP, percentage. Uses `LinearPercentIndicator` with primary colour gradient. |
| `LevelBadge` | Circular level number badge. Colour tiered: L1–3 green, L4–6 primary, L7–9 secondary/indigo, L10 gold. |
| `BadgeChip` | Inline pill chip in the badge's rarity colour with badge icon and name. Locked state shows grey with padlock icon. |
| `XpToastOverlay` | App-level overlay that wraps `MainShell`. Listens to `gamificationRewardStreamProvider`. On any reward: animates a "+N XP" toast from the top. On level-up: triggers confetti animation and shows an "🎉 Level Up!" dialog with new level title. |

### `shared_widgets.dart`

| Widget | Description |
|---|---|
| `PointsChip` | Gold `⚡ N XP` chip shown in the home screen app bar |
| `StarRating` | Row of stars rendering a double rating to 1 decimal place |
| `ShimmerBox` | `shimmer`-animated placeholder rectangle, matches card dimensions |
| `CategoryChip` | Emoji + text pill chip with selected (filled, primary colour) and unselected (outlined) states |
| `EmptyState` | Centred column: large emoji, bold title, subtitle. Used for all empty/error state screens. |
| `SpotCard` | Standard portrait card: `CachedNetworkImage`, spot name, category chip, star rating, district label. `Hero` tag on image. |
| `FeaturedSpotCard` | Wider landscape card variant for the Home screen featured row. Gradient overlaid text. |
| `CompactSpotCard` | Small thumbnail card for dense lists. |

### `spot_cards.dart`

Additional spot card variants used throughout the listing screens with specialized layouts.

---

## 16. Key Architectural Patterns

### Dual Data Sources

Some features have both a REST API service (`SpotsService`, `CommunityService`) and a direct Firestore service (`FirestoreSpotsService`). The app is actively migrating toward direct Firestore access for lower latency.

- **REST API**: Community posts, search, spot contributions
- **Direct Firestore**: All listing collections, events, ventures, user profiles, admin data, dilemmas, bucket lists, leaderboard

### Optimistic Updates

The following actions update the UI instantly before waiting for the backend to confirm:
- `PostsController.toggleLike()` — like count updates immediately
- `DilemmasController.vote()` — vote percentages recalculate immediately
- `PostsController.deletePost()` — post removed from list immediately

### Hero Tag Conflict Prevention

`AdminShell` wraps its content in `HeroControllerScope(controller: MaterialHeroController())` to prevent Hero animation conflicts between the admin panel's image cards and the main app shell's image cards, since both can be in the navigation stack during super admin sessions.

### Global XP Toast System

`XpToastOverlay` is placed at the `MainShell` level and wraps the entire child widget tree. It intercepts `gamificationRewardStreamProvider` broadcasts so:
- No individual screen setup is needed for XP notifications
- Every XP-earning action on every screen automatically shows the toast
- Level-up celebrations are shown globally regardless of which screen triggered the level up

### Join Code System

Bucket lists use randomly generated 6-character alphanumeric join codes (via `generateJoinCode()` in `FirestoreBucketListService`). Users can share this code for others to join a invite-only or public bucket list without direct sharing of Firestore IDs.

### CSV Bulk Import (Admin)

The `CsvUploadService` + `CsvUploadSheet` flow allows an admin to:
1. Pick any `.csv` file from the device
2. Parse it using the `csv` package
3. Preview the data in a table
4. Bulk-write all rows to any specified Firestore collection with a single tap

### Phase 2 Feature Flags

The `EventModel.ticketingEnabled` flag and associated fields (`ticketPrice`, `totalTickets`, `ticketsBooked`, `ticketingDeadline`) are fully modelled but the booking transaction is not yet implemented in the mobile client. The UI renders a "Book Now" CTA but booking flow is pending.

### Place Rankings vs. User Leaderboard

There are two separate ranking systems:
- **Place Leaderboard** (`place_leaderboard`): Ranks *locations* by their `avgRating` — shown in `LeaderboardScreen`
- **User Rankings**: Users in `users` collection sorted by `points` field — not yet exposed as a dedicated screen but data is available

---

## 17. Security & Environment Configuration

### Environment Variables

| Variable | Purpose | Default |
|---|---|---|
| `API_BASE_URL` | REST API base URL | `http://10.0.2.2:3000` |

Injected at build time via `--dart-define=API_BASE_URL=https://api.xplooria.com`.

### Firebase Security Rules

Stored in `firestore.rules`. Key rules:
- User documents: owner-only write access
- Listing collections: public read, admin-only write
- Admin documents: super admin claim required
- Reviews subcollections: authenticated users can write their own reviews

### Firebase Storage Rules

Stored in `storage.rules`. Uploaded images are accessible publicly via Firebase Storage URLs.

### Admin Access Control

Super admin access is controlled by a Firebase Custom Claim (`superAdmin: true`) set via Firebase Admin SDK (see `scripts/set_admin_claim.js`). The Flutter app reads this claim on every auth refresh:

```javascript
// scripts/set_admin_claim.js
admin.auth().setCustomUserClaims(uid, { superAdmin: true })
```

The app force-refreshes the ID token and reads the decoded claim in `AdminService.checkSuperAdminClaim()` to gate all admin routes.

### API Authentication

Every API request includes a fresh Firebase ID token as a Bearer token. On 401, the token is refreshed and the request is automatically retried once before surfacing an error to the user.

---

## Appendix: File Structure Reference

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/app_constants.dart
│   ├── providers/district_provider.dart
│   ├── router/app_router.dart
│   └── theme/
│       ├── app_theme.dart
│       └── theme_controller.dart
├── models/
│   ├── user_model.dart
│   ├── spot_model.dart
│   ├── event_model.dart
│   ├── listing_models.dart
│   ├── community_models.dart
│   ├── gamification_models.dart
│   ├── tour_venture_models.dart
│   ├── bucket_list_models.dart
│   └── admin_model.dart
├── services/
│   ├── auth_service.dart
│   ├── api_client.dart
│   ├── admin_service.dart
│   ├── community_service.dart
│   ├── csv_upload_service.dart
│   ├── event_service.dart
│   ├── firestore_adventure_service.dart
│   ├── firestore_spots_service.dart
│   ├── gamification_service.dart
│   ├── listings_service.dart
│   ├── spots_service.dart
│   └── tour_venture_service.dart
├── controllers/
│   ├── auth_controller.dart
│   ├── admin_controller.dart
│   ├── bucket_list_controller.dart
│   ├── community_controller.dart
│   ├── event_controller.dart
│   ├── gamification_controller.dart
│   ├── listings_controller.dart
│   ├── spots_controller.dart
│   └── tour_venture_controller.dart
├── screens/
│   ├── admin/
│   ├── auth/
│   ├── community/
│   ├── contribute/
│   ├── events/
│   ├── home/
│   ├── leaderboard/
│   ├── listings/
│   ├── onboarding/
│   ├── packages/
│   ├── profile/
│   ├── search/
│   ├── shell/
│   ├── spots/
│   └── ventures/
└── widgets/
    ├── gamification_widgets.dart
    ├── shared_widgets.dart
    └── spot_cards.dart
```

---

*Documentation generated: 28 March 2026*  
*App version: 1.0.0+1*
