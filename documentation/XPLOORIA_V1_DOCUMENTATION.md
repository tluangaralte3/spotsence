# XPLOORIA — Version 1 Product Documentation

> **Gamified Tourism Discovery & Community Platform for Northeast India**
>
> Platform: iOS & Android (Flutter)  
> Backend: Firebase (Firestore, Auth, Storage, Analytics)  
> Version: 1.0  
> Build Date: April 2026  
> Firebase Project: `spotmizoram`  
> Bundle ID (iOS): `com.hillstech.xplooria`  
> Company: HillsTech  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Mission](#2-product-vision--mission)
3. [Core Problems Solved](#3-core-problems-solved)
4. [Platform Architecture](#4-platform-architecture)
5. [Technology Stack](#5-technology-stack)
6. [User Roles, Functions & Duties](#6-user-roles-functions--duties)
7. [Feature Deep-Dive: Guest / Public User](#7-feature-deep-dive-guest--public-user)
8. [Feature Deep-Dive: Registered User](#8-feature-deep-dive-registered-user)
9. [Feature Deep-Dive: Administrator (Super Admin)](#9-feature-deep-dive-administrator-super-admin)
10. [Gamification System](#10-gamification-system)
11. [Data Models & Firestore Collections](#11-data-models--firestore-collections)
12. [Security Model](#12-security-model)
13. [Navigation & Routing](#13-navigation--routing)
14. [Design System & Theme](#14-design-system--theme)
15. [Go-to-Market Strategy](#15-go-to-market-strategy)
16. [Innovation & Vision](#16-innovation--vision)
17. [Validation & Credibility](#17-validation--credibility)
18. [Version 1 Feature Completeness Matrix](#18-version-1-feature-completeness-matrix)
19. [Appendix A: Complete Route Map](#19-appendix-a-complete-route-map)
20. [Appendix B: Dependencies Reference](#20-appendix-b-dependencies-reference)

---

## 1. Executive Summary

**Xplooria** is a gamified, community-driven tourism discovery mobile application purpose-built for Northeast India, starting with Mizoram. It solves the critical gap between the extraordinary natural and cultural richness of Northeast India and its near-total absence from mainstream digital travel platforms.

Version 1 ships a fully functioning dual-facing platform:

- **Consumer app** — Discover places, plan trips, earn XP, build social travel lists, compete on leaderboards, and book curated tour packages.
- **Admin panel** — Embedded within the same app binary; accessible to super-admin accounts only; provides full content management, analytics, moderation, and booking operations.

The platform is engineered on Flutter + Firebase, enabling a single codebase to target both iOS and Android with real-time data, atomic gamification transactions, and role-based access control.

---

## 2. Product Vision & Mission

### Vision

> *To be the definitive digital guide and social layer for tourism across all eight states of Northeast India — making the region's hidden gems discoverable, bookable, and shareable by the world.*

### Mission

- Make Mizoram's landscapes, culture, and cuisine digitally discoverable and accessible to domestic and international travellers.
- Incentivise locals and travellers to contribute, review, and share content through a fair, transparent XP-and-badge reward system.
- Provide local tour operators a no-cost digital storefront to list, promote, and take bookings for their packages.
- Build a self-sustaining community of travellers and content contributors whose engagement continuously enriches the platform.
- Expand across all eight Northeast Indian states as version milestones are reached.

### Tagline Options Tested

- *"Discover the East"*
- *"Where every journey earns a badge"*
- *"Northeast India's Travel Layer"*

---

## 3. Core Problems Solved

| Problem | How Xplooria Solves It |
|---|---|
| Northeast India is invisible on global travel apps | Dedicated, curated, locally-sourced database of 8+ place categories |
| Travellers have no reliable local knowledge source | Community reviews, photos, and contributions from verified locals |
| Tour operators have zero digital presence | Free venture/package listing with booking management |
| Passive content consumers give no feedback | Gamification — every review, photo, and contribution earns XP and badges |
| No social layer for group travel planning | Bucket lists (collaborative rooms), Dares (group challenges), Dilemmas (A/B travel polls) |
| Language/knowledge barriers for first-time visitors | State-by-state Visitor Guides with Dos/Don'ts, Quick Facts, local etiquette |
| No single place to find events | Events section with calendar view, ticketing metadata, and filtering |

---

## 4. Platform Architecture

### 4.1 Layered Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER (Flutter Widgets & Screens)                  │
│  61+ Screen files | 3 Widget libraries | Material 3 Dark-first   │
├──────────────────────────────────────────────────────────────────┤
│  STATE MANAGEMENT LAYER (Riverpod 3)                             │
│  14 Controllers | AsyncNotifiers | StreamProviders               │
├──────────────────────────────────────────────────────────────────┤
│  SERVICE LAYER (Firestore + HTTP)                                │
│  30+ Firestore services | Dio HTTP client | Firebase Storage     │
├──────────────────────────────────────────────────────────────────┤
│  DATA LAYER (Freezed Models)                                     │
│  13 Model files | Immutable classes | JSON serialization         │
├──────────────────────────────────────────────────────────────────┤
│  BACKEND (Firebase Cloud)                                        │
│  Firestore 30+ collections | Auth (custom claims) | Storage      │
│  Analytics | Real-time Database (LatLng lookups)                 │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 State Management Pattern

All state is managed by **Riverpod 3** using:

- **`AsyncNotifier`** — for async CRUD operations (auth, gamification, listing management)
- **`Notifier`** — for synchronous local state (pagination, dare list, bucket list)
- **`StreamProvider`** — for real-time Firestore subscriptions (community posts, bookings, banners)
- **`FutureProvider`** — for one-time data fetches with `.autoDispose` for admin collections

### 4.3 Data Flow (Gamification Example)

```
User submits a review
       ↓
place_detail_screen → GamificationController.award(XpAction.writeReview)
       ↓
GamificationService.award() — Firestore TRANSACTION:
  ① Read users/{uid}
  ② Parse StreakInfo (streak, multiplier 1.0–2.0)
  ③ Calculate xpAwarded = baseXp(15) × multiplier
  ④ Evaluate 22 badges → collect newBadgeIds[]
  ⑤ Recalculate level (1–10)
  ⑥ UPDATE users/{uid} (points, level, badges, streak, lastLogin)
  ⑦ WRITE xpEvents sub-doc (audit log)
       ↓
GamificationResult pushed to broadcast stream
       ↓
XpToastOverlay shows animated "+15 XP" toast (3.5 seconds)
       ↓
authController.refreshProfile() → all profile UI rebuilds
```

### 4.4 Router Architecture

Navigation is handled by **GoRouter 17** with a `_RouterNotifier` (singleton `ChangeNotifier`) that:

1. Caches the latest auth and admin state to avoid GoRouter recreation on every provider change.
2. Implements redirect guards for three tiers: unauthenticated, authenticated, and super-admin.
3. Uses `HeroControllerScope` to isolate admin navigation animations from the main shell.

---

## 5. Technology Stack

### 5.1 Core Framework

| Package | Version | Purpose |
|---|---|---|
| Flutter SDK | ≥ 3.10.8 | Cross-platform mobile UI |
| Dart SDK | ≥ 3.0 | Language |
| flutter_riverpod | ^3.1.0 | Reactive state management |
| go_router | ^17.1.0 | Type-safe declarative navigation |

### 5.2 Firebase Services

| Service | Usage |
|---|---|
| Firebase Auth | Email/password authentication; custom claims for admin role |
| Cloud Firestore | Primary database; 30+ collections; real-time streams |
| Firebase Storage | Image uploads (profile, listing, dare, guide) |
| Firebase Analytics | User event tracking |
| Firebase Realtime DB | Geo/LatLng data lookup |

### 5.3 UI & UX Libraries

| Package | Purpose |
|---|---|
| iconsax | Iconsax icon set (100+ icons used throughout) |
| google_fonts (Inter) | Typography |
| cached_network_image | Lazy image loading with memory/disk cache |
| carousel_slider | Home banner carousel, onboarding |
| smooth_page_indicator | Carousel dot indicators |
| shimmer | Loading skeleton states |
| lottie | JSON animation (achievement, empty states) |
| flutter_animate | Micro-animations |
| fl_chart | Admin analytics charts |
| confetti | Achievement celebration animations |
| percent_indicator | XP progress bars |

### 5.4 Maps & Location

| Package | Purpose |
|---|---|
| flutter_map | OpenStreetMap rendering (Community map tab) |
| latlong2 | Coordinate model (LatLng) |
| geolocator | GPS positioning |
| geocoding | Address ↔ GPS conversion |

### 5.5 Media & Forms

| Package | Purpose |
|---|---|
| image_picker | Camera / gallery photo selection |
| image_cropper | Pre-upload image cropping |
| flutter_form_builder | Form field management |
| form_builder_validators | Built-in validation rules |
| file_picker | CSV file selection for admin bulk upload |
| csv | CSV parsing (admin batch import) |

### 5.6 Networking & Storage

| Package | Purpose |
|---|---|
| dio | HTTP client with interceptors |
| flutter_secure_storage | Encrypted local credential storage |
| shared_preferences | Key-value settings (theme mode, etc.) |
| path_provider | File system path resolution |

### 5.7 Utilities

| Package | Purpose |
|---|---|
| intl | Date/time formatting |
| timeago | Relative timestamps ("2 hours ago") |
| uuid | Unique ID generation |
| url_launcher | External URL and deep-link opening |
| share_plus | System share sheet |
| connectivity_plus | Network reachability detection |
| dartz | Functional Either/Option error handling |

---

## 6. User Roles, Functions & Duties

Xplooria has three distinct user roles, each with different capabilities and access levels.

---

### 6.1 Guest / Unauthenticated User

**Who they are**: Any visitor who opens the app without logging in.

**What they can do:**
- Browse all publicly listed tourist spots, restaurants, cafes, hotels, homestays, adventure spots, shopping areas, and events.
- View spot details (images, descriptions, opening hours, entry fees, facilities, reviews).
- Browse Tour Ventures (packages) and view details.
- View the Community map with all pins.
- Read reviews and community posts.
- Browse the State Visitor Guides.
- View the Leaderboard.

**What they cannot do:**
- Write reviews or upload photos.
- Create community posts, bucket lists, dilemmas, or dares.
- Book ventures.
- Earn XP or badges.
- Access the Admin panel.

**Impact**: Guests represent the top of the funnel. The richness of public content is the primary conversion lever to registration.

---

### 6.2 Registered User

**Who they are**: Any user who has created an account (email + password).

**Permissions**: All guest permissions PLUS the following active participation capabilities.

**Core Duties & Capabilities:**

| Area | Capability |
|---|---|
| Profile | Create and edit profile (name, bio, avatar, location) |
| Reviews | Write a review and rate (1–5 stars) any spot or listing (one per place per user) |
| Photos | Upload community photos to any listing |
| Content Contribution | Submit new spots/places for admin review and approval |
| Bookmarks | Save places to personal bookmarks |
| Events | View and participate in events |
| Booking | Book tour ventures with selected packages and add-ons |
| Gamification | Earn XP, level up (1→10), unlock 22 badges, appear on leaderboard |
| Streaks | Maintain daily login streaks for an XP multiplier bonus |

**Community Features:**

| Feature | Capability |
|---|---|
| Community Feed | Create posts, tips, questions, and photo reports |
| Dilemmas | Create and vote on A/B travel choice polls |
| Bucket Lists (Rooms) | Create collaborative destination lists; invite members; tick off items as a group |
| Dares | Create and join group travel challenges with photo-proof submission |
| Dare Rewards | Scratch-off reward cards earned by completing dare milestones |
| Notifications | Receive real-time push/in-app alerts for dare join requests, approvals, and submissions |

**Venture Booking Workflow:**
1. Browse ventures on Home screen or Ventures tab.
2. Select a package tier and optionally add add-ons (packed lunch, guide, transport, etc.).
3. Review booking summary (total cost breakdown, operator details).
4. Submit booking → status becomes `pending`.
5. Track booking status in "My Bookings" screen.
6. Post-trip: submit feedback and rating.

---

### 6.3 Super Administrator

**Who they are**: Accounts whose Firebase Auth custom claims include `{ "superAdmin": true }`. Set via the Node.js admin script (`scripts/set_admin_claim.js`).

**Access**: Separate `/admin` navigation shell within the same app binary. Inaccessible to regular users. The GoRouter redirect enforces this at every navigation attempt.

**Core Admin Duties & Capabilities:**

#### Content Management
| Duty | Details |
|---|---|
| Manage Tourist Spots | Create, edit, delete spots; manage images, categories, facilities, entry fees |
| Manage Restaurants | Full CRUD for restaurants; price range, cuisine types, delivery flags |
| Manage Accommodations | Manage hotels + homestays in a merged view |
| Manage Cafes | Full CRUD for cafes; specialties, opening hours |
| Manage Adventure Spots | Create/edit adventure categories |
| Manage Shopping Areas | Create/edit shopping venues |
| Manage Events | Create/edit/delete events with ticketing metadata |
| Manage Ventures | Full CRUD for tour packages; set operator info, highlights, itinerary challenges, add-ons |
| Bulk CSV Upload | Import multiple listings at once via CSV file (per collection) |
| Sort & Filter | Sort by name or newest; toggle grid/list view |

#### Banner Management
| Duty | Details |
|---|---|
| Create/Edit Banners | Title, subtitle, image URL, link type (none / external URL / internal route), order |
| Activate/Deactivate Banners | Toggle `isActive` per banner |
| Toggle Section Visibility | Global on/off for the entire home banner carousel via `app_config/home_banners` |

#### User Management
| Duty | Details |
|---|---|
| View All Users | See full list with XP, level, registration date |
| Assign/Revoke Roles | Elevate users to admins or revoke access |
| View User Activity | Review XP history, contributions, bookings, dare participation |

#### Venture / Booking Management
| Duty | Details |
|---|---|
| View All Bookings | See every booking request across all ventures |
| Update Booking Status | Confirm, cancel, or mark as completed |
| Add Admin Notes | Leave internal notes on bookings |
| View Feedback | Read post-trip user feedback per venture |
| Packages Tab | See all venture packages and their registration counts |

#### Analytics Dashboard
| Metric | Details |
|---|---|
| Total Users | All registered users count |
| New Users Today / This Week | New registrations trend |
| Total Spots & Listings | Per-collection counts |
| Total Events & Ventures | Content inventory |
| Community Activity | Posts, reviews, dilemma votes |
| Booking Statistics | Pending, confirmed, completed |
| XP Awarded | Total platform gamification output |
| Charts | Daily active usage trends, submissions by category (via fl_chart) |

#### Visitor Guide Management
| Duty | Details |
|---|---|
| Create/Edit State Guides | Per-state guide with tagline, about, quick facts, Dos/Don'ts |
| Publish/Unpublish | Toggle guide visibility per state |
| Upload Banner Images | State-specific guide hero images |

#### Moderation
| Duty | Details |
|---|---|
| Review Contributions | Approve or reject user-submitted spots |
| Flag Content | Remove posts, reviews, or photos violating guidelines |
| Bulk Approve/Reject | Process contribution queues efficiently |

---

## 7. Feature Deep-Dive: Guest / Public User

### 7.1 Home Screen

The Home screen is the primary entry point. It is built as a `CustomScrollView` with `SliverAppBar` (floating) and multiple stacked sections:

**Sections (top to bottom):**

1. **App Bar** — Xplooria logo and notification bell (dare requests badge if signed in).
2. **State Selector** — Subtitle "Exploring [Mizoram]" is tappable; opens a bottom sheet picker for 8 NE states (only Mizoram active in V1; others show "Coming Soon").
3. **Home Banner Carousel** — Firestore-driven promotional banners with links (internal routes or external URLs). Hidden when admin disables the section. Smooth dot indicators.
4. **Browse Listings Grid** — 4-column grid of category shortcuts: Tourist Spots, Restaurants, Stay, Cafes, Adventure, Shopping, Events, Community. Each taps to the respective Listings tab.
5. **Visitor Guide Card** — Tappable state guide card for the selected NE state; opens full guide.
6. **Featured Spots Section** — Horizontally scrollable cards with category filter tabs (All, Mountains, Waterfalls, Cultural Sites, Viewpoints, Adventure). Cards show image, category, name, location, rating, and views.
7. **Tour Packages Section** — Horizontally scrollable venture cards from the live `ventures` collection. Shows image, category chip, difficulty chip, duration, price, location, and operator.
8. **AI Travelling Planner (Locked)** — "Coming Soon" teaser section with locked badge, feature chips (Smart Itineraries, AI Companion Chat, Personalised Tips, Live Suggestions), and launch announcement.
9. **Quick Stats (Signed-in only)** — XP, contributions count, badges count stat cards.

### 7.2 Spots Screen

- Paginated list of tourist spots pulled from `spots` Firestore collection.
- Filter chips for 6 categories (Mountains, Waterfalls, Cultural Sites, Viewpoints, Adventure, Lakes/Caves).
- Each card shows hero image, category, name, district, rating, and view count.
- Tapping opens `SpotDetailScreen`: full image gallery, description, facilities, entry fees, "Things to Do" list, add-ons, and review thread.

### 7.3 Listings Screen

Tabbed screen for 7 listing types:

| Tab | Firestore Collection | Extra Details |
|---|---|---|
| Restaurants | `restaurants` | Cuisine types, price range, delivery/reservation flags |
| Stay | `accommodations` + `homestays` | Merged view of hotels and homestays |
| Cafes | `cafes` | Specialties, opening hours |
| Adventure | `adventureSpots` | Difficulty, group info |
| Shopping | `shoppingAreas` | Category, map |
| Events | `events` | Dates, ticketing, type |
| Ventures | `ventures` | Full enterprise tour packages |

Each listing taps to a full detail screen with gallery, details, map, and reviews.

### 7.4 Search Screen

- Global search across all collections simultaneously.
- Category filter chips to scope search.
- Real-time debounced Firestore queries.

### 7.5 Community — Map Tab (Feed)

The Community screen's default "Feed" tab renders a full-screen interactive map powered by `flutter_map` (OpenStreetMap):

- **Map Tiles**: Carto Dark (dark mode) / Carto Light (light mode) adapts to the app theme.
- **Pins**: Two pin types:
  - **Animated Pulsing Pins** (tourist spots) — colour-coded by category (Mountains=blue, Waterfalls=cyan, Cultural=amber, etc.); 1.8s pulsing animation.
  - **Circular Image Pins** (restaurants, cafes) — circular cropped photo with pin-tip below; border colour indicates category.
- **Filter Bar**: Icon-based filter chips (Iconsax icons) for All, Tourist Spots, Restaurants, Cafes, Adventure, Homestays, Shopping, Events. Chips are pill-shaped with primary colour fill when selected.
- **Search Bar**: Text search that filters visible pins by name, location, or category in real-time.
- **Zoom Controls**: +/- buttons top-right.
- **Tap to Detail**: Tapping any pin opens a bottom sheet (`place_detail_sheet` or `spot_detail_sheet`) with name, category, rating, and quick-navigate CTA.
- **Swipe disabled** on map tab (prevents pan/zoom gesture conflict) via `NeverScrollableScrollPhysics`.

### 7.6 Leaderboard

- Ranked list of users by total XP.
- Shows rank, avatar, display name, level badge, XP total.
- Top 3 users are visually prominent (gold/silver/bronze styling).

### 7.7 Visitor Guide

- Per-state digital travel guide.
- Sections: Banner image, tagline, "About the State", Quick Facts (capital, language, population, best season, etc.), Dos, Don'ts.
- Only Mizoram is active in V1. Other states show "Coming Soon" modal when selected.

### 7.8 Events

- Calendar and list view of events.
- Filters by type and upcoming/past.
- Event detail: title, description, date/time range, location, ticket availability, ticket price.

---

## 8. Feature Deep-Dive: Registered User

All guest features apply, plus:

### 8.1 Authentication Flow

**Register:**
1. Enter name, email, password.
2. Firebase Auth creates user.
3. Firestore `users/{uid}` document created with defaults: `points=0, level=1, levelTitle="Explorer"`.
4. Redirected to Home.

**Sign In:**
1. Enter email and password.
2. Firebase Auth validates.
3. Custom claim checked (`superAdmin`) — regular users go to `/`, admins to `/admin`.

**Forgot Password:** Firebase Auth sends reset email.

### 8.2 Profile Screen

**Displays:**
- Avatar, display name, level badge, XP progress bar (level min → max), level title.
- Stats row: total XP, reviews count, contributions count, photos uploaded.
- Streak banner (🔥 current streak, longest streak).
- Badges grid — earned badges with rarity colour coding (Common/Rare/Epic/Legendary).
- XP History — scrollable activity feed (earned XP event log).
- "My Bookings" shortcut — links to venture bookings.
- "Dare Dashboard" — summary of joined dares and progress.

**XP Perks Sheet** (tappable XP chip):
- Current level + XP display.
- MezoPerks section (loyalty perks — roadmap in V1, "Coming Soon" pill).
- Recent XP earnings log.

### 8.3 Writing Reviews

- One review per user per listing (enforced via deterministic review ID: `{userId}_{placeId}`).
- 1–5 star rating + text comment.
- Review atomic-updates the running average rating on the parent listing document.
- Recorded in the global `global_reviews` collection for cross-collection review aggregation.
- Awards **+15 XP** (`XpAction.writeReview`).

### 8.4 Uploading Community Photos

- Multi-image picker (camera or gallery).
- Optional crop step.
- Uploads to Firebase Storage: `/community_photos/{collection}/{placeId}/{userId}_{timestamp}.ext`.
- Awards **+10 XP** (`XpAction.uploadPhoto`).

### 8.5 Bucket Lists (Collaborative Rooms)

**Concept**: Shared destination wish-lists that friends or groups can add to and tick off together.

**Create a Bucket List:**
- Title, description, banner image, category (11 types), visibility (public/private), max members.
- Awards **+20 XP** (`XpAction.createBucketList`).
- Free plan limit: **5 rooms** per user (`kFreeRoomCap = 5`).

**Joining a Room:**
- Public rooms: join request → host approves/declines.
- Private rooms: join via unique 6-character join code.

**Inside a Room:**
- Member list with roles (host/member).
- Items list with category icons, notes, and "checked" state.
- Any member can tick off items → awards **+10 XP** per check.
- Host can add/remove/edit items.

**Feature Unlocks (time-based):**
- `kConnectUnlockDays = 10` — After 10 days since joining, unlock Connect features.
- `kPokeUnlockDays = 20` — After 20 days, unlock Poke feature.

### 8.6 Dares (Group Travel Challenges)

**Concept**: Group-based challenges where participants complete and prove real-world travel tasks.

**Create a Dare:**
- Title, description, banner, category (11 types: adventure, food rating, photography, etc.), visibility, max participants, deadline.
- Free plan limit: **5 dares** per user (`kFreeDareCap = 5`).

**Adding Challenges to a Dare:**
- Each challenge: title, description, type (app listing or custom), points, deadline.
- Admin can set medal tier awards (bronze/silver/gold/platinum/special).

**Joining a Dare:**
- Public: request to join → creator approves.
- Private: join via code.

**Completing Challenges:**
- Participants submit photo proof for verification.
- Creator reviews submissions.
- On approval: challenge points awarded, medals unlocked.

**Dare Rewards:**
- Scratch-off cards awarded for milestones.
- Reward types: XP, medal, badge, XP multiplier, or "nothing" (gamble element).
- Each card has a rarity tier.

**Notifications:**
- In-app notification bell (badge count on app bar).
- Notification types: join requests, approvals, new submissions.

### 8.7 Dilemmas (A/B Travel Polls)

Short "would you rather?" style polls for community engagement:

- Title and description.
- Option A vs Option B (with images).
- Voting is optimistic (instant UI update, server sync in background).
- Vote counts update in real-time for all viewers.
- Users can change their vote — previous vote is atomically removed from both options before adding new vote.
- Awards **+25 XP** to creators, **+5 XP** to voters.

### 8.8 Community Feed

- `PostType` enum: `post`, `review`, `tip`, `question`.
- Posts can include text, multiple images, and optionally link to a spot.
- Like/unlike posts (optimistic).
- Comment on posts.
- Infinite scroll pagination (Riverpod paginated notifier).
- Own posts can be deleted (with optimistic removal and rollback on failure).

### 8.9 Venture Booking

**Booking Flow:**
1. View venture detail (title, description, category, difficulty, duration, season, operator info, highlights, images, reviews).
2. Select a package tier from the operator's packages.
3. Set group size, special requests.
4. Choose optional add-ons (e.g., packed lunch +₹250, porter +₹500).
5. Review booking page: full breakdown (base price × people + add-ons = grand total, operator contact).
6. Submit → `bookings/{docId}` created with `status: pending`.
7. Track under "My Bookings" (pending → confirmed → completed).
8. Post-completion: submit rating + written feedback.

---

## 9. Feature Deep-Dive: Administrator (Super Admin)

### 9.1 Admin Shell & Navigation

The admin area (`/admin`) is a separate `ShellRoute` with its own navigation:

- **`NavigationRail`** (wide screens / tablets) — vertical persistent side navigation.
- **`BottomNavigationBar`** (narrow/phone screens) — 5 tabs: Dashboard, Listings, Users, Analytics, Dares.
- Ventures management is embedded inside the **Listings → Ventures tab**.
- Animated route transitions use `HeroControllerScope` isolated from the main app shell.

### 9.2 Admin Dashboard

Real-time stats from `AppAnalyticsSnapshot` (Firestore: `app_analytics/daily_snapshot`):

| Metric | Data Source |
|---|---|
| Total Users | `users` collection count |
| New Users Today | Timestamp-filtered |
| New Users This Week | Timestamp-filtered |
| Total Spots | `spots` collection count |
| Total Listings | Sum across restaurants, cafes, hotels, etc. |
| Total Events | `events` count |
| Total Ventures | `ventures` count |
| Total Community Posts | `community_posts` count |
| Total Reviews | `global_reviews` count |
| Pending Bookings | `bookings` filtered by `status: pending` |
| Total Bookings | `bookings` total count |
| Total XP Awarded | Sum of all `xpEvents` values |

### 9.3 Listings Management (Admin)

**TabBar with 8 tabs:** Spots, Restaurants, Accommodations, Cafes, Adventure, Shopping, Events, Ventures.

**Per-tab features:**
- Live data via `autoDispose` FutureProvider (fetched fresh on each visit).
- Toggle between **List view** (rows with thumbnail, name, location, edit/delete) and **Grid view** (2-column image cards).
- **Sort** by Name (A–Z) or Newest (by `createdAt` timestamp).
- **Filter bar** collapses on scroll (animates via `AnimatedSize`).
- **Edit** button → navigates to form screen with fields pre-populated.
- **Delete** button → shows confirmation dialog → calls `adminListingNotifier.deleteListing()`.
- **Bulk CSV Upload** (via upload icon) → parses CSV and batch writes to Firestore.
- **FAB** (Floating Action Button) → navigates to add form (hidden on Ventures tab — uses embedded screen's own "New" button).

**Ventures tab specifically** renders the full `AdminVenturesScreen` embedded within the Listings screen, with three sub-tabs:
- **Packages** — List all ventures with card UI, tap to manage.
- **Feedback** — All post-trip feedback from users per venture.
- **Bookings** — All booking records with status chips and admin note field.

### 9.4 Listing Forms (Add/Edit)

**Generic listing form** (`admin_add_listing_screen.dart`):
- Title, Description, Location, Category, District.
- Images (multi-select + Firebase Storage upload).
- Rating (seed value), Price Range ($ → $$$$).
- Category-specific dynamic fields (amenities for hotels, cuisine types for restaurants, etc.).

**Venture form** (`admin_venture_form_screen.dart`) — 12 sections:
1. Basic Info (title, tagline, description)
2. Category & Difficulty (16 category types, 4 difficulty levels)
3. Season (8 season options)
4. Duration (days, nights)
5. Group & Age (max group size, min age)
6. Booking Policy (advance booking days)
7. Pricing (starting price, currency)
8. Operator Info (name, phone, WhatsApp, email)
9. Location (location text, district)
10. Highlights (add/remove bullet list)
11. Images (hero image URL + image list)
12. Challenges (add/remove venture challenges)

**Numeric fields show blank (not "0") for unset values** — user-friendly UX for editing.

### 9.5 Banner Management

- Admin can create banners with: title, subtitle, image URL, link type, link value (internal route or external URL), active flag, and ordering number.
- Global carousel section can be toggled on/off with one tap (writes to `app_config/home_banners`).
- Banners ordered by the `order` integer field.

### 9.6 Visitor Guide Management

- One guide per NE state (8 states).
- Editable fields: stateName, emoji, tagline, about text, Dos array, Don'ts array, quick facts (label+value+icon), banner image URL, published flag.
- Draft/unpublished guides are not visible in the consumer app.

### 9.7 Analytics Screen

Powered by `fl_chart`:
- Line charts: daily new users trend.
- Bar charts: bookings by status, XP awarded over time.
- Summary cards for all dashboard metrics.
- Data snapshot from `app_analytics` Firestore document.

---

## 10. Gamification System

Xplooria's gamification engine is a full, production-grade reward system built with atomic Firestore transactions.

### 10.1 XP Actions & Rewards

| Action | XP Earned | Trigger |
|---|---|---|
| Write a review | +15 | Submitting any listing review |
| Upload a photo | +10 | Uploading community photo |
| Create a bucket list | +20 | New bucket list created |
| Complete a bucket item | +10 | Tick off item in a list |
| Create a dilemma | +25 | New A/B poll created |
| Vote on a dilemma | +5 | Casting a vote |
| Submit a contribution | +20 | Submit a new spot for review |
| Daily login | +5 | First app open each calendar day |
| Streak bonus (7 days) | +10 | Awarded at streak milestone |
| Weekly streak | +30 | 7-consecutive-day login |
| Monthly streak | +100 | 30-consecutive-day login |

### 10.2 Streak Multiplier System

A streak mechanic incentivises daily app engagement:

```
Multiplier = 1.0 + floor(loginStreak ÷ 5) × 0.10
Maximum multiplier = 2.0 (at 50+ day streak)
```

| Streak | Multiplier | Bonus |
|---|---|---|
| 1–4 days | 1.0× | No bonus |
| 5–9 days | 1.1× | +10% XP |
| 10–14 days | 1.2× | +20% XP |
| 15–19 days | 1.3× | +30% XP |
| 20–24 days | 1.4× | +40% XP |
| 25+ days | 1.5×+ | Increases every 5 days |
| 50+ days | 2.0× (cap) | +100% XP |

### 10.3 Level System (10 Levels)

| Level | Title | XP Required |
|---|---|---|
| 1 | Explorer | 0 |
| 2 | Wanderer | 100 |
| 3 | Adventurer | 250 |
| 4 | Pathfinder | 500 |
| 5 | Guide | 1,000 |
| 6 | Expert | 2,000 |
| 7 | Master | 3,500 |
| 8 | Legend | 5,500 |
| 9 | Champion | 8,500 |
| 10 | Guardian | 12,500 |

### 10.4 Badge System (22 Badges)

**Exploration Badges (6)**

| Badge | Trigger |
|---|---|
| First Review | Submit first review |
| Ten Reviews | Submit 10 reviews |
| Fifty Reviews | Submit 50 reviews |
| First Contribution | Submit first spot |
| Ten Contributions | Submit 10 spots |
| 25 Contributions | Submit 25 spots |

**Photography Badges (2)**

| Badge | Trigger |
|---|---|
| First Photo | Upload first community photo |
| Photo Master | Upload 50+ community photos |

**Streak Badges (3)**

| Badge | Trigger |
|---|---|
| 3-Day Streak | 3 consecutive daily logins |
| 7-Day Streak | 7 consecutive daily logins |
| 30-Day Streak | 30 consecutive daily logins |

**Community Badges (2)**

| Badge | Trigger |
|---|---|
| First Dilemma | Create first A/B poll |
| Dilemma Voter | Vote on 50+ dilemmas |

**Bucket List Badges (2)**

| Badge | Trigger |
|---|---|
| Bucket Complete (1) | Complete your first bucket list |
| Bucket Complete (10) | Complete 10 bucket lists |

**Special & Achievement Badges (7)**

| Badge | Trigger | Rarity |
|---|---|---|
| Early Adopter | Registered in first month of launch | Legendary |
| Top 10 | Reach global leaderboard top 10 | Epic |
| Level 5 | Reach level "Guide" | Rare |
| Level 10 | Reach level "Guardian" | Legendary |
| Social Butterfly | 100+ community post likes received | Rare |

**Rarity Tiers:**
- **Common** (grey) — Easy to obtain, high frequency
- **Rare** (blue #42A5F5) — Moderate effort
- **Epic** (purple #AB47BC) — Significant achievement
- **Legendary** (gold #FFB300) — Exceptional milestone

### 10.5 XP Reward Notification (Toast)

An animated overlay (`XpToastOverlay`) is positioned above the bottom navigation bar. It:

1. Listens to the `gamificationRewardStreamProvider` (broadcast stream).
2. Slides up from bottom with animation when XP is awarded.
3. Displays: `+{xp} XP`, action label, multiplier badge (if > 1.0×), and level-up celebration.
4. Auto-dismisses after **3.5 seconds**.
5. Shows confetti animation on badge unlock or level-up events.

---

## 11. Data Models & Firestore Collections

### 11.1 Firestore Collection Architecture

```
firestore/
├── users/{uid}                      ← User profiles, XP, badges, streaks
│   └── xpEvents/{eventId}           ← XP audit log per user
├── spots/{docId}                    ← Tourist spots
│   ├── reviews/{reviewId}           ← Spot reviews (1 per user)
│   └── communityPhotos/{photoId}    ← Community photo uploads
├── restaurants/{docId}              ← Restaurant listings
│   └── reviews/{reviewId}
├── cafes/{docId}                    ← Cafe listings
│   └── reviews/{reviewId}
├── accommodations/{docId}           ← Hotel listings
│   └── reviews/{reviewId}
├── homestays/{docId}                ← Homestay listings
│   └── reviews/{reviewId}
├── adventureSpots/{docId}           ← Adventure spot listings
│   └── reviews/{reviewId}
├── shoppingAreas/{docId}            ← Shopping area listings
│   └── reviews/{reviewId}
├── events/{docId}                   ← Events with ticketing
├── ventures/{docId}                 ← Tour packages
│   ├── reviews/{reviewId}           ← Venture reviews
│   ├── registrations/{regId}        ← Booking registrations
│   └── feedback/{fbId}             ← Post-trip feedback
├── bookings/{docId}                 ← Top-level booking records
├── community_posts/{docId}          ← Community feed posts
├── dilemmas/{docId}                 ← A/B poll dilemmas
├── bucketLists/{listId}             ← Collaborative travel lists
├── dares/{docId}                    ← Group travel challenges
├── global_reviews/{reviewId}        ← Cross-collection review index
├── home_banners/{bannerId}          ← Home carousel banners
├── visitor_guides/{stateKey}        ← Per-state visitor guides
├── app_admins/{uid}                 ← Admin profiles and permissions
│   └── activityLog/{logId}         ← Admin action audit trail
├── app_analytics/{docId}            ← Platform analytics snapshot
└── app_config/{configKey}           ← Global configuration flags
```

### 11.2 Key Model Schemas

**UserModel** — Core user profile stored at `users/{uid}`

```
id, email, displayName, photoURL, bio, location,
role (0=admin, 1=user),
points, level (1–10), levelTitle,
badges[], badgesEarned[], 
contributionsCount, ratingsCount, photosCount,
dilemmasCreated, dilemmasVoted,
bucketListsCreated, bucketItemsCompleted,
loginStreak, longestStreak, lastLogin,
bookmarks[], createdAt
```

**VentureBooking** — Tour booking record at `bookings/{id}`

```
id, userId, userName, userEmail,
ventureId, ventureTitle, heroImage, category, location,
operatorName, operatorPhone, operatorWhatsapp, operatorEmail,
selectedPackageName, pricePerPerson, personCount,
selectedAddons[], addonSubtotal, grandTotal,
status (pending|confirmed|cancelled|completed),
adminNote, hasFeedback, createdAt, updatedAt
```

**DareModel** — Group challenge at `dares/{id}`

```
id, title, description, bannerUrl,
category (11 types), customCategory,
visibility (public|private), maxParticipants, joinCode,
creatorId, creatorName, creatorPhoto,
challenges[] (DareChallenge),
members[] (DareMember),
createdAt, deadline, xpReward,
requiresProof, tags[], status
```

**BucketListModel** — Collaborative room at `bucketLists/{id}`

```
id, title, description, bannerUrl,
category (11 types), visibility, maxMembers, joinCode,
hostId, hostName, hostPhoto,
items[] (BucketItem), members[] (BucketMember),
joinRequests[], createdAt, completedAt,
xpReward, badges, challengeTitle
```

---

## 12. Security Model

### 12.1 Role Enforcement

Security is enforced at two levels:

1. **GoRouter (Client-side)**: `_RouterNotifier` redirect logic blocks unauthenticated users from protected routes and blocks non-admin users from `/admin` routes.

2. **Firestore Security Rules (Server-side)**: All operations are validated server-side with three helper functions:

```javascript
function isAuth() { return request.auth != null; }
function isUser(uid) { return isAuth() && request.auth.uid == uid; }
function isSuperAdmin() {
  return isAuth() && request.auth.token.superAdmin == true;
}
```

### 12.2 Data Access Matrix

| Collection | Public Read | Auth Read | Auth Write | Admin Only Write |
|---|---|---|---|---|
| users | No (auth only) | Own doc | Own doc | — |
| spots, restaurants, cafes, etc. | **Yes** | Yes | Yes | — |
| reviews (sub-collection) | **Yes** | Yes | Create (own) | — |
| community_posts | **Yes** | Yes | Create / own delete | delete any |
| bucketLists | Public only if visibility=public | Member read | Host/member | — |
| dares | Public if public | Member read | Creator/member | — |
| bookings | No | Own booking | Create own | Status updates |
| ventures | **Yes** | Yes | No | Full CRUD |
| ventures/registrations | No | Own | Create | Update/delete |
| ventures/feedback | **Yes** | Yes | Create | — |
| app_admins | Admin only | Own | No | Full CRUD |
| app_analytics | No | No | No | Full CRUD |
| home_banners | **Yes** | Yes | No | Full CRUD |
| visitor_guides | **Yes** | Yes | No | Full CRUD |

### 12.3 Firebase Storage Rules

| Path | Read | Write Conditions |
|---|---|---|
| `/community_photos/` | Public | Auth + < 10 MB + image/* |
| `/avatars/{userId}/` | Public | Auth + own userId + < 5 MB + image/* |
| `/admin_listings/` | Public | Auth + < 15 MB + image/* |
| `/dare_banners/` | Public | Auth + < 10 MB + image/* |
| `/dare_proofs/` | Auth | Auth + < 15 MB + image/* |
| `/banners/` | Public | Auth + < 10 MB + image/* |
| `/visitor_guides/` | Public | isSuperAdmin + < 10 MB + image/* |

### 12.4 Custom Claim Setup

Super Admin accounts are created via the Node.js utility:

```
scripts/set_admin_claim.js <serviceAccount.json>

Admin Email:    hillstechadmin@spotsence.com
Custom Claim:   { superAdmin: true }
Firestore Doc:  app_admins/{uid}  (permissions: all flags true)
```

---

## 13. Navigation & Routing

### 13.1 Shell Structure

The app has two independent `ShellRoute` shells:

1. **Main Shell** — Bottom navigation with 5 tabs: Home, Explore (Spots), Map (Community), Profile, Leaderboard. Available to all authenticated and guest users.

2. **Admin Shell** — Separate navigation rail/bottom bar for admin-only screens. Isolated `HeroControllerScope`.

### 13.2 Auth Redirect Logic

```
On every navigation:
1. Auth loading? → hold (return null)
2. Not authenticated + protected route? → /login
3. Authenticated + auth route (/login, /register)? → /
4. Route starts with /admin?
   a. Not authenticated? → /login
   b. Admin loading? → hold
   c. Not superAdmin? → / (home, denied silently)
```

### 13.3 Route Transition Types

- **Slide Up** — Modal screens (auth, booking flow, creation forms)
- **Fade** — Detail screens (spot, listing, event, venture)
- **Default** — Admin screens (no transition override)

---

## 14. Design System & Theme

### 14.1 Colour Palette

**Brand Colours (theme-invariant):**

| Token | Hex | Usage |
|---|---|---|
| `AppColors.primary` | `#00E5A0` | CTAs, highlights, active states, FABs |
| `AppColors.secondary` | `#6C63FF` | Tags, secondary accents |
| `AppColors.accent` | `#FFB300` | Gold — XP, badges, stars, rewards |
| `AppColors.success` | `#22C55E` | Success states, easy difficulty |
| `AppColors.error` | `#EF4444` | Errors, hard difficulty |
| `AppColors.warning` | `#F59E0B` | Warnings, moderate difficulty |

**Adaptive Surfaces (dark/light via `context.col`):**

| Token | Dark | Light | Usage |
|---|---|---|---|
| `.bg` | `#0A0E1A` | `#F4F7FF` | App background |
| `.surface` | `#121827` | `#FFFFFF` | Cards, sheets |
| `.surfaceElevated` | `#1C2333` | `#F0F4FF` | Dropdowns, elevated |
| `.border` | `#2A3347` | `#E0E8F4` | Dividers, outlines |
| `.textPrimary` | `#F0F4FF` | `#1A1F35` | Main text |
| `.textSecondary` | `#8892A4` | `#5A6480` | Labels, hints |
| `.textMuted` | `#4A5568` | `#A0AEC0` | Disabled text |

### 14.2 Typography (Google Fonts — Inter)

All text uses the **Inter** variable font:

| Style | Size | Weight | Use |
|---|---|---|---|
| displayLarge | 32px | 700 | Hero titles |
| titleLarge | 20px | 600 | Screen titles |
| titleMedium | 16px | 600 | Section headers |
| bodyLarge | 15px | 400 | Primary body copy |
| bodyMedium | 14px | 400 | Secondary text |
| labelLarge | 14px | 600 | Button labels |

### 14.3 Component Specifications

| Component | Specification |
|---|---|
| Cards | 16px radius, 1px border, zero elevation (flat design) |
| Buttons (primary) | Primary colour fill, 52px min height, 14px radius, full-width |
| Buttons (outline) | 1px border, no fill, 14px radius |
| Input fields | Filled style, 12px radius, 16px horizontal padding; focus: 1.5px primary border |
| Chips | 20px radius, bordered, rarity colours for badges |
| FAB (extended) | Primary fill, black text/icon, "Add {Category}" label |
| Bottom Nav | Fixed, no elevation, primary icon colour on active |
| Tab Bars | Scrollable, label-size indicator, 2.5px indicator weight |

---

## 15. Go-to-Market Strategy

### 15.1 Target Audiences

**Primary: Domestic Travellers (25–45)**
- Indian tourists planning trips to Northeast India.
- Digital-native, comfortable with app-based discovery.
- Seeking authentic, off-the-beaten-path experiences.
- Value local recommendations over generic travel aggregators.

**Secondary: International Travellers**
- Adventure tourism enthusiasts.
- Photography/nature travel community.
- Cultural heritage explorers.
- Budget backpackers and sustainable travel advocates.

**Tertiary: Local Content Creators & Contributors**
- Mizoram residents who are proud of their state.
- Local bloggers, photographers, food reviewers.
- Students and young professionals.
- Incentivised by XP, badges, leaderboard visibility, and future MezoPerks rewards.

**Quaternary: Tour Operators & Local Businesses**
- Small and medium tour operators in Mizoram.
- Homestay owners, adventure guides, cultural experience providers.
- Motivated by free digital storefront and direct booking management.

### 15.2 Launch Phase Strategy

**Phase 1 — Mizoram Beta Launch (V1)**
- Soft launch with Mizoram content.
- Seed database via admin CSV bulk upload of existing tourist data.
- Partner with 5–10 established tour operators for venture listings.
- Influencer seeding: partner with Mizo travel Instagram and YouTube creators.
- Campus ambassador programme at Mizoram University, ICFAI, and NIT Mizoram.
- Target: **1,000 registered users in first 60 days**.
- Target: **50 community photo contributions in first 30 days**.

**Phase 2 — Community Activation**
- Dare campaign: "Explore 5 Hidden Gems of Mizoram" — first-ever platform-wide dare with prizes.
- Review drive: "Rate Your Favourite Spot" — multiplied XP week for reviews.
- Partner with Mizoram Tourism Department for official endorsement.
- Target: **5,000 users, 500 reviews, 20 active tour operators** by end of Phase 2.

**Phase 3 — Northeast Expansion**
- Activate Nagaland (Hornbill Festival tie-in), Meghalaya (Living Root Bridges), Manipur.
- Multi-state leaderboard seasons.
- Cross-state Dare events.
- Target: **25,000 users across 3 states**.

### 15.3 Monetisation Roadmap (Post-V1)

| Stream | Mechanism | Timeline |
|---|---|---|
| Operator Commission | 5–10% on confirmed venture bookings | Phase 2 |
| Featured Listings | Pay-to-be-featured — promoted spots on home screen | Phase 2 |
| MezoPerks Loyalty | Partnerships with local businesses for XP reward redemption | Phase 3 |
| Premium Users | Remove dare/bucket list cap; exclusive badges; advanced analytics | Phase 2 |
| Sponsored Dares | Brands sponsor platform-wide travel challenges | Phase 3 |
| AI Planner (Premium) | AI itinerary generation subscription | Phase 4 |

### 15.4 Distribution Channels

- **App Stores**: iOS App Store + Google Play Store (primary).
- **WhatsApp**: Organic sharing via `share_plus` (spot cards, venture links).
- **Social Media**: Instagram (visual tourism content), Facebook (Mizoram community groups), YouTube (operator showcase videos).
- **Government Partners**: Mizoram Tourism Department official partnership for credibility and data access.
- **Travel Agencies**: B2B referral partnerships for venture bookings.
- **University Networks**: Student ambassador programme for contributor acquisition.

### 15.5 Retention Mechanics

| Mechanic | Purpose |
|---|---|
| Daily Login Streak | Habit formation; escalating XP multiplier punishes streak breaks |
| Badge Notifications | Milestone-triggered push to re-engage dormant users |
| Weekly Leaderboard Reset | Creates urgency for weekly engagement spikes |
| New Dare Notifications | Social pressure from friend group activities |
| Booking Status Updates | Keeps users in the booking funnel until completion |
| Review Follow-up | Post-visit prompt to submit experience rating |

---

## 16. Innovation & Vision

### 16.1 What Makes Xplooria Different

**1. Hyper-Local Focus**
Unlike global platforms (TripAdvisor, Google Maps), Xplooria is built exclusively for Northeast India. Every feature, category, and data model is designed for the specific travel patterns, geography, and culture of the region. This hyper-local focus enables:
- Categories that matter locally (Homestays, Adventure Spots, Cultural Sites) — not generic hotel chains.
- Local operator onboarding with no technical overhead.
- Content verified by people who actually know the region.

**2. Gamification as Core Infrastructure (Not an Afterthought)**
Gamification is not a "layer" on top of the product — it is embedded in the Firestore transaction layer. Every meaningful user action triggers an atomic XP award that:
- Cannot be double-awarded (transaction integrity).
- Cannot be lost (even if the UI crashes, the XP write persists).
- Cascades to badge evaluation, level recalculation, and streak tracking simultaneously.

**3. Social Travel Planning — Beyond Lists**
The combination of Bucket Lists (collaborative destination lists), Dares (proof-based group challenges), and Dilemmas (community voting) creates a full social travel planning ecosystem that no existing travel app offers in the Indian market.

**4. Operator Empowerment**
Local tour operators get:
- A mobile storefront with full package/pricing configuration.
- Direct booking management with status tracking.
- Customer feedback collection.
- WhatsApp integration (operator contact via WhatsApp is standard in India).
- All at zero cost in V1.

**5. Resilient Offline-First Architecture**
`flutter_secure_storage` and `shared_preferences` cache critical data locally. `connectivity_plus` monitors network state. Future offline database (Hive or SQLite) is already in the architecture roadmap.

**6. AI Travelling Planner (Roadmap)**
The V1 UI already includes a locked "Coming Soon" teaser for the AI Travelling Planner & Companion feature. This teaser:
- Communicates the platform's AI ambition.
- Sets user expectations for the next release.
- Validates interest before building (lean startup signal).

Planned AI capabilities:
- **Smart Itinerary Generation** — Input: start date, interests, budget → Output: day-by-day itinerary with Xplooria listings.
- **AI Companion Chat** — Answers travel questions contextually using Xplooria's curated data.
- **Personalised Recommendations** — ML-powered spot suggestions based on review history and browsing patterns.
- **Live Suggestions** — Real-time context-aware tips based on GPS location.

### 16.2 Technical Innovation

**Atomic Gamification Transactions**
The `GamificationService.award()` method uses Firestore's multi-document transaction to ensure XP, badge evaluation, level recalculation, streak tracking, and audit logging happen atomically — no partial state possible.

**Dual-Shell Admin Architecture**
The admin and consumer apps share the same codebase but are separated by GoRouter's `ShellRoute` with independent `HeroControllerScope`. This eliminates the need for two separate Flutter projects while maintaining complete UI/UX isolation between admin and consumer modes.

**Real-time Earned-State Architecture**
Profile data (XP, level, badges) updates in real-time for the user who triggered the action via `authController.refreshProfile()`, and for any other viewer of their profile via `currentUserStreamProvider` (Firestore live stream). No polling required.

**Security-by-Design**
Both client-side (GoRouter) and server-side (Firestore rules) enforce the same role model independently. Even if the GoRouter is bypassed, Firestore rules prevent unauthorised writes.

### 16.3 Long-Term Vision (3-Year Roadmap)

| Milestone | Description |
|---|---|
| V1 (Current) | Mizoram, all core features, admin panel, gamification |
| V1.5 | Push notifications (FCM), offline reading mode, enhanced search |
| V2 | AI Travelling Planner (basic), 3 new NE states |
| V2.5 | MezoPerks loyalty programme live, operator analytics dashboard |
| V3 | Full NE coverage (all 8 states), AI companion, premium subscriptions |
| V4 | Pan-India tribal/rural tourism expansion, B2B API for travel agencies |

---

## 17. Validation & Credibility

### 17.1 Technical Credibility

**Production-Grade Stack**
- Firebase (used by Google, Alibaba, The New York Times) — enterprise reliability.
- Flutter (used by Google Pay, BMW, Alibaba) — proven performance at scale.
- Riverpod (the successor to Provider, endorsed by the Flutter team) — state management best practices.

**Security Compliance**
- All user passwords handled exclusively by Firebase Auth (never stored in Firestore or Storage).
- Role-based access control enforced at the database level via Firestore Security Rules.
- AWS-equivalent SLA via Firebase infrastructure (99.95% uptime guarantee).
- Image uploads size-limited and MIME-type validated in Storage Rules.
- No PII exposed in Firestore indexes — email addresses are protected by `isUser(uid)` rules.

**Code Quality Signals**
- Immutable data models via Freezed (prevents accidental state mutation).
- Sealed result types (`ApiResult`, `AuthResult`) prevent unhandled null states.
- `autoDispose` providers for admin collections — no memory leaks from unused data listeners.
- CI-ready: `flutter_lints` enforced, test infrastructure with `fake_cloud_firestore` and `firebase_auth_mocks`.

### 17.2 Market Validation

**TAM (Total Addressable Market)**
- 2.5 million+ domestic tourists travel to Northeast India annually (Ministry of Tourism, 2023).
- International tourist arrivals growing at ~12% YoY post-COVID.
- 780+ million smartphone users in India; 50 million+ active travel app users.

**SAM (Serviceable Addressable Market) — V1**
- Mizoram population: ~1.3 million.
- Estimated smartphone penetration: ~60% = 780,000 smartphone users.
- Travel-interested segment: ~15% = ~120,000 potential users.

**SOM (Serviceable Obtainable Market) — Year 1**
- Target: **10,000 registered users** in Mizoram by end of Year 1.
- Target conversion rate from downloads to registrations: 35%.
- Operator acquisition target: **50 active venture listings**.

**Competitive Gap**
| Platform | NE India Coverage | Local Tours | Gamification | Community Planning |
|---|---|---|---|---|
| Google Maps | Partial | No | No | No |
| TripAdvisor | Minimal | No | Badges only | No |
| MakeMyTrip | No tours | Hotel/flight only | No | No |
| **Xplooria** | **Full (Mizoram first)** | **Yes** | **Full system** | **Yes** |

No direct competitor addresses the Northeast India market with the depth that Xplooria provides.

### 17.3 Partnership Signals

- **Mizoram Tourism Department** — Official data partnership opportunity (spot data, event data).
- **Local Tour Operators** — Free platform = zero adoption friction; validated interest from regional operators.
- **University Partnerships** — Campus ambassador readiness at Mizoram University.
- **HillsTech** — Local technology company with regional credibility and relationships.

### 17.4 Platform Trust Features

- **One review per user per place** — Prevents review bombing and fake ratings.
- **Admin moderation queue** — All user contributions require admin approval before going live.
- **Contribution XP only on approval** — No incentive to spam contributions (reward only after admin verification).
- **Booking status trail** — Transparent booking lifecycle with admin notes prevents dispute ambiguity.
- **Visitor Guide Dos/Don'ts** — Cultural sensitivity built into the product (key for Northeast India tourism).

---

## 18. Version 1 Feature Completeness Matrix

| Feature Category | Feature | Status |
|---|---|---|
| **Authentication** | Email/password register | ✅ Complete |
| | Email/password login | ✅ Complete |
| | Password reset | ✅ Complete |
| | Auth state persistence | ✅ Complete |
| | Role-based redirect | ✅ Complete |
| **Discovery** | Tourist spots (browse + detail) | ✅ Complete |
| | Restaurants | ✅ Complete |
| | Cafes | ✅ Complete |
| | Hotels / Stay | ✅ Complete |
| | Homestays | ✅ Complete |
| | Adventure spots | ✅ Complete |
| | Shopping areas | ✅ Complete |
| | Events | ✅ Complete |
| | Ventures / Tour packages | ✅ Complete |
| | Global search | ✅ Complete |
| **Maps** | Interactive community map | ✅ Complete |
| | Category filtering (icon chips) | ✅ Complete |
| | Animated map pins | ✅ Complete |
| | Tap-to-detail | ✅ Complete |
| **Community** | Feed posts (text + image) | ✅ Complete |
| | Like / comment | ✅ Complete |
| | Dilemma A/B polls | ✅ Complete |
| | Bucket lists (rooms) | ✅ Complete |
| | Dares (group challenges) | ✅ Complete |
| | Dare photo proof | ✅ Complete |
| | Dare scratch cards | ✅ Complete |
| | Notifications | ✅ Complete |
| **Gamification** | XP system (11 actions) | ✅ Complete |
| | 10-level progression | ✅ Complete |
| | 22 badges | ✅ Complete |
| | Daily login streak + multiplier | ✅ Complete |
| | Leaderboard | ✅ Complete |
| | XP toast notification | ✅ Complete |
| **Bookings** | Browse ventures | ✅ Complete |
| | Select package + add-ons | ✅ Complete |
| | Booking review + submit | ✅ Complete |
| | "My Bookings" tracking | ✅ Complete |
| | Post-booking feedback | ✅ Complete |
| **Profile** | View stats and badges | ✅ Complete |
| | Edit profile (name, bio, photo) | ✅ Complete |
| | XP history feed | ✅ Complete |
| | Theme toggle (dark/light) | ✅ Complete |
| **Home** | Banner carousel (Firestore-driven) | ✅ Complete |
| | Category grid shortcuts | ✅ Complete |
| | Featured spots section | ✅ Complete |
| | Tour packages preview | ✅ Complete |
| | Visitor Guide card | ✅ Complete |
| | NE State picker | ✅ Complete |
| | AI Planner teaser (locked) | ✅ Complete |
| **Visitor Guide** | State guide (Mizoram) | ✅ Complete |
| | Dos / Don'ts | ✅ Complete |
| | Quick facts | ✅ Complete |
| **Admin — Content** | Manage 8 collection types | ✅ Complete |
| | Add/Edit/Delete listings | ✅ Complete |
| | CSV bulk import | ✅ Complete |
| | Manage ventures (12-section form) | ✅ Complete |
| | Banner management | ✅ Complete |
| | Visitor guide management | ✅ Complete |
| **Admin — Operations** | View all bookings | ✅ Complete |
| | Update booking status | ✅ Complete |
| | View venture feedback | ✅ Complete |
| | User management | ✅ Complete |
| | Analytics dashboard | ✅ Complete |
| | Moderation queue | ✅ Complete |
| **Upcoming (Roadmap)** | AI Travelling Planner | 🔒 Coming Soon |
| | Push notifications (FCM) | 🔲 Planned |
| | MezoPerks loyalty redemption | 🔒 Coming Soon |
| | Offline reading mode | 🔲 Planned |
| | Multi-state expansion | 🔲 Planned |

---

## 19. Appendix A: Complete Route Map

| Route | Path | Auth Required | Admin Only |
|---|---|---|---|
| Onboarding | `/onboarding` | No | — |
| Login | `/login` | No | — |
| Register | `/register` | No | — |
| Forgot Password | `/forgot-password` | No | — |
| Home | `/` | No | — |
| Spots List | `/spots` | No | — |
| Spot Detail | `/spots/:id` | No | — |
| Listings (tab) | `/listings?tab={n}` | No | — |
| Restaurant Detail | `/listings/restaurants/:id` | No | — |
| Hotel Detail | `/listings/hotels/:id` | No | — |
| Cafe Detail | `/listings/cafes/:id` | No | — |
| Stay Detail | `/listings/stay/:id` | No | — |
| Adventure Detail | `/listings/adventure/:id` | No | — |
| Shopping Detail | `/listings/shopping/:id` | No | — |
| Search | `/search` | No | — |
| Community (Feed/Map) | `/community` | No | — |
| Create Post | `/community/new` | **Yes** | — |
| Create Dilemma | `/community/dilemmas/new` | **Yes** | — |
| Create Bucket List | `/community/bucket-lists/new` | **Yes** | — |
| Bucket List Detail | `/community/bucket-lists/:id` | **Yes** | — |
| Edit Bucket List | `/community/bucket-lists/:id/edit` | **Yes** | — |
| Add Bucket Item | `/community/bucket-lists/:listId/add-item` | **Yes** | — |
| My Rooms | `/community/my-rooms` | **Yes** | — |
| Create Dare | `/community/dares/new` | **Yes** | — |
| Dare Detail | `/community/dares/:id` | **Yes** | — |
| Edit Dare | `/community/dares/:id/edit` | **Yes** | — |
| Add Challenge | `/community/dares/:dareId/add-challenge` | **Yes** | — |
| Submit Proof | `/community/dares/:dareId/challenges/:challengeId/proof` | **Yes** | — |
| Dare Rewards | `/dare-rewards` | **Yes** | — |
| Scratch Card | `/dare-rewards/cards/:cardId` | **Yes** | — |
| Notifications | `/notifications` | **Yes** | — |
| Dare Dashboard | `/profile/dare-dashboard` | **Yes** | — |
| Venture Detail | `/ventures/:id` | No | — |
| Booking Review | `/ventures/:id/booking-review` | **Yes** | — |
| My Bookings | `/my-bookings` | **Yes** | — |
| Event Detail | `/events/:id` | No | — |
| Reviews | `/reviews/:collection/:id` | No | — |
| Leaderboard | `/leaderboard` | No | — |
| Profile | `/profile` | **Yes** | — |
| Edit Profile | `/profile/edit` | **Yes** | — |
| Admin Shell | `/admin` | **Yes** | **Yes** |
| Admin Listings | `/admin` (tab) | **Yes** | **Yes** |
| Admin Add Listing | `/admin/listings/add/:collection` | **Yes** | **Yes** |
| Admin Edit Listing | `/admin/listings/edit/:collection/:docId` | **Yes** | **Yes** |
| Admin Add Venture | `/admin/ventures/add` | **Yes** | **Yes** |
| Admin Edit Venture | `/admin/ventures/edit/:docId` | **Yes** | **Yes** |

---

## 20. Appendix B: Dependencies Reference

### Production Dependencies Summary

| Category | Count | Key Packages |
|---|---|---|
| Core Framework | 2 | flutter, flutter_riverpod |
| Firebase | 5 | firebase_core, auth, firestore, storage, analytics |
| Navigation | 1 | go_router |
| Networking | 2 | dio, pretty_dio_logger |
| State/Serialization | 4 | riverpod_annotation, freezed_annotation, json_annotation, equatable |
| Local Storage | 2 | shared_preferences, flutter_secure_storage |
| UI Components | 10 | carousel_slider, iconsax, google_fonts, cached_network_image, shimmer, lottie, fl_chart, confetti, percent_indicator, smooth_page_indicator |
| Maps & Location | 4 | flutter_map, latlong2, geolocator, geocoding |
| Forms & Validation | 2 | flutter_form_builder, form_builder_validators |
| Media | 3 | image_picker, image_cropper, image |
| Bulk Upload | 2 | file_picker, csv |
| Utilities | 8 | intl, timeago, uuid, url_launcher, share_plus, connectivity_plus, package_info_plus, logger |
| Functional | 1 | dartz |

**Total Production Dependencies: 46+**

### Development Dependencies

| Package | Purpose |
|---|---|
| build_runner | Code generation orchestrator |
| freezed | Immutable model generation |
| json_serializable | JSON codec generation |
| riverpod_generator | Provider code generation |
| flutter_lints | Lint rules |
| flutter_launcher_icons | App icon generation |
| flutter_test | Unit + widget testing |
| mockito | Mock generation for tests |
| fake_cloud_firestore | In-memory Firestore for tests |
| firebase_auth_mocks | Firebase Auth mock for tests |

---

## Document Information

| Field | Value |
|---|---|
| Document Title | Xplooria V1 Product Documentation |
| Version | 1.0 |
| Date | April 2026 |
| Author | HillsTech Engineering Team |
| Platform | iOS & Android (Flutter) |
| Backend | Firebase (spotmizoram project) |
| Document Location | `/documentation/XPLOORIA_V1_DOCUMENTATION.md` |

---

*This document represents the complete feature, architecture, strategy, and technical reference for Xplooria Version 1. For questions regarding specific implementation details, refer to the source code at `lib/` or contact the HillsTech engineering team.*
