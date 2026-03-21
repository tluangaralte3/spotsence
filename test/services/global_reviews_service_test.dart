// test/services/global_reviews_service_test.dart
//
// Unit tests for GlobalReviewsService using FakeFirebaseFirestore.
//
// Covers:
//   recordReview()         — writes to global_reviews + updates place_leaderboard
//   _updateLeaderboard()   — first review sets avgRating; subsequent updates running average
//   watchReviewsForPlace() — streams reviews for a specific placeId
//   watchLatestReviews()   — streams all reviews

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotmizoram/services/global_reviews_service.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Future<void> submitReview(
  GlobalReviewsService svc, {
  String placeId = 'place1',
  String placeName = 'Vantawng Falls',
  String category = 'spot',
  String heroImage = 'https://img.jpg',
  String userId = 'u1',
  String userName = 'Lal',
  String userAvatar = '',
  double rating = 4.0,
  String comment = 'Beautiful!',
}) async {
  await svc.recordReview(
    placeId: placeId,
    placeName: placeName,
    category: category,
    heroImage: heroImage,
    userId: userId,
    userName: userName,
    userAvatar: userAvatar,
    rating: rating,
    comment: comment,
  );
}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late GlobalReviewsService sut;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    sut = GlobalReviewsService(fakeDb);
  });

  // ── recordReview() — global_reviews ──────────────────────────────────────

  group('recordReview() — global_reviews collection', () {
    test('creates a document in global_reviews', () async {
      await submitReview(sut);

      final snap = await fakeDb.collection('global_reviews').get();
      expect(snap.docs.length, 1);
    });

    test('review document has correct placeId field', () async {
      await submitReview(sut, placeId: 'spot42');

      final snap = await fakeDb.collection('global_reviews').get();
      expect(snap.docs.first.data()['placeId'], 'spot42');
    });

    test('review document has correct rating field', () async {
      await submitReview(sut, rating: 3.5);

      final snap = await fakeDb.collection('global_reviews').get();
      expect(snap.docs.first.data()['rating'], 3.5);
    });

    test('review document has all required fields', () async {
      await submitReview(
        sut,
        placeId: 'p1',
        placeName: 'Reiek Peak',
        category: 'spot',
        userId: 'u2',
        userName: 'Vanlal',
        rating: 5.0,
        comment: 'Spectacular!',
      );

      final snap = await fakeDb.collection('global_reviews').get();
      final d = snap.docs.first.data();
      expect(d['placeId'], 'p1');
      expect(d['placeName'], 'Reiek Peak');
      expect(d['category'], 'spot');
      expect(d['userId'], 'u2');
      expect(d['userName'], 'Vanlal');
      expect(d['rating'], 5.0);
      expect(d['comment'], 'Spectacular!');
    });

    test('each call creates a separate document', () async {
      await submitReview(sut, userId: 'u1');
      await submitReview(sut, userId: 'u2', comment: 'Nice');

      final snap = await fakeDb.collection('global_reviews').get();
      expect(snap.docs.length, 2);
    });
  });

  // ── recordReview() — place_leaderboard ────────────────────────────────────

  group('recordReview() — place_leaderboard', () {
    test('creates a place_leaderboard doc on first review', () async {
      await submitReview(sut, placeId: 'spot1', rating: 4.0);

      final snap = await fakeDb
          .collection('place_leaderboard')
          .doc('spot1')
          .get();
      expect(snap.exists, isTrue);
    });

    test('first review sets ratingCount to 1', () async {
      await submitReview(sut, placeId: 'spot1', rating: 4.0);

      final snap = await fakeDb
          .collection('place_leaderboard')
          .doc('spot1')
          .get();
      expect(snap.data()!['ratingCount'], 1);
    });

    test('first review sets avgRating to the review rating', () async {
      await submitReview(sut, placeId: 'spot1', rating: 4.0);

      final snap = await fakeDb
          .collection('place_leaderboard')
          .doc('spot1')
          .get();
      final avgRating = (snap.data()!['avgRating'] as num).toDouble();
      expect(avgRating, closeTo(4.0, 0.01));
    });

    test('second review updates avgRating to running average', () async {
      await submitReview(sut, placeId: 'spot1', rating: 4.0);
      await submitReview(sut, placeId: 'spot1', rating: 2.0, userId: 'u2');

      final snap = await fakeDb
          .collection('place_leaderboard')
          .doc('spot1')
          .get();
      final d = snap.data()!;
      expect((d['ratingCount'] as num).toInt(), 2);
      // avg = (4.0 + 2.0) / 2 = 3.0
      expect((d['avgRating'] as num).toDouble(), closeTo(3.0, 0.01));
    });

    test('three reviews compute correct running average', () async {
      await submitReview(sut, placeId: 'sp', rating: 5.0);
      await submitReview(sut, placeId: 'sp', rating: 3.0, userId: 'u2');
      await submitReview(sut, placeId: 'sp', rating: 4.0, userId: 'u3');

      final snap = await fakeDb.collection('place_leaderboard').doc('sp').get();
      final d = snap.data()!;
      expect((d['ratingCount'] as num).toInt(), 3);
      expect((d['avgRating'] as num).toDouble(), closeTo(4.0, 0.01));
    });

    test('leaderboard doc stores category and placeName', () async {
      await submitReview(
        sut,
        placeId: 'c1',
        placeName: 'Café Aizawl',
        category: 'cafe',
        rating: 4.5,
      );

      final snap = await fakeDb.collection('place_leaderboard').doc('c1').get();
      expect(snap.data()!['category'], 'cafe');
      expect(snap.data()!['placeName'], 'Café Aizawl');
    });

    test(
      'reviews for different places do not cross-pollute leaderboard',
      () async {
        await submitReview(sut, placeId: 'placeA', rating: 5.0);
        await submitReview(sut, placeId: 'placeB', rating: 1.0);

        final a = await fakeDb
            .collection('place_leaderboard')
            .doc('placeA')
            .get();
        final b = await fakeDb
            .collection('place_leaderboard')
            .doc('placeB')
            .get();
        expect((a.data()!['avgRating'] as num).toDouble(), closeTo(5.0, 0.01));
        expect((b.data()!['avgRating'] as num).toDouble(), closeTo(1.0, 0.01));
      },
    );
  });

  // ── watchReviewsForPlace() ────────────────────────────────────────────────

  group('watchReviewsForPlace()', () {
    test('emits empty list when no reviews exist', () async {
      final stream = sut.watchReviewsForPlace('noplace');
      final list = await stream.first;
      expect(list, isEmpty);
    });

    test('emits reviews for the correct placeId only', () async {
      await submitReview(sut, placeId: 'p1', comment: 'For p1');
      await submitReview(sut, placeId: 'p2', comment: 'For p2');

      final stream = sut.watchReviewsForPlace('p1');
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.placeId, 'p1');
    });

    test('review has correct fields after recordReview', () async {
      await submitReview(
        sut,
        placeId: 'px',
        userId: 'u1',
        userName: 'Lal',
        rating: 4.5,
        comment: 'Great!',
      );

      final stream = sut.watchReviewsForPlace('px');
      final list = await stream.first;
      expect(list.first.userId, 'u1');
      expect(list.first.userName, 'Lal');
      expect(list.first.rating, 4.5);
      expect(list.first.comment, 'Great!');
    });
  });

  // ── watchLatestReviews() ──────────────────────────────────────────────────

  group('watchLatestReviews()', () {
    test('emits empty list when collection is empty', () async {
      final stream = sut.watchLatestReviews();
      final list = await stream.first;
      expect(list, isEmpty);
    });

    test('emits all reviews after multiple recordReview calls', () async {
      await submitReview(sut, placeId: 'p1', userId: 'u1');
      await submitReview(sut, placeId: 'p2', userId: 'u2');
      await submitReview(sut, placeId: 'p3', userId: 'u3');

      final stream = sut.watchLatestReviews(limit: 10);
      final list = await stream.first;
      expect(list.length, 3);
    });

    test('reviews from different places are all returned', () async {
      await submitReview(sut, placeId: 'spotA', category: 'spot');
      await submitReview(sut, placeId: 'cafeB', category: 'cafe');

      final stream = sut.watchLatestReviews(limit: 10);
      final list = await stream.first;
      final categories = list.map((r) => r.category).toSet();
      expect(categories, containsAll(['spot', 'cafe']));
    });
  });

  // ── GlobalReview.fromMap ──────────────────────────────────────────────────

  group('GlobalReview.fromMap', () {
    test('parses all fields correctly', () {
      final review = GlobalReview.fromMap('doc1', {
        'placeId': 'p1',
        'placeName': 'Vantawng',
        'category': 'spot',
        'heroImage': 'img.jpg',
        'userId': 'u1',
        'userName': 'Lal',
        'userAvatar': 'avatar.jpg',
        'rating': 4.5,
        'comment': 'Lovely!',
      });

      expect(review.id, 'doc1');
      expect(review.placeId, 'p1');
      expect(review.placeName, 'Vantawng');
      expect(review.category, 'spot');
      expect(review.userId, 'u1');
      expect(review.rating, 4.5);
      expect(review.comment, 'Lovely!');
    });

    test('defaults to empty strings for missing fields', () {
      final review = GlobalReview.fromMap('id1', {});
      expect(review.placeId, '');
      expect(review.userId, '');
      expect(review.comment, '');
      expect(review.rating, 0.0);
    });

    test('coerces int rating to double', () {
      final review = GlobalReview.fromMap('id2', {'rating': 5});
      expect(review.rating, isA<double>());
      expect(review.rating, 5.0);
    });
  });
}
