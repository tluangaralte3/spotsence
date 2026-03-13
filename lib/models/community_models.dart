import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class PostComment {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final String createdAt;

  const PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    comment: json['comment'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
  );
}

@immutable
class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String type; // post | review | tip | question
  final String content;
  final List<String> images;
  final String? spotId;
  final String? spotName;
  final String? location;
  final List<String> likes;
  final List<PostComment> comments;
  final String createdAt;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.type,
    required this.content,
    this.images = const [],
    this.spotId,
    this.spotName,
    this.location,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  int get likeCount => likes.length;
  int get commentCount => comments.length;

  bool isLikedBy(String uid) => likes.contains(uid);

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id: json['id'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    userPhoto: json['userPhoto'] as String?,
    type: json['type'] as String? ?? 'post',
    content: json['content'] as String? ?? '',
    images: List<String>.from(json['images'] as List? ?? []),
    spotId: json['spotId'] as String?,
    spotName: json['spotName'] as String?,
    location: json['location'] as String?,
    likes: List<String>.from(json['likes'] as List? ?? []),
    comments: (json['comments'] as List? ?? [])
        .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: json['createdAt'] as String? ?? '',
  );

  CommunityPost toggleLike(String uid) {
    final newLikes = likes.contains(uid)
        ? likes.where((id) => id != uid).toList()
        : [...likes, uid];
    return CommunityPost(
      id: id,
      userId: userId,
      userName: userName,
      userPhoto: userPhoto,
      type: type,
      content: content,
      images: images,
      spotId: spotId,
      spotName: spotName,
      location: location,
      likes: newLikes,
      comments: comments,
      createdAt: createdAt,
    );
  }
}

@immutable
class BucketListPlace {
  final String spotId;
  final String spotName;
  final String category;
  final bool visited;

  const BucketListPlace({
    required this.spotId,
    required this.spotName,
    required this.category,
    required this.visited,
  });

  factory BucketListPlace.fromJson(Map<String, dynamic> json) =>
      BucketListPlace(
        spotId: json['spotId'] as String? ?? '',
        spotName: json['spotName'] as String? ?? '',
        category: json['category'] as String? ?? '',
        visited: json['visited'] as bool? ?? false,
      );
}

@immutable
class BucketList {
  final String id;
  final String title;
  final String? description;
  final String hostId;
  final String hostName;
  final List<BucketListPlace> places;
  final List<String> participants;
  final int maxParticipants;
  final String status; // open | full | completed
  final String? startDate;
  final String? endDate;
  final String createdAt;

  const BucketList({
    required this.id,
    required this.title,
    this.description,
    required this.hostId,
    required this.hostName,
    required this.places,
    required this.participants,
    required this.maxParticipants,
    required this.status,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  int get visitedCount => places.where((p) => p.visited).length;
  double get progress => places.isEmpty ? 0 : visitedCount / places.length;

  factory BucketList.fromJson(Map<String, dynamic> json) => BucketList(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    hostId: json['hostId'] as String? ?? '',
    hostName: json['hostName'] as String? ?? '',
    places: (json['places'] as List? ?? [])
        .map((e) => BucketListPlace.fromJson(e as Map<String, dynamic>))
        .toList(),
    participants: List<String>.from(json['participants'] as List? ?? []),
    maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 10,
    status: json['status'] as String? ?? 'open',
    startDate: json['startDate'] as String?,
    endDate: json['endDate'] as String?,
    createdAt: json['createdAt'] as String? ?? '',
  );
}

@immutable
class DilemmaOption {
  final String? spotId;
  final String name;
  final String?
  category; // 'spot' | 'cafe' | 'restaurant' | 'hotel' | 'homestay'
  final String? imageUrl;
  final String? district;

  const DilemmaOption({
    this.spotId,
    required this.name,
    this.category,
    this.imageUrl,
    this.district,
  });

  factory DilemmaOption.fromJson(Map<String, dynamic> json) => DilemmaOption(
    spotId: json['spotId'] as String?,
    name: json['name'] as String? ?? '',
    category: json['category'] as String?,
    imageUrl: json['imageUrl'] as String?,
    district: json['district'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (spotId != null) 'spotId': spotId,
    'name': name,
    if (category != null) 'category': category,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (district != null) 'district': district,
  };
}

@immutable
class Dilemma {
  final String id;
  final String question;
  final DilemmaOption optionA;
  final DilemmaOption optionB;
  final List<String> votesA;
  final List<String> votesB;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String status; // 'active' | 'closed'
  /// null = no deadline (open indefinitely)
  final DateTime? expiresAt;
  final DateTime createdAt;

  const Dilemma({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.votesA,
    required this.votesB,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  int get totalVotes => votesA.length + votesB.length;
  double get percentA => totalVotes == 0 ? 0.5 : votesA.length / totalVotes;
  double get percentB => totalVotes == 0 ? 0.5 : votesB.length / totalVotes;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => status == 'active' && !isExpired;

  String? userVote(String uid) {
    if (votesA.contains(uid)) return 'A';
    if (votesB.contains(uid)) return 'B';
    return null;
  }

  factory Dilemma.fromJson(Map<String, dynamic> json) => Dilemma(
    id: json['id'] as String? ?? '',
    question: json['question'] as String? ?? '',
    optionA: DilemmaOption.fromJson(
      json['optionA'] as Map<String, dynamic>? ?? {},
    ),
    optionB: DilemmaOption.fromJson(
      json['optionB'] as Map<String, dynamic>? ?? {},
    ),
    votesA: List<String>.from(json['votesA'] as List? ?? []),
    votesB: List<String>.from(json['votesB'] as List? ?? []),
    authorId: json['authorId'] as String? ?? '',
    authorName: json['authorName'] as String? ?? '',
    authorPhoto: json['authorPhoto'] as String?,
    status: json['status'] as String? ?? 'active',
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.tryParse(json['expiresAt'] as String),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  factory Dilemma.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? expiresAt;
    if (d['expiresAt'] is Timestamp) {
      expiresAt = (d['expiresAt'] as Timestamp).toDate();
    }
    DateTime createdAt = DateTime.now();
    if (d['createdAt'] is Timestamp) {
      createdAt = (d['createdAt'] as Timestamp).toDate();
    }
    return Dilemma(
      id: doc.id,
      question: d['question'] as String? ?? '',
      optionA: DilemmaOption.fromJson(
        d['optionA'] as Map<String, dynamic>? ?? {},
      ),
      optionB: DilemmaOption.fromJson(
        d['optionB'] as Map<String, dynamic>? ?? {},
      ),
      votesA: List<String>.from(d['votesA'] as List? ?? []),
      votesB: List<String>.from(d['votesB'] as List? ?? []),
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      authorPhoto: d['authorPhoto'] as String?,
      status: d['status'] as String? ?? 'active',
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}
