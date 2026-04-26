# Xplooria — Data Models Reference

> **Source:** `lib/models/`  
> **Last updated:** April 2026  
> All models map directly to Firestore collections unless stated otherwise.

---

## Table of Contents

1. [User Model](#1-user-model)
2. [Spot Model](#2-spot-model)
3. [Listing Models](#3-listing-models)
4. [Event Model](#4-event-model)
5. [Tour Venture Models](#5-tour-venture-models)
6. [Booking Model](#6-booking-model)
7. [Community Models](#7-community-models)
8. [Bucket List Models](#8-bucket-list-models)
9. [Dare Models](#9-dare-models)
10. [Gamification Models](#10-gamification-models)
11. [Banner Model](#11-banner-model)
12. [Visitor Guide Model](#12-visitor-guide-model)
13. [Admin Model](#13-admin-model)

---

## 1. User Model

**File:** `user_model.dart`  
**Firestore collection:** `users/{uid}`

### `UserModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firebase UID |
| `email` | `String` | User email address |
| `displayName` | `String` | Public display name |
| `photoURL` | `String?` | Profile photo URL |
| `bio` | `String?` | Short user bio |
| `location` | `String?` | User's stated location |
| `role` | `int` | `0` = admin, `1` = regular user |
| `points` | `int` | Total XP points earned |
| `level` | `int` | Current level (1–10) |
| `levelTitle` | `String` | e.g. "Explorer", "Guardian" |
| `badges` | `List<String>` | Badge IDs visible on profile |
| `badgesEarned` | `List<String>` | All badge IDs ever earned |
| `contributionsCount` | `int` | Spots submitted for review |
| `ratingsCount` | `int` | Reviews written |
| `photosCount` | `int` | Community photos uploaded |
| `dilemmasCreated` | `int` | Dilemmas posted |
| `dilemmasVoted` | `int` | Dilemmas voted on |
| `bucketListsCreated` | `int` | Bucket lists created |
| `bucketItemsCompleted` | `int` | Bucket items checked off |
| `loginStreak` | `int` | Current consecutive-day streak |
| `longestStreak` | `int` | All-time best streak |
| `lastLogin` | `DateTime?` | Date of most recent login |
| `bookmarks` | `List<String>` | Bookmarked spot/listing IDs |
| `createdAt` | `String` | ISO-8601 account creation date |

### Level Thresholds

| Level | Title | Min Points |
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

### Derived Helpers

| Helper | Type | Description |
|---|---|---|
| `isAdmin` | `bool` | `role == 0` |
| `isSuperAdminEmail` | `bool` | Email matches `hillstechadmin@xplooria.com` |
| `pointsToNextLevel` | `int` | XP gap to next level |
| `xpToNextLevel` | `int` | Alias for `pointsToNextLevel` |
| `levelProgress` | `double` | 0.0–1.0 progress bar value |

---

## 2. Spot Model

**File:** `spot_model.dart`  
**Firestore collection:** `spots/{id}`

### Supporting classes

#### `EntryFee`

| Field | Type |
|---|---|
| `type` | `String` (e.g. "Indian", "Foreigner") |
| `amount` | `String` (e.g. "₹50") |

#### `SpotRating`

| Field | Type |
|---|---|
| `userId` | `String` |
| `userName` | `String` |
| `rating` | `double` |
| `timestamp` | `String` |

#### `SpotComment`

| Field | Type |
|---|---|
| `userId` | `String` |
| `userName` | `String` |
| `comment` | `String` |
| `timestamp` | `String` |

### `SpotModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `name` | `String` | Spot name |
| `category` | `String` | e.g. "Waterfall", "Lake" |
| `locationAddress` | `String` | Human-readable address |
| `district` | `String` | Mizoram district |
| `averageRating` | `double` | Computed mean rating |
| `popularity` | `double` | Popularity score |
| `ratingsCount` | `int` | Number of ratings |
| `imagesUrl` | `List<String>` | All image URLs |
| `featured` | `bool` | Pinned on homepage |
| `status` | `String` | `"Published"` / `"Draft"` |
| `views` | `int` | Total view count |
| `distance` | `String?` | Distance from city |
| `bestSeason` | `String?` | Best visiting season |
| `openingHours` | `String?` | Visiting hours |
| `facilities` | `String?` | Available facilities |
| `accessibility` | `String?` | Accessibility notes |
| `safetyNotes` | `String?` | Safety information |
| `officialSourceUrl` | `String?` | Government / official link |
| `alternateNames` | `List<String>` | Local name variants |
| `placeStory` | `String?` | History / narrative |
| `thingsToDo` | `List<String>` | Activities at the spot |
| `entryFees` | `List<EntryFee>` | Tiered entry fees |
| `addOns` | `List<String>` | Available add-ons |
| `ratings` | `List<SpotRating>` | Individual ratings |
| `comments` | `List<SpotComment>` | User comments |
| `tags` | `List<String>` | Searchable tags |
| `latitude` | `double?` | GPS latitude |
| `longitude` | `double?` | GPS longitude |

### Derived Helpers

| Helper | Description |
|---|---|
| `heroImage` | First image URL or empty string |

---

## 3. Listing Models

**File:** `listing_models.dart`  
**Firestore collections:** `restaurants`, `hotels`, `cafes`, `homestays`, `adventureSpots`, `shoppingAreas`

### `RestaurantModel`

| Field | Type |
|---|---|
| `id` | `String` |
| `name` | `String` |
| `description` | `String` |
| `location` | `String` |
| `images` | `List<String>` |
| `rating` | `double` |
| `priceRange` | `String` (`$` / `$$` / `$$$` / `$$$$`) |
| `cuisineTypes` | `List<String>` |
| `openingHours` | `String` |
| `hasDelivery` | `bool` |
| `hasReservation` | `bool` |
| `district` | `String` |
| `contactPhone` | `String` |
| `website` | `String` |
| `ratingsCount` | `int` |
| `latitude` | `double?` |
| `longitude` | `double?` |

### `HotelModel`

| Field | Type |
|---|---|
| `id` | `String` |
| `name` | `String` |
| `description` | `String` |
| `location` | `String` |
| `images` | `List<String>` |
| `rating` | `double` |
| `priceRange` | `String` |
| `amenities` | `List<String>` |
| `roomTypes` | `List<String>` |
| `hasRestaurant` | `bool` |
| `hasWifi` | `bool` |
| `hasParking` | `bool` |
| `hasPool` | `bool` |
| `district` | `String` |
| `contactPhone` | `String` |
| `website` | `String` |
| `ratingsCount` | `int` |

### `CafeModel`

Same base structure as `RestaurantModel` with café-specific fields (specialty coffees, has workspace, etc.)

### `HomestayModel`

Similar to `HotelModel` with homestay-specific fields (host name, max guests, meal options, etc.)

### `AdventureSpotModel`

Similar to `SpotModel` but scoped to the `adventureSpots` collection with additional fields for difficulty, gear requirements, and guide availability.

### `ShoppingAreaModel`

Fields for shopping areas including store categories, payment methods accepted, and opening hours.

### `ListingCategory` Enum

Enum used by the tabbed listings screen to switch between collection types.

| Value | Collection |
|---|---|
| `restaurant` | `restaurants` |
| `hotel` | `hotels` |
| `cafe` | `cafes` |
| `homestay` | `homestays` |
| `adventure` | `adventureSpots` |
| `shopping` | `shoppingAreas` |

---

## 4. Event Model

**File:** `event_model.dart`  
**Firestore collection:** `events/{id}`

### `EventModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `title` | `String` | Event name |
| `description` | `String` | Full description |
| `location` | `String` | Venue / place |
| `date` | `DateTime?` | Start date |
| `endDate` | `DateTime?` | End date (optional) |
| `time` | `String` | Start time string, e.g. "10:00 AM" |
| `endTime` | `String` | End time string |
| `attendees` | `int` | Registered attendee count |
| `category` | `String` | Event category |
| `imageUrl` | `String` | Banner image URL |
| `type` | `String` | `festival` / `cultural` / `adventure` / `personal` |
| `status` | `String` | `Published` / `Draft` |
| `tags` | `List<String>` | Searchable tags |
| `featured` | `bool` | Pinned featured event |
| `createdBy` | `String` | Creator UID |
| `createdAt` | `DateTime?` | Creation timestamp |
| `updatedAt` | `DateTime?` | Last update timestamp |
| `ticketingEnabled` | `bool` | Whether tickets can be booked |
| `ticketPrice` | `double?` | Price per ticket (null = free) |
| `ticketCurrency` | `String` | Currency code (default `INR`) |
| `totalTickets` | `int?` | Max capacity (null = unlimited) |
| `ticketsBooked` | `int` | Seats already taken |
| `ticketingDeadline` | `DateTime?` | Last date to book |

### Derived Helpers

| Helper | Type | Description |
|---|---|---|
| `isUpcoming` | `bool` | Event date is in the future |
| `isOngoing` | `bool` | Currently happening (between start and end date) |
| `isPast` | `bool` | Event has ended |
| `ticketsRemaining` | `int?` | `totalTickets - ticketsBooked` |
| `isSoldOut` | `bool` | No tickets remaining |
| `isFree` | `bool` | `ticketPrice` is null or 0 |
| `canBookTicket` | `bool` | Ticketing enabled, not sold out, not past deadline |

---

## 5. Tour Venture Models

**File:** `tour_venture_models.dart`  
**Firestore collection:** `adventureSpots/{id}`

### Enums

#### `PackageCategory`

Local activity package types: `birdWatching`, `fishing`, `hiking`, `cycling`, `kayaking`, `camping`, `photography`, `cultural`, `wildlife`, `trekking`, `rockClimbing`, `riverRafting`, `zipLining`, and more.

#### `DifficultyLevel`

`easy` / `moderate` / `hard` / `expert`

#### `PackageSeason`

`allYear` / `summer` / `winter` / `monsoon` / `spring` / `autumn`

#### `MedalTier`

`bronze` / `silver` / `gold` / `platinum`

### Supporting classes

#### `PricingTier`

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Tier name (e.g. "Basic", "Premium") |
| `price` | `double` | Price per person |
| `description` | `String` | What's included |
| `maxPersons` | `int?` | Group limit |

#### `VentureAddon`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique ID |
| `name` | `String` | Add-on name |
| `price` | `double` | Extra cost |
| `description` | `String` | What's provided |
| `imageUrl` | `String?` | Icon/photo |

#### `RentalPartner`

| Field | Type |
|---|---|
| `name` | `String` |
| `phone` | `String` |
| `location` | `String` |
| `equipment` | `List<String>` |
| `priceRange` | `String` |

#### `VentureChallenge`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Challenge ID |
| `title` | `String` | Challenge name |
| `description` | `String` | What to do |
| `xpReward` | `int` | XP awarded on completion |
| `medalTier` | `MedalTier` | Medal awarded |
| `requiresProof` | `bool` | Photo proof required |
| `order` | `int` | Display order |

#### `VentureAchievementMedal`

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `description` | `String` |
| `tier` | `MedalTier` |
| `imageUrl` | `String?` |

#### `ScheduleSlot`

| Field | Type |
|---|---|
| `time` | `String` |
| `activity` | `String` |
| `description` | `String?` |
| `duration` | `String?` |

#### `OperatorInfo`

| Field | Type |
|---|---|
| `name` | `String` |
| `phone` | `String` |
| `whatsapp` | `String` |
| `email` | `String` |
| `bio` | `String?` |
| `photoUrl` | `String?` |

### `TourVentureModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `title` | `String` | Package title |
| `description` | `String` | Full description |
| `category` | `PackageCategory` | Activity type |
| `location` | `String` | Location string |
| `district` | `String` | Mizoram district |
| `heroImage` | `String` | Primary banner image |
| `images` | `List<String>` | Additional photos |
| `difficulty` | `DifficultyLevel` | Difficulty rating |
| `season` | `PackageSeason` | Best season |
| `duration` | `String` | e.g. "3 Days 2 Nights" |
| `groupSize` | `int` | Max participants |
| `basePrice` | `double` | Starting price |
| `pricingTiers` | `List<PricingTier>` | Tiered pricing |
| `addons` | `List<VentureAddon>` | Optional extras |
| `rentalPartners` | `List<RentalPartner>` | Equipment partners |
| `challenges` | `List<VentureChallenge>` | In-venture challenges |
| `medals` | `List<VentureAchievementMedal>` | Completion medals |
| `schedule` | `List<ScheduleSlot>` | Itinerary |
| `operator` | `OperatorInfo` | Contact details |
| `includes` | `List<String>` | What's included |
| `excludes` | `List<String>` | What's not included |
| `tags` | `List<String>` | Search tags |
| `latitude` | `double?` | GPS latitude |
| `longitude` | `double?` | GPS longitude |
| `rating` | `double` | Average rating |
| `ratingsCount` | `int` | Total ratings |
| `featured` | `bool` | Homepage featured |
| `status` | `String` | `Published` / `Draft` |
| `createdAt` | `DateTime?` | Creation timestamp |
| `updatedAt` | `DateTime?` | Last update timestamp |

### `VentureRegistration`

Sub-collection: `adventureSpots/{id}/registrations`

| Field | Type |
|---|---|
| `userId` | `String` |
| `userName` | `String` |
| `userEmail` | `String` |
| `selectedTier` | `String` |
| `selectedAddons` | `List<Map>` |
| `personCount` | `int` |
| `grandTotal` | `double` |
| `status` | `String` |
| `createdAt` | `DateTime` |

### `VentureFeedback`

Sub-collection: `adventureSpots/{id}/feedback`

| Field | Type |
|---|---|
| `userId` | `String` |
| `rating` | `double` |
| `comment` | `String` |
| `createdAt` | `DateTime` |

---

## 6. Booking Model

**File:** `booking_model.dart`  
**Firestore collection:** `venture_bookings/{id}`

### `BookingStatus` Enum

| Value | Label |
|---|---|
| `pending` | Pending |
| `confirmed` | Confirmed |
| `cancelled` | Cancelled |
| `completed` | Completed |

### `VentureBooking`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `userId` | `String` | Booker's UID |
| `userName` | `String` | Booker's name |
| `userEmail` | `String` | Booker's email |
| `ventureId` | `String` | Linked venture ID |
| `ventureTitle` | `String` | Venture name |
| `heroImage` | `String` | Venture banner image |
| `category` | `String` | Activity category |
| `location` | `String` | Venue location |
| `operatorName` | `String` | Operator's name |
| `operatorPhone` | `String` | Contact phone |
| `operatorWhatsapp` | `String` | WhatsApp number |
| `operatorEmail` | `String` | Operator email |
| `selectedPackageName` | `String?` | Chosen pricing tier |
| `selectedPackageDesc` | `String?` | Tier description |
| `pricePerPerson` | `double?` | Per-person price |
| `personCount` | `int` | Number of participants |
| `selectedAddons` | `List<Map>` | Chosen add-ons with prices |
| `addonSubtotal` | `double` | Sum of add-on costs |
| `grandTotal` | `double` | Total payable amount |
| `status` | `BookingStatus` | Current booking status |
| `adminNote` | `String?` | Admin message on status change |
| `hasFeedback` | `bool` | Whether feedback was submitted |
| `createdAt` | `DateTime` | Booking creation time |
| `updatedAt` | `DateTime` | Last status update time |

---

## 7. Community Models

**File:** `community_models.dart`  
**Firestore collection:** `community_posts/{id}`

### `PostComment`

| Field | Type |
|---|---|
| `id` | `String` |
| `userId` | `String` |
| `userName` | `String` |
| `comment` | `String` |
| `createdAt` | `String` |

### `CommunityPost`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `userId` | `String` | Author's UID |
| `userName` | `String` | Author's display name |
| `userPhoto` | `String?` | Author's photo URL |
| `type` | `String` | `post` / `review` / `tip` / `question` |
| `content` | `String` | Post body text |
| `images` | `List<String>` | Attached image URLs |
| `spotId` | `String?` | Linked spot ID |
| `spotName` | `String?` | Linked spot name |
| `location` | `String?` | Textual location tag |
| `likes` | `List<String>` | UIDs of users who liked |
| `comments` | `List<PostComment>` | Post comments |
| `createdAt` | `String` | ISO-8601 timestamp |

**Derived helpers:** `likeCount`, `commentCount`, `isLikedBy(uid)`, `toggleLike(uid)`

### `DilemmaOption`

| Field | Type | Description |
|---|---|---|
| `spotId` | `String?` | Linked spot ID |
| `name` | `String` | Option label |
| `category` | `String?` | `spot` / `cafe` / `restaurant` / `hotel` / `homestay` |
| `imageUrl` | `String?` | Option image |
| `district` | `String?` | District |

### `Dilemma`

**Firestore collection:** `dilemmas/{id}`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `question` | `String` | The dilemma question |
| `optionA` | `DilemmaOption` | First choice |
| `optionB` | `DilemmaOption` | Second choice |
| `votesA` | `List<String>` | UIDs who voted A |
| `votesB` | `List<String>` | UIDs who voted B |
| `authorId` | `String` | Creator UID |
| `authorName` | `String` | Creator display name |
| `authorPhoto` | `String?` | Creator photo |
| `status` | `String` | `active` / `closed` |
| `expiresAt` | `DateTime?` | Auto-close date (null = no deadline) |
| `createdAt` | `DateTime` | Creation timestamp |

**Derived helpers:** `totalVotes`, `percentA`, `percentB`, `isExpired`, `isActive`, `userVote(uid)`

### `BucketListPlace` *(legacy community model)*

| Field | Type |
|---|---|
| `spotId` | `String` |
| `spotName` | `String` |
| `category` | `String` |
| `visited` | `bool` |

---

## 8. Bucket List Models

**File:** `bucket_list_models.dart`  
**Firestore collection:** `bucket_lists/{id}`

### Constants

| Constant | Value | Description |
|---|---|---|
| `kFreeRoomCap` | `5` | Max free bucket list rooms per user |
| `kConnectUnlockDays` | `10` | Days in room before Connect is unlocked |
| `kPokeUnlockDays` | `20` | Days in room before Poke is unlocked |

### `BucketCategory` Enum

| Value | Label |
|---|---|
| `spot` | Tourist Spot |
| `restaurant` | Restaurant |
| `cafe` | Café |
| `hotel` | Hotel |
| `homestay` | Homestay |
| `adventure` | Adventure |
| `shopping` | Shopping |
| `event` | Event |
| `other` | Other |

### `BucketItem`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Item ID |
| `name` | `String` | Place / activity name |
| `imageUrl` | `String?` | Photo |
| `category` | `BucketCategory` | Category enum |
| `customCategory` | `String?` | Used when category is `other` |
| `listingId` | `String?` | Linked Firestore doc ID |
| `listingType` | `String?` | `spot` / `restaurant` / `cafe` / … |
| `note` | `String?` | Personal note |
| `isChecked` | `bool` | Completed flag |
| `checkedByUserId` | `String?` | Who marked it done |
| `checkedByUserName` | `String?` | Their display name |
| `checkedAt` | `DateTime?` | When it was checked |

### `MemberRole` / `MemberStatus` Enums

**MemberRole:** `host` / `member`  
**MemberStatus:** `pending` / `approved` / `declined`

### `BucketMember`

| Field | Type | Description |
|---|---|---|
| `userId` | `String` | Member UID |
| `userName` | `String` | Display name |
| `userPhoto` | `String?` | Photo URL |
| `role` | `MemberRole` | `host` or `member` |
| `status` | `MemberStatus` | Approval status |
| `joinedAt` | `DateTime` | Join request date |
| `approvedAt` | `DateTime?` | Approval date (for feature unlocks) |
| `strikes` | `int` | Violation strikes (0–3; 3 = auto-removed) |
| `contactShared` | `bool` | Opted to share contact within room |

### `RoomPokeModel`

Sub-collection: `bucket_lists/{id}/pokes`

| Field | Type |
|---|---|
| `id` | `String` |
| `fromUserId` | `String` |
| `fromUserName` | `String` |
| `toUserId` | `String` |
| `message` | `String?` |
| `createdAt` | `DateTime` |

### `RoomReportModel`

Sub-collection: `bucket_lists/{id}/reports`

| Field | Type |
|---|---|
| `id` | `String` |
| `reporterId` | `String` |
| `reportedUserId` | `String` |
| `reason` | `String` |
| `createdAt` | `DateTime` |

### `BucketVisibility` Enum

`public` / `private`

### `BucketListModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `title` | `String` | Room name |
| `description` | `String?` | Room description |
| `hostId` | `String` | Creator UID |
| `hostName` | `String` | Creator name |
| `items` | `List<BucketItem>` | All bucket items |
| `members` | `List<BucketMember>` | Participants |
| `maxMembers` | `int` | Max allowed members |
| `visibility` | `BucketVisibility` | `public` or `private` |
| `joinCode` | `String` | Invite code for private rooms |
| `tags` | `List<String>` | Discovery tags |
| `createdAt` | `DateTime` | Creation timestamp |
| `updatedAt` | `DateTime` | Last update timestamp |

---

## 9. Dare Models

**File:** `dare_models.dart`  
**Firestore collection:** `dares/{id}`

### Constants

| Constant | Value | Description |
|---|---|---|
| `kFreeDareCap` | `5` | Max free dares a user can host |

### `DareCategory` Enum

| Value | Label | Color |
|---|---|---|
| `adventure` | Adventure | `#FF6B35` |
| `foodRating` | Food Rating | `#FF9F1C` |
| `photography` | Photography | `#6C63FF` |
| `wildlife` | Wildlife | `#2EC4B6` |
| `nightCamp` | Night Camp | `#5C6BC0` |
| `exploration` | Exploration | `#00E5A0` |
| `fitness` | Fitness | `#E71D36` |
| `social` | Social | `#EC407A` |
| `creative` | Creative | `#9B5DE5` |
| `travel` | Travel | `#0077B6` |
| `other` | Other | `#8892A4` |

### `DareVisibility` Enum

`public` / `private`

### `DareChallengeType` Enum

`appListing` / `custom`

### `MedalType` Enum

| Value | Label | Color |
|---|---|---|
| `bronze` | Bronze | `#CD7F32` |
| `silver` | Silver | `#C0C0C0` |
| `gold` | Gold | `#FFB300` |
| `platinum` | Platinum | `#E5E4E2` |
| `special` | Special | `#6C63FF` |

### `ScratchRewardType` Enum

`xp` / `medal` / `badge` / `multiplier` / `nothing`

### `ProofStatus` Enum

`pending` / `approved` / `rejected`

### `DareItemStatus` Enum

`notStarted` / `inProgress` / `submitted` / `completed` / `rejected`

### `DareMemberRole` Enum

`creator` / `participant`

### `DareMemberStatus` Enum

`pending` / `approved` / `declined` / `suspended`

### `DareMilestone`

Sub-checkpoint within a challenge.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Milestone ID |
| `title` | `String` | Milestone name |
| `description` | `String?` | Details |
| `xpReward` | `int` | XP on completion (default `50`) |
| `medalType` | `MedalType` | Medal tier |
| `order` | `int` | Sequence order |

### `DareChallenge`

One activity within a Dare.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Challenge ID |
| `title` | `String` | Challenge name |
| `description` | `String?` | What to do |
| `imageUrl` | `String?` | Challenge photo |
| `category` | `DareCategory` | Challenge category |
| `type` | `DareChallengeType` | `appListing` or `custom` |
| `listingId` | `String?` | Firestore listing doc ID |
| `listingCollection` | `String?` | `spots` / `restaurants` / `cafes` / … |
| `listingLocation` | `String?` | Location name from listing |
| `customInstructions` | `String?` | Free-form instructions |
| `xpReward` | `int` | XP awarded (default `100`) |
| `medalType` | `MedalType` | Medal tier |
| `order` | `int` | Display order |
| `requiresProof` | `bool` | Photo proof required |
| `milestones` | `List<DareMilestone>` | Sub-checkpoints |

### `DareMember`

| Field | Type | Description |
|---|---|---|
| `userId` | `String` | Member UID |
| `userName` | `String` | Display name |
| `userPhoto` | `String?` | Photo URL |
| `role` | `DareMemberRole` | `creator` or `participant` |
| `status` | `DareMemberStatus` | Approval status |
| `joinedAt` | `DateTime` | Join date |
| `approvedAt` | `DateTime?` | Approval date |
| `completedChallenges` | `int` | Number completed |
| `totalXpEarned` | `int` | XP earned in this dare |

**Derived:** `isCreator`, `isApproved`

### `ProofSubmission`

Sub-collection: `dares/{dareId}/proofs`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `userId` | `String` | Submitter UID |
| `userName` | `String` | Submitter name |
| `userPhoto` | `String?` | Submitter photo |
| `challengeId` | `String` | Challenge this proof is for |
| `dareId` | `String` | Parent dare ID |
| `imageUrls` | `List<String>` | Proof photos |
| `latitude` | `double?` | GPS latitude |
| `longitude` | `double?` | GPS longitude |
| `locationName` | `String?` | Location label |
| `note` | `String?` | Optional note |
| `submittedAt` | `DateTime` | Submission time |
| `status` | `ProofStatus` | `pending` / `approved` / `rejected` |
| `reviewNote` | `String?` | Admin review comment |

### `ScratchCard`

Firestore collection: `scratch_cards/{id}`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `userId` | `String` | Owner UID |
| `dareId` | `String` | Originating dare |
| `dareTitle` | `String` | Dare name |
| `challengeId` | `String` | Originating challenge |
| `challengeTitle` | `String` | Challenge name |
| `rewardType` | `ScratchRewardType` | Reward type |
| `xpAmount` | `int` | XP if `rewardType == xp` |
| `medal` | `MedalType?` | Medal if `rewardType == medal` |
| `badgeTitle` | `String?` | Badge name if `rewardType == badge` |
| `multiplier` | `double?` | Multiplier if `rewardType == multiplier` |
| `isScratched` | `bool` | Whether card has been revealed |
| `earnedAt` | `DateTime` | When card was earned |
| `scratchedAt` | `DateTime?` | When card was scratched |

### `DareMedalRecord`

Sub-collection: `users/{uid}/dare_medals`

| Field | Type |
|---|---|
| `id` | `String` |
| `medalType` | `MedalType` |
| `dareId` | `String` |
| `dareTitle` | `String` |
| `challengeTitle` | `String` |
| `bannerUrl` | `String?` |
| `earnedAt` | `DateTime` |

### `DareModel`

Main dare document.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `title` | `String` | Dare title |
| `description` | `String` | Description |
| `bannerUrl` | `String?` | Banner image |
| `category` | `DareCategory` | Category |
| `customCategory` | `String?` | Used when `category == other` |
| `visibility` | `DareVisibility` | `public` or `private` |
| `maxParticipants` | `int` | Participant cap |
| `joinCode` | `String` | Invite code |
| `creatorId` | `String` | Creator UID |
| `creatorName` | `String` | Creator name |
| `creatorPhoto` | `String?` | Creator photo |
| `challenges` | `List<DareChallenge>` | All challenges |
| `members` | `List<DareMember>` | All members (incl. creator) |
| `joinRequests` | `List<DareMember>` | Pending join requests |
| `createdAt` | `DateTime` | Creation timestamp |
| `deadline` | `DateTime?` | Optional expiry date |
| `completedAt` | `DateTime?` | Completion timestamp |
| `xpReward` | `int` | Bonus XP for full completion |
| `tags` | `List<String>` | Discovery tags |
| `requiresProof` | `bool` | Proof required by default |
| `removedUserIds` | `List<String>` | Banned user IDs |
| `likeCount` | `int` | Like count |
| `adminRestricted` | `bool` | Admin has restricted this dare |
| `adminRestrictReason` | `String?` | Restriction reason |

**Derived helpers:** `approvedMembers`, `participantCount`, `isFull`, `isExpired`, `isParticipant(uid)`, `isCreator(uid)`, `hasPendingRequest(uid)`, `isRemoved(uid)`, `displayCategory`, `memberInfo(uid)`

---

## 10. Gamification Models

**File:** `gamification_models.dart`

### `XpAction` Enum

| Value | Base XP | Description |
|---|---|---|
| `writeReview` | +15 | Submit a star rating + comment |
| `uploadPhoto` | +10 | Upload community photo |
| `createBucketList` | +20 | Create a new bucket list |
| `completeBucketItem` | +10 | Check off a bucket item |
| `createDilemma` | +25 | Post a new dilemma |
| `voteDilemma` | +5 | Cast a vote on a dilemma |
| `submitContribution` | +20 | Submit a new spot for review |
| `dailyLogin` | +5 | First app open of the day |
| `streakBonus` | +10 | Awarded additionally when streak ≥ 3 |
| `weeklyStreak` | +30 | Bonus at exactly 7-day streak |
| `monthlyStreak` | +100 | Bonus at exactly 30-day streak |

### `XpEvent`

Written to `users/{uid}/xpEvents` for the activity feed.

| Field | Type |
|---|---|
| `id` | `String` |
| `action` | `XpAction` |
| `xpEarned` | `int` |
| `createdAt` | `DateTime` |
| `relatedId` | `String?` (spotId, dilemmaId, etc.) |

### `StreakInfo`

Parsed from the user document.

| Field | Type | Description |
|---|---|---|
| `currentStreak` | `int` | Current consecutive-day count |
| `longestStreak` | `int` | All-time best |
| `lastLogin` | `DateTime?` | Last recorded login date |

**Derived:** `display` (e.g. "🔥 5"), `xpMultiplier` (every 5 days adds +10%, capped at ×2.0)

### `GamificationResult`

Returned by `GamificationService.award()`.

| Field | Type |
|---|---|
| `xpAwarded` | `int` |
| `newBadgeIds` | `List<String>` |
| `leveledUp` | `bool` |
| `newLevel` | `int` |
| `totalPoints` | `int` |
| `streak` | `StreakInfo` |

**Derived:** `hasReward` — true if any XP, badge, or level was earned.

### `LevelInfo`

| Field | Type |
|---|---|
| `level` | `int` |
| `title` | `String` |
| `minPoints` | `int` |
| `maxPoints` | `int` |

**Static catalogue** (`LevelInfo.levels`):

| Level | Title | Min | Max |
|---|---|---|---|
| 1 | Explorer | 0 | 99 |
| 2 | Wanderer | 100 | 249 |
| 3 | Adventurer | 250 | 499 |
| 4 | Pathfinder | 500 | 999 |
| 5 | Guide | 1,000 | 1,999 |
| 6 | Expert | 2,000 | 3,999 |
| 7 | Master | 4,000 | 6,999 |
| 8 | Legend | 7,000 | 9,999 |
| 9 | Champion | 10,000 | 14,999 |
| 10 | Guardian | 15,000 | ∞ |

### `ReviewModel`

| Field | Type |
|---|---|
| `userId` | `String` |
| `userName` | `String` |
| `userPhoto` | `String?` |
| `rating` | `double` |
| `comment` | `String` |
| `timestamp` | `String` |

### `LeaderboardEntry`

| Field | Type |
|---|---|
| `rank` | `int` |
| `userId` | `String` |
| `userName` | `String` |
| `userPhoto` | `String?` |
| `points` | `int` |
| `level` | `int` |
| `levelTitle` | `String` |
| `badgesCount` | `int` |

### `BadgeModel`

| Field | Type |
|---|---|
| `id` | `String` |
| `name` | `String` |
| `description` | `String` |
| `icon` | `IconData` |
| `rarity` | `String` (`common` / `rare` / `epic` / `legendary`) |
| `category` | `String` |
| `pointsReward` | `int` |
| `earned` | `bool` |

**Rarity colours:**

| Rarity | Colour |
|---|---|
| `common` | `#9E9E9E` |
| `rare` | `#42A5F5` |
| `epic` | `#AB47BC` |
| `legendary` | `#FFB300` |

#### Pre-defined Badge Catalogue (`BadgeModel.allBadges`)

| ID | Name | Category | Rarity | XP |
|---|---|---|---|---|
| `first_review` | First Review | reviews | common | 10 |
| `five_reviews` | Reviewer | reviews | common | 20 |
| `twenty_reviews` | Critic | reviews | rare | 50 |
| `fifty_reviews` | Authority | reviews | epic | 150 |
| `first_contribution` | Contributor | contributions | common | 15 |
| `five_contributions` | Explorer | contributions | rare | 75 |
| `ten_contributions` | Cartographer | contributions | epic | 150 |
| `first_bookmark` | Collector | bookmarks | common | 5 |
| `level_5` | Guide | levels | rare | 100 |
| `level_10` | Guardian | levels | legendary | 500 |
| `community_post` | Social | community | common | 10 |
| `bucket_list` | Planner | community | common | 10 |
| `photo_explorer` | Photographer | media | rare | 50 |
| `photo_master` | Lens Master | media | epic | 120 |
| `top_10` | Top Explorer | leaderboard | epic | 200 |
| `streak_3` | On a Roll | streaks | common | 15 |
| `streak_7` | Week Warrior | streaks | rare | 50 |
| `streak_30` | Unstoppable | streaks | legendary | 300 |
| `first_dilemma` | Torn | dilemmas | common | 10 |
| `dilemma_voter` | Poll Master | dilemmas | rare | 40 |

---

## 11. Banner Model

**File:** `banner_model.dart`  
**Firestore collection:** `home_banners/{id}`  
**Config doc:** `app_config/home_banners`

### `BannerLinkType` Enum

| Value | Description |
|---|---|
| `none` | No action on tap |
| `externalUrl` | Opens a web URL |
| `internalRoute` | Navigates to a GoRouter path |

### `BannerModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `title` | `String` | Banner headline |
| `subtitle` | `String` | Supporting text |
| `imageUrl` | `String` | Banner image URL |
| `linkType` | `BannerLinkType` | What happens on tap |
| `linkValue` | `String?` | URL or GoRouter path |
| `isActive` | `bool` | Visibility toggle |
| `order` | `int` | Sort order on home screen |
| `createdAt` | `DateTime` | Creation timestamp |
| `updatedAt` | `DateTime` | Last update timestamp |

### `BannerSectionConfig`

Global visibility flag for the entire banner section.

| Field | Type |
|---|---|
| `sectionVisible` | `bool` |

---

## 12. Visitor Guide Model

**File:** `visitor_guide_model.dart`  
**Firestore collection:** `visitor_guides/{stateKey}`

### `GuideQuickFact`

| Field | Type | Description |
|---|---|---|
| `label` | `String` | Fact label (e.g. "Capital") |
| `value` | `String` | Fact value (e.g. "Aizawl") |
| `iconName` | `String` | Icon name stored as string, mapped on UI |

### `VisitorGuideModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | State key (Firestore doc ID) |
| `stateName` | `String` | Display name (e.g. "Mizoram") |
| `emoji` | `String` | State emoji flag |
| `tagline` | `String` | Short marketing tagline |
| `about` | `String` | Full about paragraph |
| `bannerImageUrl` | `String` | Hero banner image |
| `dos` | `List<String>` | Visitor dos |
| `donts` | `List<String>` | Visitor don'ts |
| `facts` | `List<GuideQuickFact>` | Quick facts grid |
| `isPublished` | `bool` | Visibility toggle |
| `updatedAt` | `DateTime` | Last update timestamp |

---

## 13. Admin Model

**File:** `admin_model.dart`  
**Firestore collection:** `app_admins/{uid}`

### `AdminRole` Enum

| Value | Label | Description |
|---|---|---|
| `superAdmin` | Super Admin | Full access — `hillstechadmin@xplooria.com` |
| `moderator` | Moderator | Can review and approve content |
| `analyst` | Analyst | Read-only analytics access |

### `AdminPermissions`

| Field | Type | Default |
|---|---|---|
| `canManageSpots` | `bool` | `false` |
| `canManageListings` | `bool` | `false` |
| `canManageEvents` | `bool` | `false` |
| `canManageVentures` | `bool` | `false` |
| `canManageUsers` | `bool` | `false` |
| `canViewAnalytics` | `bool` | `false` |
| `canManageCommunity` | `bool` | `false` |
| `canManageAdmins` | `bool` | `false` (superAdmin only) |

`AdminPermissions.all()` — all flags set to `true`, used for superAdmin.

### `AdminModel`

| Field | Type | Description |
|---|---|---|
| `uid` | `String` | Firebase UID |
| `email` | `String` | Admin email |
| `displayName` | `String` | Admin name |
| `role` | `AdminRole` | Role level |
| `permissions` | `AdminPermissions` | Granular feature flags |
| `isActive` | `bool` | Account active toggle |
| `lastLogin` | `DateTime?` | Most recent login |
| `createdAt` | `DateTime?` | When access was granted |
| `createdBy` | `String` | UID of granting admin |

**Derived:** `isSuperAdmin`

### `AppAnalyticsSnapshot`

Read from `app_analytics/daily_snapshot`.

| Field | Type |
|---|---|
| `totalUsers` | `int` |
| `newUsersToday` | `int` |
| `newUsersThisWeek` | `int` |
| `totalSpots` | `int` |
| `totalListings` | `int` |
| `totalEvents` | `int` |
| `totalVentures` | `int` |
| `totalCommunityPosts` | `int` |
| `totalReviews` | `int` |
| `totalBookingRequests` | `int` |
| `pendingBookingRequests` | `int` |
| `totalPointsAwarded` | `int` |
| `updatedAt` | `DateTime?` |

---

## Firestore Collection Summary

| Collection | Model | File |
|---|---|---|
| `users/{uid}` | `UserModel` | user_model.dart |
| `users/{uid}/xpEvents` | `XpEvent` | gamification_models.dart |
| `users/{uid}/dare_medals` | `DareMedalRecord` | dare_models.dart |
| `spots/{id}` | `SpotModel` | spot_model.dart |
| `restaurants/{id}` | `RestaurantModel` | listing_models.dart |
| `hotels/{id}` | `HotelModel` | listing_models.dart |
| `cafes/{id}` | `CafeModel` | listing_models.dart |
| `homestays/{id}` | `HomestayModel` | listing_models.dart |
| `adventureSpots/{id}` | `TourVentureModel` + `AdventureSpotModel` | tour_venture_models.dart / listing_models.dart |
| `adventureSpots/{id}/registrations` | `VentureRegistration` | tour_venture_models.dart |
| `adventureSpots/{id}/feedback` | `VentureFeedback` | tour_venture_models.dart |
| `shoppingAreas/{id}` | `ShoppingAreaModel` | listing_models.dart |
| `events/{id}` | `EventModel` | event_model.dart |
| `venture_bookings/{id}` | `VentureBooking` | booking_model.dart |
| `community_posts/{id}` | `CommunityPost` | community_models.dart |
| `dilemmas/{id}` | `Dilemma` | community_models.dart |
| `bucket_lists/{id}` | `BucketListModel` | bucket_list_models.dart |
| `bucket_lists/{id}/pokes` | `RoomPokeModel` | bucket_list_models.dart |
| `bucket_lists/{id}/reports` | `RoomReportModel` | bucket_list_models.dart |
| `dares/{id}` | `DareModel` | dare_models.dart |
| `dares/{id}/proofs` | `ProofSubmission` | dare_models.dart |
| `scratch_cards/{id}` | `ScratchCard` | dare_models.dart |
| `home_banners/{id}` | `BannerModel` | banner_model.dart |
| `app_config/home_banners` | `BannerSectionConfig` | banner_model.dart |
| `visitor_guides/{stateKey}` | `VisitorGuideModel` | visitor_guide_model.dart |
| `app_admins/{uid}` | `AdminModel` | admin_model.dart |
| `app_analytics/daily_snapshot` | `AppAnalyticsSnapshot` | admin_model.dart |
