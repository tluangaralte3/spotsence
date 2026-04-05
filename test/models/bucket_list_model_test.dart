// test/models/bucket_list_model_test.dart
//
// Unit tests for BucketCategory enum and BucketListItem model helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:xplooria/models/bucket_list_models.dart';

void main() {
  // ── BucketCategory enum ──────────────────────────────────────────────────

  group('BucketCategory', () {
    test('all values have non-empty label', () {
      for (final c in BucketCategory.values) {
        expect(c.label, isNotEmpty, reason: '${c.name}.label must not be empty');
      }
    });

    test('all values have non-empty emoji', () {
      for (final c in BucketCategory.values) {
        expect(c.emoji, isNotEmpty, reason: '${c.name}.emoji must not be empty');
      }
    });

    test('specific label mappings', () {
      expect(BucketCategory.spot.label, 'Tourist Spot');
      expect(BucketCategory.restaurant.label, 'Restaurant');
      expect(BucketCategory.cafe.label, 'Café');
      expect(BucketCategory.hotel.label, 'Hotel');
      expect(BucketCategory.homestay.label, 'Homestay');
      expect(BucketCategory.adventure.label, 'Adventure');
      expect(BucketCategory.shopping.label, 'Shopping');
      expect(BucketCategory.event.label, 'Event');
      expect(BucketCategory.other.label, 'Other');
    });

    test('specific emoji mappings', () {
      expect(BucketCategory.spot.emoji, '📍');
      expect(BucketCategory.restaurant.emoji, '🍽️');
      expect(BucketCategory.cafe.emoji, '☕');
      expect(BucketCategory.hotel.emoji, '🏨');
      expect(BucketCategory.homestay.emoji, '🏡');
      expect(BucketCategory.adventure.emoji, '🧗');
      expect(BucketCategory.shopping.emoji, '🛍️');
      expect(BucketCategory.event.emoji, '🎉');
      expect(BucketCategory.other.emoji, '📌');
    });

    test('all values have a non-null icon', () {
      for (final c in BucketCategory.values) {
        // IconData is a value type; just verify it is accessible
        expect(c.icon, isNotNull, reason: '${c.name}.icon must not be null');
      }
    });

    group('fromString', () {
      test('resolves exact enum names', () {
        expect(BucketCategory.fromString('spot'), BucketCategory.spot);
        expect(BucketCategory.fromString('restaurant'), BucketCategory.restaurant);
        expect(BucketCategory.fromString('cafe'), BucketCategory.cafe);
        expect(BucketCategory.fromString('hotel'), BucketCategory.hotel);
        expect(BucketCategory.fromString('adventure'), BucketCategory.adventure);
        expect(BucketCategory.fromString('shopping'), BucketCategory.shopping);
        expect(BucketCategory.fromString('event'), BucketCategory.event);
      });

      test('is case-insensitive', () {
        expect(BucketCategory.fromString('SPOT'), BucketCategory.spot);
        expect(BucketCategory.fromString('Restaurant'), BucketCategory.restaurant);
      });

      test('falls back to other for unknown values', () {
        expect(BucketCategory.fromString('unknown'), BucketCategory.other);
        expect(BucketCategory.fromString(''), BucketCategory.other);
        expect(BucketCategory.fromString('xyz123'), BucketCategory.other);
      });
    });
  });

  // ── BucketItem ────────────────────────────────────────────────────────────

  group('BucketItem', () {
    BucketItem makeItem({
      String id = 'item1',
      String name = 'Phawngpui Peak',
      BucketCategory category = BucketCategory.spot,
      bool isChecked = false,
      String? note,
    }) =>
        BucketItem(
          id: id,
          name: name,
          category: category,
          note: note,
          isChecked: isChecked,
        );

    test('creates item with correct fields', () {
      final item = makeItem();
      expect(item.id, 'item1');
      expect(item.name, 'Phawngpui Peak');
      expect(item.category, BucketCategory.spot);
      expect(item.isChecked, isFalse);
      expect(item.note, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final item = makeItem(name: 'Original', isChecked: false);
      final updated = item.copyWith(isChecked: true);
      expect(updated.name, 'Original');
      expect(updated.isChecked, isTrue);
    });

    test('copyWith can update note', () {
      final item = makeItem();
      final updated = item.copyWith(note: 'Visited in December');
      expect(updated.note, 'Visited in December');
    });

    test('toJson includes all required keys', () {
      final item = makeItem(
        id: 'bk1',
        name: 'Tam Dil',
        category: BucketCategory.adventure,
        isChecked: true,
      );
      final json = item.toJson();
      expect(json['id'], 'bk1');
      expect(json['name'], 'Tam Dil');
      expect(json['category'], 'adventure');
      expect(json['isChecked'], isTrue);
    });

    test('fromJson round-trips correctly', () {
      final original = makeItem(
        id: 'bk2',
        name: 'Vantawng Falls',
        category: BucketCategory.cafe,
        isChecked: false,
        note: 'Must visit',
      );
      final restored = BucketItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.isChecked, original.isChecked);
      expect(restored.note, original.note);
    });

    test('displayCategory returns label for non-other category', () {
      final item = makeItem(category: BucketCategory.restaurant);
      expect(item.displayCategory, 'Restaurant');
    });

    test('displayCategory returns customCategory when category is other', () {
      const item = BucketItem(
        id: 'i1',
        name: 'Custom Place',
        category: BucketCategory.other,
        customCategory: 'Waterfall',
      );
      expect(item.displayCategory, 'Waterfall');
    });
  });

  // ── BucketListModel ───────────────────────────────────────────────────────

  BucketMember makeHost() => BucketMember(
        userId: 'u1',
        userName: 'Lalzama',
        role: MemberRole.host,
        status: MemberStatus.approved,
        joinedAt: DateTime(2024, 1, 1),
      );

  group('BucketListModel derived properties', () {
    BucketListModel makeRoom({
      List<BucketItem> items = const [],
      List<BucketMember>? members,
      int maxMembers = 10,
    }) =>
        BucketListModel(
          id: 'r1',
          title: 'Mizoram Adventures',
          description: 'A bucket list for Mizoram',
          bannerUrl: '',
          category: BucketCategory.adventure,
          visibility: BucketVisibility.private,
          maxMembers: maxMembers,
          joinCode: 'ABC123',
          hostId: 'u1',
          hostName: 'Lalzama',
          items: items,
          members: members ?? [makeHost()],
          createdAt: DateTime(2024, 6, 1),
        );

    test('progress is 0 when no items', () {
      expect(makeRoom().progress, 0.0);
    });

    test('progress is 1.0 when all items checked', () {
      final items = [
        const BucketItem(id: 'i1', name: 'A', category: BucketCategory.spot, isChecked: true),
        const BucketItem(id: 'i2', name: 'B', category: BucketCategory.cafe, isChecked: true),
      ];
      expect(makeRoom(items: items).progress, 1.0);
    });

    test('checkedCount counts only checked items', () {
      final items = [
        const BucketItem(id: 'i1', name: 'A', category: BucketCategory.spot, isChecked: true),
        const BucketItem(id: 'i2', name: 'B', category: BucketCategory.spot, isChecked: false),
        const BucketItem(id: 'i3', name: 'C', category: BucketCategory.spot, isChecked: true),
      ];
      expect(makeRoom(items: items).checkedCount, 2);
    });

    test('isCompleted is false when some items unchecked', () {
      final items = [
        const BucketItem(id: 'i1', name: 'A', category: BucketCategory.spot, isChecked: true),
        const BucketItem(id: 'i2', name: 'B', category: BucketCategory.spot, isChecked: false),
      ];
      expect(makeRoom(items: items).isCompleted, isFalse);
    });

    test('isMember returns true for approved member', () {
      final room = makeRoom();
      expect(room.isMember('u1'), isTrue);
    });

    test('isMember returns false for unknown user', () {
      final room = makeRoom();
      expect(room.isMember('unknown'), isFalse);
    });

    test('isHost returns true for hostId', () {
      final room = makeRoom();
      expect(room.isHost('u1'), isTrue);
      expect(room.isHost('u2'), isFalse);
    });

    test('isFull when approvedCount >= maxMembers', () {
      final members = List.generate(
        3,
        (i) => BucketMember(
          userId: 'u${i + 1}',
          userName: 'User $i',
          role: i == 0 ? MemberRole.host : MemberRole.member,
          status: MemberStatus.approved,
          joinedAt: DateTime(2024),
        ),
      );
      final room = makeRoom(members: members, maxMembers: 3);
      expect(room.isFull, isTrue);
    });

    test('copyWith updates title without changing other fields', () {
      final room = makeRoom();
      final updated = room.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.hostId, room.hostId);
      expect(updated.joinCode, room.joinCode);
    });
  });
}
