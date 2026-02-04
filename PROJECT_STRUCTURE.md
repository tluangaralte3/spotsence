# SpotMizoram Mobile - Project Structure

## 📁 Architecture Overview

This project follows **Clean Architecture** principles with clear separation of concerns across three main layers:

```
lib/
├── core/                    # Core utilities, constants, theme
├── features/                # Feature modules (Clean Architecture)
└── shared/                  # Shared widgets and utilities
```

## 🏗️ Clean Architecture Layers

### 1. **Domain Layer** (Business Logic)

- **Entities**: Pure Dart classes representing business objects
- **Repositories**: Abstract interfaces for data operations
- **Use Cases**: Business logic operations (to be implemented)

### 2. **Data Layer** (Data Management)

- **Models**: Data transfer objects with JSON serialization
- **Data Sources**: Remote (Firebase) and Local (Hive) implementations
- **Repositories**: Concrete implementations of domain repositories

### 3. **Presentation Layer** (UI)

- **Providers**: Riverpod state management
- **Pages**: Full-screen widgets
- **Widgets**: Reusable UI components

## 📂 Detailed Folder Structure

```
lib/
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # App-wide constants
│   │   └── enums.dart                # All enums (categories, status, etc.)
│   │
│   ├── theme/
│   │   ├── app_colors.dart           # Color palette
│   │   └── app_theme.dart            # Material 3 theme configuration
│   │
│   ├── utils/
│   │   ├── validators.dart           # Input validation
│   │   ├── formatters.dart           # Data formatting utilities
│   │   ├── location_helper.dart      # GPS & distance calculations
│   │   └── image_helper.dart         # Image picking & processing
│   │
│   ├── errors/
│   │   ├── failures.dart             # Failure types for error handling
│   │   └── exceptions.dart           # Exception classes
│   │
│   └── routes/
│       └── app_router.dart           # GoRouter configuration
│
├── features/
│   │
│   ├── spots/                        # Featured tourist spots
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── spot_entity.dart
│   │   │   └── repositories/
│   │   │       └── spots_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── pages/
│   │       │   └── spots_list_page.dart
│   │       └── widgets/
│   │
│   ├── restaurants/                  # Dining & food
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── restaurant_entity.dart
│   │   │   └── repositories/
│   │   │       └── restaurants_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── pages/
│   │       │   └── restaurants_list_page.dart
│   │       └── widgets/
│   │
│   ├── adventure/                    # Adventure & outdoor activities
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── adventure_spot_entity.dart
│   │   │   └── repositories/
│   │   │       └── adventure_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── pages/
│   │       │   └── adventure_list_page.dart
│   │       └── widgets/
│   │
│   ├── shopping/                     # Shopping destinations
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── shopping_area_entity.dart
│   │   │   └── repositories/
│   │   │       └── shopping_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── pages/
│   │       │   └── shopping_list_page.dart
│   │       └── widgets/
│   │
│   ├── auth/                         # Authentication & user management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       └── widgets/
│   │
│   ├── gamification/                 # Points, badges, leaderboard
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── badge_entity.dart
│   │   │   └── repositories/
│   │   │       └── gamification_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── profile/                      # User profile & settings
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── pages/
│   │       │   └── profile_page.dart
│   │       └── widgets/
│   │
│   └── home/                         # Home page (discovery hub)
│       └── presentation/
│           ├── pages/
│           │   └── home_page.dart
│           └── widgets/
│
├── shared/
│   └── widgets/                      # Reusable widgets across features
│
└── main.dart                         # App entry point
```

## 🔥 Firebase Collections (Matching Web)

The mobile app uses the **same Firebase collections** as the web platform:

| Collection       | Purpose               | Fields Matched           |
| ---------------- | --------------------- | ------------------------ |
| `spots`          | Tourist spots         | ✅ All fields from web   |
| `restaurants`    | Dining places         | ✅ All fields from web   |
| `adventureSpots` | Adventure activities  | ✅ All fields from web   |
| `shoppingAreas`  | Shopping destinations | ✅ All fields from web   |
| `users`          | User profiles         | ✅ Compatible with web   |
| `badges`         | Gamification badges   | ✅ Points system aligned |
| `contributions`  | User submissions      | ✅ Approval workflow     |
| `leaderboard`    | Rankings              | ✅ Same scoring system   |

## 🎨 Design System

### Colors (Tourism-Themed)

- **Primary**: Forest Green `#2E7D32` - Represents Mizoram's nature
- **Secondary**: Warm Orange `#FF6F00` - Cultural vibrancy
- **Feature Colors**:
  - Restaurants: Orange `#FF6B35`
  - Adventure: Emerald `#10B981`
  - Shopping: Indigo `#6366F1`

### Typography

- **Font**: Google Fonts - Poppins
- **Material 3** design system with adaptive components

### UI Patterns

- **Cards**: Rounded corners (`16dp`), elevated shadows
- **Horizontal Scrolls**: Matching web carousel behavior
- **Bottom Navigation**: 5 tabs (Home, Discover, Map, Rank, Profile)

## 📱 Key Features Alignment

### Web → Mobile Mapping

| Web Section             | Mobile Implementation            |
| ----------------------- | -------------------------------- |
| Featured Spots Carousel | Horizontal ListView with cards   |
| Trending Restaurants    | Horizontal scroll (same query)   |
| Adventure & Nature      | Horizontal scroll (same data)    |
| Shopping Destinations   | Horizontal scroll (same fields)  |
| Filters (Category tabs) | Chip filters / Segmented control |
| Detail pages            | Full-screen pages with routing   |

## 🛠️ Tech Stack

### State Management

- **Riverpod 2.4+** - Type-safe, compile-time state management

### Data & Serialization

- **Freezed** - Immutable models, copyWith, equality
- **JSON Serialization** - Auto-generated serializers

### Firebase

- **Authentication** - Email/Password, Google Sign-In
- **Firestore** - Real-time NoSQL database
- **Storage** - Image uploads
- **Analytics** - User behavior tracking

### Maps & Location

- **Google Maps Flutter** - Interactive maps
- **Geolocator** - GPS & distance calculations

### Local Storage

- **Hive** - Fast, lightweight NoSQL database
- **Shared Preferences** - Simple key-value storage

### Navigation

- **GoRouter** - Declarative routing with deep links

## 🚀 Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code (Freezed, JSON)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Firebase Setup

- Add `google-services.json` (Android) to `android/app/`
- Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`

### 4. Run the App

```bash
flutter run
```

## 📋 Development Workflow

### Creating a New Feature

1. **Domain Layer** (Business Logic)
   - Create entity in `features/{feature}/domain/entities/`
   - Create repository interface in `features/{feature}/domain/repositories/`

2. **Data Layer** (Data Access)
   - Create model in `features/{feature}/data/models/`
   - Create data source in `features/{feature}/data/datasources/`
   - Implement repository in `features/{feature}/data/repositories/`

3. **Presentation Layer** (UI)
   - Create provider in `features/{feature}/presentation/providers/`
   - Create page in `features/{feature}/presentation/pages/`
   - Create widgets in `features/{feature}/presentation/widgets/`

### Code Generation

After modifying Freezed models or adding JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🧪 Testing Strategy

- **Unit Tests**: Domain entities, utilities, validators
- **Widget Tests**: UI components, pages
- **Integration Tests**: Complete user flows
- **Firebase Emulator**: Local testing without production data

## 🔐 Security

- Firebase Security Rules (matches web)
- Input validation on all forms
- Secure token storage
- Role-based access control (RBAC)

## 📊 Performance

- Image caching with `cached_network_image`
- Lazy loading for lists
- Offline support with Hive
- Debounced search queries
- Optimized Firestore queries (limit, orderBy)

## 🎯 Next Steps

1. **Implement Data Layer**
   - Firebase data sources
   - Hive local storage
   - Repository implementations

2. **Build UI Components**
   - Spot cards
   - Restaurant cards
   - Filter chips
   - Loading states

3. **Add Firebase Integration**
   - Authentication flow
   - Firestore queries
   - Image uploads

4. **Gamification Features**
   - Points tracking
   - Badge system
   - Leaderboard

5. **Maps Integration**
   - Spot markers
   - Directions
   - Nearby search

---

**Built with ❤️ for Mizoram Tourism**  
**Version**: 1.0.0  
**Platform**: Flutter 3.10+
