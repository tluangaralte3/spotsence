// test/models/community_models_test.dart
//
// Unit tests for CommunityPost, PostComment (community_models.dart)
// and BucketCategory, BucketItem, BucketListModel (bucket_list_models.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:xplooria/models/community_models.dart';
import 'package:xplooria/models/bucket_list_models.dart';

void main() {
  // ── PostComment.fromJson ──────────────────────────────────────────────────

  group('PostComment.fromJson', () {
    test('parses all fields', () {
      final c = PostComment.fromJson({
        'id': 'cmt1',
        'userId': 'u1',
        'userName': 'Lalzama',
        'comment': 'Great spot!',
        'createdAt': '2024-03-01T00:00:00Z',
      });

      expect(c.id, 'cmt1');
      expect(c.userId, 'u1');
      expect(c.userName, 'Lalzama');
      expect(c.comment, 'Great spot!');
      expect(c.createdAt, '2024-03-01T00:00:00Z');
    });

    test('defaults to empty strings for missing fields', () {
      final c = PostComment.fromJson({});
      expect(c.id, '');
      expect(c.userId, '');
      expect(c.userName, '');
      expect(c.comment, '');
      expect(c.createdAt, '');
    });
  });

  // ── CommunityPost ─────────────────────────────────────────────────────────

  group('CommunityPost', () {
    CommunityPost makePost({
      String id = 'p1',
      String userId = 'u1',
      List<String> likes = const [],
      List<PostComment> comments = const [],
    }) => CommunityPost(
      id: id,
      userId: userId,
      userName: 'TestUser',
      type: 'post',
      content: 'Hello world',
      likes: likes,
      comments: comments,
      createdAt: '2024-01-01T00:00:00Z',
    );

    test('likeCount returns length of likes list', () {
      final post = makePost(likes: ['u1', 'u2', 'u3']);
      expect(post.likeCount, 3);
    });

    test('likeCount is 0 for empty likes', () {
      expect(makePost().likeCount, 0);
    });

    test('commentCount returns length of comments list', () {
      final post = makePost(
        comments: [
          PostComment.fromJson({
            'id': 'c1',
            'userId': 'u2',
            'userName': 'A',
            'comment': 'x',
            'createdAt': '',
          }),
        ],
      );
      expect(post.commentCount, 1);
    });

    test('commentCount is 0 when no comments', () {
      expect(makePost().commentCount, 0);
    });

    test('isLikedBy returns true when uid is in likes', () {
      final post = makePost(likes: ['u1', 'u2']);
      expect(post.isLikedBy('u1'), isTrue);
    });

    test('isLikedBy returns false when uid not in likes', () {
      final post = makePost(likes: ['u1', 'u2']);
      expect(post.isLikedBy('u99'), isFalse);
    });

    test('toggleLike adds uid when not yet liked', () {
      final post = makePost(likes: ['u1']);
      final toggled = post.toggleLike('u2');
      expect(toggled.likes, containsAll(['u1', 'u2']));
    });

    test('toggleLike removes uid when already liked', () {
      final post = makePost(likes: ['u1', 'u2']);
      final toggled = post.toggleLike('u1');
      expect(toggled.likes, isNot(contains('u1')));
      expect(toggled.likes, contains('u2'));
    });

    test('toggleLike preserves other fields', () {
      final post = makePost(likes: []);
      final toggled = post.toggleLike('u1');
      expect(toggled.id, post.id);
      expect(toggled.content, post.content);
      expect(toggled.userId, post.userId);
    });

    test('double toggle is idempotent', () {
      final post = makePost(likes: []);
      final added = post.toggleLike('u1');
      final removed = added.toggleLike('u1');
      expect(removed.likes, isEmpty);
    });

    test('fromJson parses complete post', () {
      final post = CommunityPost.fromJson({
        'id': 'p1',
        'userId': 'u1',
        'userName': 'Lalzama',
        'type': 'review',
        'content': 'Amazing view from Reiek!',
        'images': ['img1.jpg'],
        'spotId': 'spot1',
        'spotName': 'Reiek',
        'location': 'Reiek, Mizoram',
        'likes': ['u2', 'u3'],
        'comments': [],
        'createdAt': '2024-03-01T00:00:00Z',
      });

      expect(post.type, 'review');
      expect(post.content, 'Amazing view from Reiek!');
      expect(post.images, ['img1.jpg']);
      expect(post.spotName, 'Reiek');
      expect(post.likeCount, 2);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final post = CommunityPost.fromJson({
        'id': 'p2',
        'userId': 'u2',
        'userName': 'X',
        'type': 'post',
        'content': 'Hi',
        'likes': [],
        'comments': [],
        'createdAt': '',
      });
      expect(post.spotId, isNull);
      expect(post.images, isEmpty);
      expect(post.userPhoto, isNull);
    });

    test('fromJson defaults type to "post" when missing', () {
      final post = CommunityPost.fromJson({
        'id': 'p3',
        'userId': 'u3',
        'userName': 'Y',
        'content': 'Hi',
        'likes': [],
        'comments': [],
        'createdAt': '',
      });
      expect(post.type, 'post');
    });
  });

  // ── BucketCategory ────────────────────────────────────────────────────────

  group('BucketCategory', () {
    test('all categories have a non-empty label', () {
      for (final c in BucketCategory.values) {
        expect(c.label, isNotEmpty, reason: '${c.name} label missing');
      }
    });

    test('all categories have a non-empty emoji', () {
      for (final c in BucketCategory.values) {
        expect(c.emoji, isNotEmpty, reason: '${c.name} emoji missing');
      }
    });

    test('fromString parses known values (lowercase)', () {
      expect(BucketCategory.fromString('spot'), BucketCategory.spot);
      expect(
        BucketCategory.fromString('restaurant'),
        BucketCategory.restaurant,
      );
      expect(BucketCategory.fromString('cafe'), BucketCategory.cafe);
      expect(BucketCategory.fromString('hotel'), BucketCategory.hotel);
      expect(BucketCategory.fromString('homestay'), BucketCategory.homestay);
      expect(BucketCategory.fromString('adventure'), BucketCategory.adventure);
      expect(BucketCategory.fromString('shopping'), BucketCategory.shopping);
      expect(BucketCategory.fromString('event'), BucketCategory.event);
      expect(BucketCategory.fromString('other'), BucketCategory.other);
    });

    test('fromString falls back to other for unknown values', () {
      expect(BucketCategory.fromString('unknown'), BucketCategory.other);
      expect(BucketCategory.fromString(''), BucketCategory.other);
      expect(BucketCategory.fromString('foobar'), BucketCategory.other);
    });
  });

  // ── BucketItem ────────────────────────────────────────────────────────────

  group('BucketItem', () {
    BucketItem makeItem({bool isChecked = false}) => BucketItem(
      id: 'item1',
      name: 'Visit Phawngpui',
      category: BucketCategory.spot,
      isChecked: isChecked,
    );

    test('isChecked defaults to false', () {
      expect(makeItem().isChecked, isFalse);
    });

    test('copyWith can mark item as checked', () {
      final checked = makeItem().copyWith(
        isChecked: true,
        checkedByUserId: 'u1',
        checkedByUserName: 'Lal',
      );
      expect(checked.isChecked, isTrue);
      expect(checked.checkedByUserId, 'u1');
      expect(checked.checkedByUserName, 'Lal');
    });

    test('copyWith preserves unchanged fields', () {
      final original = makeItem();
      final copy = original.copyWith(note: 'bring camera');
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.category, original.category);
      expect(copy.note, 'bring camera');
    });

    test('fromJson parses correctly', () {
      final item = BucketItem.fromJson({
        'id': 'i1',
        'name': 'Tlawng River',
        'category': 'spot',
        'isChecked': false,
      });

      expect(item.name, 'Tlawng River');
      expect(item.category, BucketCategory.spot);
      expect(item.isChecked, isFalse);
    });

    test('toJson serialises back correctly', () {
      final item = makeItem();
      final json = item.toJson();
      expect(json['id'], 'item1');
      expect(json['name'], 'Visit Phawngpui');
      expect(json['category'], 'spot');
      expect(json['isChecked'], isFalse);
    });

    test('toJson / fromJson round-trip is consistent', () {
      final original = BucketItem(
        id: 'rt1',
        name: 'Murlen National Park',
        category: BucketCategory.adventure,
        note: 'pack light',
        isChecked: true,
        checkedByUserId: 'u2',
        checkedByUserName: 'Vanlal',
      );
      final json = original.toJson();
      final restored = BucketItem.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.note, original.note);
      expect(restored.isChecked, original.isChecked);
      expect(restored.checkedByUserId, original.checkedByUserId);
    });

    test('displayCategory returns category label when not other', () {
      final item = makeItem();
      expect(item.displayCategory, BucketCategory.spot.label);
    });

    test('displayCategory returns customCategory when category is other', () {
      final item = BucketItem(
        id: 'ci',
        name: 'Custom Thing',
        category: BucketCategory.other,
        customCategory: 'Street Food',
      );
      expect(item.displayCategory, 'Street Food');
    });
  });

  // ── BucketListModel ───────────────────────────────────────────────────────

  group('BucketListModel', () {
    BucketListModel makeModel({List<BucketItem> items = const []}) =>
        BucketListModel(
          id: 'bl1',
          title: 'Must Visit Mizoram',
          description: 'Top spots',
          bannerUrl: '',
          category: BucketCategory.spot,
          visibility: BucketVisibility.public,
          maxMembers: 6,
          joinCode: 'ABC123',
          hostId: 'host1',
          hostName: 'Lal',
          items: items,
          members: const [],
          createdAt: DateTime(2024),
        );

    test('checkedCount counts only checked items', () {
      final model = makeModel(
        items: [
          BucketItem(
            id: 'i1',
            name: 'a',
            category: BucketCategory.spot,
            isChecked: false,
          ),
          BucketItem(
            id: 'i2',
            name: 'b',
            category: BucketCategory.cafe,
            isChecked: true,
          ),
          BucketItem(
            id: 'i3',
            name: 'c',
            category: BucketCategory.hotel,
            isChecked: true,
          ),
        ],
      );
      expect(model.checkedCount, 2);
    });

    test('progress is 0.0 for empty items list', () {
      expect(makeModel().progress, 0.0);
    });

    test('progress is 1.0 when all items checked', () {
      final model = makeModel(
        items: [
          BucketItem(
            id: 'i1',
            name: 'a',
            category: BucketCategory.spot,
            isChecked: true,
          ),
        ],
      );
      expect(model.progress, 1.0);
    });

    test('progress is 0.5 when half items checked', () {
      final model = makeModel(
        items: [
          BucketItem(
            id: 'i1',
            name: 'a',
            category: BucketCategory.spot,
            isChecked: true,
          ),
          BucketItem(
            id: 'i2',
            name: 'b',
            category: BucketCategory.cafe,
            isChecked: false,
          ),
        ],
      );
      expect(model.progress, 0.5);
    });

    test('isCompleted is false for empty list', () {
      expect(makeModel().isCompleted, isFalse);
    });

    test('isCompleted is true when all items are checked', () {
      final model = makeModel(
        items: [
          BucketItem(
            id: 'i1',
            name: 'a',
            category: BucketCategory.spot,
            isChecked: true,
          ),
        ],
      );
      expect(model.isCompleted, isTrue);
    });

    test('isCompleted is false when some items unchecked', () {
      final model = makeModel(
        items: [
          BucketItem(
            id: 'i1',
            name: 'a',
            category: BucketCategory.spot,
            isChecked: true,
          ),
          BucketItem(
            id: 'i2',
            name: 'b',
            category: BucketCategory.cafe,
            isChecked: false,
          ),
        ],
      );
      expect(model.isCompleted, isFalse);
    });

    test('isHost returns true for hostId match', () {
      expect(makeModel().isHost('host1'), isTrue);
      expect(makeModel().isHost('other'), isFalse);
    });

    test('displayCategory returns label for non-other category', () {
      expect(makeModel().displayCategory, BucketCategory.spot.label);
    });

    test('displayCategory returns customCategory when category is other', () {
      final model = BucketListModel(
        id: 'bl2',
        title: 'T',
        description: '',
        bannerUrl: '',
        category: BucketCategory.other,
        customCategory: 'Waterfalls',
        visibility: BucketVisibility.private,
        maxMembers: 2,
        joinCode: 'XYZ',
        hostId: 'h',
        hostName: 'H',
        items: const [],
        members: const [],
        createdAt: DateTime(2024),
      );
      expect(model.displayCategory, 'Waterfalls');
    });

    test('copyWith updates title only', () {
      final copy = makeModel().copyWith(title: 'New Title');
      expect(copy.title, 'New Title');
      expect(copy.hostId, 'host1');
    });

    test('copyWith updates items', () {
      final items = [
        BucketItem(
          id: 'i1',
          name: 'x',
          category: BucketCategory.spot,
          isChecked: false,
        ),
      ];
      final copy = makeModel().copyWith(items: items);
      expect(copy.items.length, 1);
    });
  });
}
