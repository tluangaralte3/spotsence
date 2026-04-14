// functions/index.js
//
// Firebase Cloud Functions – push notification triggers for Xplooria.
//
// Triggers (Firestore onCreate):
//   1.  dares/{dareId}          → topic: new_dares      (public dares only)
//   2.  dilemmas/{dilemmaId}    → topic: new_dilemmas
//   3.  ventures/{ventureId}    → topic: new_ventures
//   4+. <listing collection>/{docId} → topic: new_listings
//
// FCM data payload keys consumed by the Flutter app:
//   type  – 'dare' | 'dilemma' | 'venture' | 'listing'
//   id    – Firestore document ID (used by Flutter to deep-link)
//
// Deploy:
//   cd functions && npm install
//   firebase deploy --only functions --project spotmizoram

'use strict';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp }     = require('firebase-admin/app');
const { getMessaging }      = require('firebase-admin/messaging');

initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/** Build the FCM Android config block (channel + click action). */
function androidConfig() {
  return {
    notification: {
      channelId: 'xplooria_channel',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };
}

/** Truncate a string to keep notification bodies readable. */
function trunc(str, max = 60) {
  if (!str) return '';
  return str.length <= max ? str : str.slice(0, max - 1) + '…';
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. New public dare / challenge created
// ─────────────────────────────────────────────────────────────────────────────

exports.onDareCreated = onDocumentCreated(
  { document: 'dares/{dareId}', region: 'asia-southeast1' },
  async (event) => {
    const dare = event.data?.data();
    if (!dare) return;

    // Only broadcast public dares; private ones are invite-only.
    if (dare.visibility !== 'public') return;

    const title   = trunc(dare.title ?? 'New Challenge');
    const creator = dare.creatorName ?? 'Someone';

    await getMessaging().send({
      topic: 'new_dares',
      notification: {
        title: '🎯 New Challenge Available!',
        body: `${creator} just created "${title}" – join the dare!`,
      },
      data: {
        type: 'dare',
        id:   event.params.dareId,
      },
      android: androidConfig(),
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    });
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// 2. New dilemma posted
// ─────────────────────────────────────────────────────────────────────────────

exports.onDilemmaCreated = onDocumentCreated(
  { document: 'dilemmas/{dilemmaId}', region: 'asia-southeast1' },
  async (event) => {
    const d = event.data?.data();
    if (!d) return;

    const question = trunc(d.question ?? d.title ?? 'A new dilemma');
    const author   = d.authorName ?? d.creatorName ?? 'Someone';

    await getMessaging().send({
      topic: 'new_dilemmas',
      notification: {
        title: '🤔 New Dilemma Posted!',
        body: `${author}: "${question}" – cast your vote!`,
      },
      data: {
        type: 'dilemma',
        id:   event.params.dilemmaId,
      },
      android: androidConfig(),
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    });
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// 3. New venture / adventure package added
// ─────────────────────────────────────────────────────────────────────────────

exports.onVentureCreated = onDocumentCreated(
  { document: 'ventures/{ventureId}', region: 'asia-southeast1' },
  async (event) => {
    const v = event.data?.data();
    if (!v) return;

    // Skip drafts (isAvailable === false means admin hasn't published yet).
    if (v.isAvailable === false) return;

    const title    = trunc(v.title ?? 'New Adventure');
    const location = v.location ?? v.district ?? 'Mizoram';

    await getMessaging().send({
      topic: 'new_ventures',
      notification: {
        title: '🏕️ New Adventure Package!',
        body: `"${title}" in ${location} is now available – explore and book!`,
      },
      data: {
        type: 'venture',
        id:   event.params.ventureId,
      },
      android: androidConfig(),
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    });
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// 4. New listing added by admin (multiple collections)
//    Covers: spots, restaurants, cafes, hotels, homestays,
//            adventureSpots, shopping, events
// ─────────────────────────────────────────────────────────────────────────────

const LISTING_COLLECTIONS = [
  { col: 'spots',           label: 'Tourist Spots',   emoji: '📍' },
  { col: 'restaurants',     label: 'Restaurants',     emoji: '🍽️' },
  { col: 'cafes',           label: 'Cafés',           emoji: '☕' },
  { col: 'hotels',          label: 'Hotels',          emoji: '🏨' },
  { col: 'homestays',       label: 'Homestays',       emoji: '🏡' },
  { col: 'adventureSpots',  label: 'Adventure Spots', emoji: '🧗' },
  { col: 'shopping',        label: 'Shopping',        emoji: '🛍️' },
  { col: 'events',          label: 'Events',          emoji: '🎉' },
];

for (const { col, label, emoji } of LISTING_COLLECTIONS) {
  // Function names must be valid JavaScript identifiers.
  const fnName = 'onListing_' + col.replace(/[^a-zA-Z0-9]/g, '_') + '_Created';

  exports[fnName] = onDocumentCreated(
    { document: `${col}/{docId}`, region: 'asia-southeast1' },
    async (event) => {
      const listing = event.data?.data();
      if (!listing) return;

      const name = trunc(listing.name ?? listing.title ?? `New ${label}`);

      await getMessaging().send({
        topic: 'new_listings',
        notification: {
          title: `${emoji} New ${label} Added!`,
          body: `"${name}" is now on Xplooria – check it out!`,
        },
        data: {
          type:       'listing',
          id:         event.params.docId,
          collection: col,
        },
        android: androidConfig(),
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
        },
      });
    },
  );
}
