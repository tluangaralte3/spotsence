# SpotMizoram Web → Mobile Overview

> Shared understanding of the current web implementation so the mobile app can mirror features, data, and UX patterns.

---

## 1. High-Level Concept

SpotMizoram is a **unified tourism platform** where web and mobile are two clients talking to the **same Firebase backend** (Firestore + Storage + Auth). The goal is that:

- Both clients read/write **the same collections**
- Listing types, fields, and status flags stay in sync
- User-facing flows (browse → view details → rate/review → save/plan) feel consistent

This document focuses on what the **web app already does** so the **mobile app can align**.

---

## 2. Backend & Data Model (Shared Contract)

### 2.1 Core Technologies

- **Database**: Firebase Firestore
- **Storage**: Firebase Storage (images per collection)
- **Auth**: Firebase Authentication (planned/partially integrated)
- **Frontend (web)**: Next.js App Router (TypeScript, React), client components for listing sections

### 2.2 Key Collections (Web Uses Today)

These are the main collections the web frontend already reads/writes and that mobile should reuse:

1. `spots`
   - Used by: `FeaturedSpotsSection` (home page)
   - Purpose: General tourism spots (mountains, waterfalls, viewpoints, cultural sites, etc.)
   - Key fields (partial):
     - `id` (doc id)
     - `name: string`
     - `category: string` (e.g. `Mountains`, `Waterfalls`, `Cultural Sites`, `Viewpoints`, `Adventure`)
     - `locationAddress?: string`
     - `imagesUrl: string[]` (main images)
     - `placeStory?: string`
     - `averageRating?: number`
     - `popularity?: number` (0–10 scale)
     - `featured: boolean`
     - `status: 'Approved' | 'Pending' | 'Rejected'` (web filters by `Approved`)

2. `restaurants`
   - Used by: `TrendingRestaurantsSection`
   - Purpose: Food places and dining experiences
   - Key fields:
     - `id`
     - `name: string`
     - `description: string`
     - `location: string`
     - `images: string[]`
     - `rating: number`
     - `priceRange: '$' | '$$' | '$$$' | '$$$$'`
     - `cuisineTypes: string[]`
     - `openingHours: string`
     - `hasDelivery: boolean`
     - `hasReservation: boolean`

3. `adventureSpots`
   - Used by: `AdventureSpotsSection`
   - Purpose: Trekking, hikes, nature trips, adventure locations
   - Key fields:
     - `id`
     - `name: string`
     - `description: string`
     - `category: string` (e.g. `Trekking`, `Wildlife`, etc.)
     - `location: string`
     - `images: string[]`
     - `rating: number`
     - `difficulty: 'Easy' | 'Moderate' | 'Hard' | 'Expert' | string`
     - `duration: string` (e.g. `3–4 hours`)
     - `bestSeason: string`
     - `activities: string[]` (top 3 shown)
     - `isPopular: boolean`

4. `shoppingAreas`
   - Used by: `ShoppingAreasSection`
   - Purpose: Markets, malls, street shopping, local bazaars
   - Key fields:
     - `id`
     - `name: string`
     - `description: string`
     - `type: string` (e.g. `Market`, `Mall`, etc.)
     - `location: string`
     - `images: string[]`
     - `rating: number`
     - `openingHours: string`
     - `products: string[]`
     - `priceRange: '$' | '$$' | '$$$' | '$$$$'`
     - `hasParking: boolean`
     - `acceptsCards: boolean`
     - `hasDelivery: boolean`
     - `isPopular: boolean`

> **Mobile note**: Reuse these field names & types when consuming Firestore to avoid branching logic between web and mobile.

---

## 3. Current Web UX Flows (That Mobile Should Mirror)

### 3.1 Home Page Overview

The web home page is the **main discovery hub**. It includes:

- Hero + intro sections
- **Featured spots carousel** (from `spots`)
- **Trending restaurants** horizontal list
- **Adventure & nature spots** horizontal list
- **Shopping destinations** horizontal list
- Events, calendar, and other supporting sections

Each of the 3 new sections uses **the same design pattern** as the `FeaturedSpotsSection` so users feel continuity.

### 3.2 Featured Spots (`spots` collection)

Component: `FeaturedSpotsSection`

- Horizontal **scrollable cards** with left/right arrow buttons
- Filter tabs (e.g. `Popular nearby`, `Mountains`, `Waterfalls`, `Cultural Sites`, `Viewpoints`, `Adventure`)
- Each card shows:
  - Image (from `imagesUrl[0]` or gradient fallback)
  - Name + location/category
  - `averageRating` (if present)
  - Short `placeStory` or a generated fallback description
  - `category` and `popularity` score
- Click → navigates to `/spots/[id]` detail page (web side)

**Mobile alignment idea**:

- Use a horizontal card carousel with the same fields
- Keep category filters at the top (chips or segmented control)
- Use the same `category` strings for filtering

### 3.3 Trending Restaurants (`restaurants` collection)

Component: `TrendingRestaurantsSection`

- Data source: `restaurants` ordered by `rating desc`, limited to 12
- Horizontal scrollable card list with arrows
- Each card:
  - Image (`images[0]`)
  - Price badge using `priceRange` (`$` → cheap, `$$$$` → premium)
  - Rating (0–5, `rating` number)
  - Name + location
  - Description preview (2 lines)
  - Primary cuisine (first item from `cuisineTypes`)
  - Quick feature icons:
    - Delivery (truck icon / 🚚)
    - Reservation (calendar icon / 📅)
- Web navigation: `/restaurants/[id]`

**Mobile alignment idea**:

- A "Trending Restaurants" row on home, or a full screen that reuses the same query
- Filter or sort by rating/price if needed
- Respect the same rating scale and price buckets

### 3.4 Adventure & Nature (`adventureSpots` collection)

Component: `AdventureSpotsSection`

- Data source: `adventureSpots` ordered by `rating desc`, limit 12
- Horizontal scroll pattern (same as restaurants)
- Each card:
  - Image (`images[0]`)
  - Popular badge when `isPopular = true`
  - Name + location
  - Rating value
  - Short description
  - Bottom row:
    - `category` (displayed in primary color)
    - Combined text: `difficulty • duration`

**Mobile alignment idea**:

- Highlight difficulty with color (Easy → green, Hard → red) if you want to mirror web styling
- Use the same `difficulty` text + icons in your UI

### 3.5 Shopping Destinations (`shoppingAreas` collection)

Component: `ShoppingAreasSection`

- Data source: `shoppingAreas` ordered by `rating desc`, limit 12
- Horizontal scrollable list
- Each card:
  - Image (`images[0]`)
  - Optional `Popular` badge (from `isPopular`)
  - Name + location
  - Rating
  - Description preview
  - Bottom row:
    - `type` (market/mall/street, etc.)
    - Feature icons: cards (💳), delivery (🚚), parking (🅿️)

**Mobile alignment idea**:

- Use similar icons on mobile for mental mapping
- Reuse `type` to filter or group on a shopping discovery screen

---

## 4. State Management & Firebase Usage

The web sections are optimized to **avoid unnecessary Firestore reads** and to provide a **predictable UX**:

### 4.1 Fetch Pattern (All Three Sections)

For `TrendingRestaurantsSection`, `AdventureSpotsSection`, `ShoppingAreasSection`:

- Use `useEffect` with an internal `hasFetched` ref:
  - Prevents multiple fetches on re-renders
  - Ensures one-time Firestore reads per mount
- State per section:
  - `items[]` (restaurants/spots/areas)
  - `loading: boolean`
  - `error: string | null`

### 4.2 Loading / Error / Empty States

Each section supports three clear states:

1. **Loading**
   - Shows a centered card with a spinner and "Loading..." text
2. **Error**
   - When Firestore fails, an error card appears with an icon and the error message
   - Example: `Failed to load restaurants. Please try again later.`
3. **Empty**
   - When the query succeeds but returns no items, a friendly empty state is shown

**Mobile recommendation**:

- Reuse the same 3-state model:
  - `loading`, `error`, `data[]`
- If you use React Native or Flutter, keep the same logical states so behavior matches web.

---

## 5. Design System & Visual Language

The web UI establishes a visual system that mobile can mirror:

### 5.1 Cards

- Rounded corners: `rounded-2xl`
- Shadow: `shadow-md` default, `hover:-translate-y-1 hover:shadow-xl` on hover
- Image area: `h-64`, full-width, cover

### 5.2 Badges & Pills

- Shape: `rounded-full`
- Types:
  - Category/type labels (e.g. spot category, shopping type)
  - Popular/featured badges
  - Price range badges
- Colors:
  - Restaurants: orange theme
  - Adventure: emerald/green theme
  - Shopping: indigo/purple theme

### 5.3 Icon Language

- Uses `lucide-react` for web; mobile can use similar iconography:
  - Map/location → map pin
  - Rating → star
  - Time/duration → clock
  - Adventure indicators → compass, mountain
  - Shopping → bag, credit card, truck, parking

**Mobile recommendation**:

- Keep the same colors & icon semantics so users immediately recognize sections across platforms.

---

## 6. Navigation & Deep Links (Web)

- Featured spots: `/spots/[id]`
- Restaurants: `/restaurants/[id]`
- Adventure: `/adventure/[id]` (planned pattern)
- Shopping: `/shopping/[id]` (planned pattern)

**Mobile alignment idea**:

- Mirror route structure in your navigation stack:
  - `SpotsStack → SpotDetail(id)`
  - `RestaurantsStack → RestaurantDetail(id)`
  - etc.
- If using dynamic links / deep links later, reuse the same slugs so a single link can open in web or mobile.

---

## 7. Admin & Content Management (Impact on Mobile)

On web, an **admin/management interface** exists (or is being built) to:

- Create and update documents in:
  - `restaurants`
  - `adventureSpots`
  - `shoppingAreas`
  - `spots` and others
- Upload multiple images per listing (stored in Firebase Storage, paths grouped per collection)
- Control flags like:
  - `featured`
  - `status` (for approval)
  - `isPopular`

**What mobile should assume**:

- Data is treated as **source of truth** from Firestore
- Mobile does **not** need its own CMS; it should **consume** what web/admin writes
- Mobile should respect flags such as `featured`, `status`, `isPopular` when filtering or highlighting

---

## 8. How Mobile Can Extend This

Given the current web implementation, mobile can:

1. **Reuse all listing queries**
   - Same collections
   - Same orderBy (`rating desc`)
   - Same limits (e.g. 12 items for horizontal lists)

2. **Maintain consistent sections on home**
   - Featured spots
   - Trending restaurants
   - Adventure & nature
   - Shopping destinations

3. **Add mobile-only powers while staying in sync**
   - Offline caching of Firestore reads
   - Location-aware sorting (nearest first)
   - Native maps integration with same `locationAddress`/coordinates
   - Push notifications for popular or newly featured spots

4. **Share future AI/Chat layer**
   - When the AI companion (`MizoMate AI`) is plugged into a shared backend, both web and mobile can call the same APIs to:
     - Discover spots
     - Generate itineraries
     - Recommend restaurants/shopping

---

## 9. Summary for Mobile Team

- The **web app is the reference implementation** for:
  - Data shapes (Firestore collections & fields)
  - Sectioning of content (featured, trending, adventure, shopping)
  - Visual grouping (colors, icons, card layouts)
- The **backend is already shared**:
  - No separate APIs required for mobile; Firestore + Storage are the contract
- Mobile should aim to:
  - Reuse the same collections and keys
  - Preserve the same UX flows (browse → detail)
  - Use consistent naming (categories, difficulty, price levels)

If the mobile team follows this doc, the user experience will feel like **one unified SpotMizoram ecosystem**, regardless of whether the user is on web or mobile.

---

**Last Updated (Web → Mobile Overview)**: February 2026
