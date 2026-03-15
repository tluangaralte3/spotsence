# SpotMizoram Gamification System

## Overview

Every meaningful action a user takes automatically awards XP, tracks streaks, evaluates badge unlocks, and updates their profile — all via a single Firestore transaction. No manual steps required from the user.

---

## XP Actions & Points

| Action                      | XP   | Trigger Location                          |
| --------------------------- | ---- | ----------------------------------------- |
| Write a review              | +15  | `place_detail_sheet.dart`                 |
| Upload a community photo    | +10  | `place_detail_sheet.dart`                 |
| Create a bucket list        | +20  | `bucket_list_controller.dart`             |
| Complete a bucket list item | +10  | `bucket_list_controller.dart`             |
| Create a dilemma            | +25  | `community_controller.dart`               |
| Vote on a dilemma           | +5   | `community_controller.dart`               |
| Daily login                 | +5   | `main_shell.dart` (once per calendar day) |
| Streak bonus (day 3+)       | +10  | `gamification_service.dart`               |
| Weekly streak (day 7)       | +30  | `gamification_service.dart`               |
| Monthly streak (day 30)     | +100 | `gamification_service.dart`               |

---

## Streak Multiplier

Consecutive daily logins boost all XP earned that session. Every 5 days adds +10%, capped at ×2.0.

```
multiplier = clamp(1.0 + floor(streak / 5) × 0.10, 1.0, 2.0)
```

| Streak     | Multiplier      |
| ---------- | --------------- |
| 1–4 days   | ×1.0 (no bonus) |
| 5–9 days   | ×1.1            |
| 10–14 days | ×1.2            |
| 15–19 days | ×1.3            |
| 20–24 days | ×1.4            |
| 25–29 days | ×1.5            |
| 30–34 days | ×1.6            |
| 35–39 days | ×1.7            |
| 40–44 days | ×1.8            |
| 45–49 days | ×1.9            |
| 50+ days   | ×2.0 (cap)      |

The multiplier is applied inside the Firestore transaction in `gamification_service.dart` before writing back to Firestore. Streak-specific bonus actions (streakBonus, weeklyStreak, monthlyStreak) are **not** multiplied — only regular actions are.

Missing a day resets the streak to 0.

---

## Level System

Points accumulate on the user's Firestore doc (`users/{uid}.points`). Level and title are recalculated on every XP award.

| Level | Points Required | Title      |
| ----- | --------------- | ---------- |
| 1     | 0               | Explorer   |
| 2     | 100             | Wanderer   |
| 3     | 250             | Adventurer |
| 4     | 500             | Pathfinder |
| 5     | 1,000           | Guide      |
| 6     | 2,000           | Expert     |
| 7     | 3,500           | Master     |
| 8     | 5,500           | Legend     |
| 9     | 8,500           | Champion   |
| 10    | 12,500          | Guardian   |

Level-up is detected by comparing `oldLevel` vs `finalLevel` inside the transaction. When a level-up occurs, `GamificationResult.leveledUp = true`, which triggers a special celebratory toast message.

---

## Badge Catalogue (22 Badges)

Badges are evaluated on every XP award via `BadgeModel.evaluate()`. They unlock automatically when a counter threshold is met. Each badge also awards bonus XP on unlock.

### 🗺️ Exploration Badges

| ID                          | Badge              | Rarity    | Condition               | Bonus XP |
| --------------------------- | ------------------ | --------- | ----------------------- | -------- |
| `first_review`              | First Review       | Common ⚪ | ratingsCount ≥ 1        | +10      |
| `ten_reviews`               | Regular Reviewer   | Rare 🔵   | ratingsCount ≥ 10       | +25      |
| `fifty_reviews`             | Review Master 🎖️   | Epic 🟣   | ratingsCount ≥ 50       | +75      |
| `first_contribution`        | First Contributor  | Common ⚪ | contributionsCount ≥ 1  | +10      |
| `ten_contributions`         | Active Explorer 🗺️ | Epic 🟣   | contributionsCount ≥ 10 | +50      |
| `twenty_five_contributions` | Mizoram Guide      | Rare 🔵   | contributionsCount ≥ 25 | +40      |

### 📷 Photo Badges

| ID             | Badge           | Rarity    | Condition        | Bonus XP |
| -------------- | --------------- | --------- | ---------------- | -------- |
| `first_photo`  | Shutterbug      | Common ⚪ | photosCount ≥ 1  | +10      |
| `photo_master` | Photo Master 📷 | Epic 🟣   | photosCount ≥ 10 | +50      |

### 🔥 Streak Badges

| ID          | Badge           | Rarity       | Condition        | Bonus XP |
| ----------- | --------------- | ------------ | ---------------- | -------- |
| `streak_3`  | On a Roll 🔥    | Common ⚪    | loginStreak ≥ 3  | +15      |
| `streak_7`  | Week Warrior 🔥 | Rare 🔵      | loginStreak ≥ 7  | +40      |
| `streak_30` | Unstoppable 💎  | Legendary 🟡 | loginStreak ≥ 30 | +150     |

### 🤔 Dilemma Badges

| ID              | Badge              | Rarity    | Condition           | Bonus XP |
| --------------- | ------------------ | --------- | ------------------- | -------- |
| `first_dilemma` | Question Master 🤔 | Common ⚪ | dilemmasCreated ≥ 1 | +10      |
| `dilemma_voter` | Decision Maker 🗳️  | Rare 🔵   | dilemmasVoted ≥ 10  | +30      |

### ✅ Bucket List Badges

| ID                   | Badge              | Rarity    | Condition                 | Bonus XP |
| -------------------- | ------------------ | --------- | ------------------------- | -------- |
| `bucket_complete_1`  | Bucket Starter ✅  | Common ⚪ | bucketItemsCompleted ≥ 1  | +15      |
| `bucket_complete_10` | Bucket Champion 🏁 | Rare 🔵   | bucketItemsCompleted ≥ 10 | +50      |

### ✨ Special Badges

| ID                 | Badge            | Rarity       | Condition                   | Bonus XP |
| ------------------ | ---------------- | ------------ | --------------------------- | -------- |
| `early_adopter`    | Early Adopter 🚀 | Legendary 🟡 | level ≥ 2 (first 100 users) | +100     |
| `top_10`           | Top Explorer     | Rare 🔵      | rank ≤ 10                   | +50      |
| `level_5`          | Rising Star      | Common ⚪    | level ≥ 5                   | +20      |
| `level_10`         | Guardian         | Legendary 🟡 | level ≥ 10                  | +200     |
| `bookworm`         | Well-Travelled   | Common ⚪    | bookmarks ≥ 10              | +15      |
| `social_butterfly` | Community Pillar | Rare 🔵      | various community actions   | +30      |

### Rarity Colour Key

| Rarity    | Colour |
| --------- | ------ |
| Common    | Grey   |
| Rare      | Blue   |
| Epic      | Purple |
| Legendary | Gold   |

---

## Firestore Data Model

### User Document — `users/{uid}`

**Existing fields (updated by gamification):**

```
points              int     — total accumulated XP
level               int     — current level (1–10)
levelTitle          string  — e.g. "Wanderer"
badges              []      — active display badges
badgesEarned        []      — all-time unlocked badge IDs
ratingsCount        int     — total reviews written
contributionsCount  int     — total spot contributions
```

**New fields added by gamification:**

```
photosCount           int       — community photos uploaded
dilemmasCreated       int       — dilemmas created
dilemmasVoted         int       — dilemma votes cast
bucketListsCreated    int       — bucket lists created
bucketItemsCompleted  int       — bucket items ticked off
loginStreak           int       — current consecutive login days
longestStreak         int       — all-time best streak
lastLogin             Timestamp — last recorded login date
```

### XP Events Subcollection — `users/{uid}/xpEvents/{eventId}`

Each XP award writes a log entry for the Activity feed:

```
action      string    — XpAction name (e.g. "writeReview")
xpEarned    int       — total XP including multiplier + badge bonus
createdAt   Timestamp — server timestamp
relatedId   string?   — optional (spot ID, dilemma ID, etc.)
```

Firestore rules: users can `read` and `create` their own events only.

---

## Architecture — Data Flow

```
User Action
    │
    ▼
Screen / Controller  (e.g. place_detail_sheet.dart)
  └─ gamificationController.award(XpAction.writeReview, relatedId: spotId)
  └─ gamificationController.incrementCounter('ratingsCount')
    │
    ▼
GamificationController  (Riverpod NotifierProvider)
  └─ calls GamificationService.award()
    │
    ▼
GamificationService  (Firestore Transaction — atomic)
  1. Read users/{uid}
  2. Load StreakInfo from doc fields
  3. Calculate streak multiplier
  4. xpAwarded = baseXp × multiplier
  5. Run BadgeModel.evaluate() → newBadgeIds[]
  6. Add badge bonus XP for each new badge
  7. Recalculate level & levelTitle
  8. Write users/{uid} update (points, level, badges, streak fields)
  9. Write users/{uid}/xpEvents/{autoId}
  10. Return GamificationResult
    │
    ▼
GamificationController  (back in Riverpod)
  └─ pushes GamificationResult to _rewardStreamController (broadcast)
  └─ calls authController.refreshProfile() → all UI rebuilds
    │
    ▼
XpToastOverlay  (wraps every screen via MainShell)
  └─ subscribed via listenManual (fireImmediately: false)
  └─ shows animated slide-up toast for 3.5 seconds:
       Normal:    "+15 XP  ⭐ Keep going!"
       Badge:     "+15 XP  🏅 Badge unlocked: First Review"
       Level up:  "+15 XP  🎉 Level 3! Adventurer"
       Streak:    "🔥 7-day streak  ×1.1 XP"
```

---

## User-Facing UI

### Profile Screen

| Section       | What it shows                                                                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Header avatar | 🔥 StreakBanner (visible when streak ≥ 2) with shimmer animation                                                                                 |
| XP bar        | Current XP / next level XP with animated fill + percentage                                                                                       |
| Stats tab     | 11 counters: reviews, photos, contributions, dilemmas created, bucket items completed, streak, best streak, badges, total XP, level, saved spots |
| Badges tab    | Grid of all unlocked badges, colour-coded by rarity                                                                                              |
| Activity tab  | Live scrollable feed of last 20 XP events with timestamps                                                                                        |

### Toast (All Screens)

Slides up from the bottom above the nav bar. Auto-dismisses after 3.5s. Shows:

- XP pill (green): `+15 XP`
- Message line: level-up celebration / badge name / generic encouragement
- Streak line (if streak ≥ 3): `🔥 7-day streak ×1.1 XP`

---

## Retention Mechanics

| Mechanic               | How it retains                                                                  |
| ---------------------- | ------------------------------------------------------------------------------- |
| **Daily login streak** | Reason to open every day; missing resets to 0 creating loss aversion            |
| **Streak multiplier**  | Every action is worth more the longer the streak — compounding reward           |
| **Milestone streaks**  | +30 XP at day 7, +100 XP at day 30 create anticipation spikes                   |
| **Badge goals**        | 22 clear targets at different effort levels keep casual and power users engaged |
| **Level titles**       | Identity progression from "Explorer" → "Guardian" gives status beyond numbers   |
| **Activity feed**      | Personal history reinforces the habit loop and shows tangible progress          |
| **XP toasts**          | Immediate dopamine feedback on every action                                     |

---

## Version 2 Roadmap (Planned)

- **AR Spot Visits** — physically visiting a spot (verified via camera + GPS) awards medals, similar to Pokémon GO PokéStops
- **DARE Feature** — admin-issued challenges with time limits and XP/badge rewards (e.g. "Visit 3 waterfalls this weekend")
- **Social XP** — bonus XP when friends complete your bucket list or vote on your dilemma
