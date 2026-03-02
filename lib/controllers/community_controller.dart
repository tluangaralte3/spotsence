import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_models.dart';
import '../models/gamification_models.dart';
import '../services/community_service.dart';

// ── Community Posts ───────────────────────────────────────────────────────────

class PostsState {
  final List<CommunityPost> posts;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  PostsState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) => PostsState(
    posts: posts ?? this.posts,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
    error: error,
  );
}

class PostsController extends Notifier<PostsState> {
  CommunityService get _service => ref.read(communityServiceProvider);

  @override
  PostsState build() {
    Future.microtask(() => loadMore());
    return const PostsState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.getPosts(page: state.page);
    result.when(
      ok: (newPosts) => state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: result.meta?.hasMore ?? false,
        page: state.page + 1,
      ),
      err: (msg) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> refresh() async {
    state = const PostsState();
    await loadMore();
  }

  Future<void> toggleLike(String postId, String currentUserId) async {
    // Optimistic update
    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final updated = state.posts[idx].toggleLike(currentUserId);
    final newPosts = List<CommunityPost>.from(state.posts)..[idx] = updated;
    state = state.copyWith(posts: newPosts);

    // API call (rollback on failure)
    final result = await _service.toggleLike(postId);
    if (result.isErr) {
      // rollback
      final rolled = state.posts[idx].toggleLike(currentUserId);
      final rb = List<CommunityPost>.from(state.posts)..[idx] = rolled;
      state = state.copyWith(posts: rb);
    }
  }

  Future<String?> createPost({
    required String content,
    required String type,
    List<String>? images,
    String? spotId,
    String? spotName,
    String? location,
  }) async {
    final result = await _service.createPost(
      content: content,
      type: type,
      images: images,
      spotId: spotId,
      spotName: spotName,
      location: location,
    );
    return result.when(
      ok: (post) {
        state = state.copyWith(posts: [post, ...state.posts]);
        return null;
      },
      err: (msg) => msg,
    );
  }
}

final postsControllerProvider = NotifierProvider<PostsController, PostsState>(
  PostsController.new,
);

// ── Bucket Lists ──────────────────────────────────────────────────────────────

final bucketListsProvider = FutureProvider<List<BucketList>>((ref) async {
  final result = await ref.read(communityServiceProvider).getBucketLists();
  return result.when(ok: (list) => list, err: (_) => []);
});

// ── Dilemmas ──────────────────────────────────────────────────────────────────

class DilemmasController extends Notifier<List<Dilemma>> {
  @override
  List<Dilemma> build() {
    Future.microtask(() => _load());
    return [];
  }

  Future<void> _load() async {
    final result = await ref.read(communityServiceProvider).getDilemmas();
    result.when(ok: (list) => state = list, err: (_) {});
  }

  Future<void> vote(String dilemmaId, String option, String uid) async {
    final result = await ref
        .read(communityServiceProvider)
        .voteDilemma(dilemmaId, option);
    if (result.isOk) {
      // Update local state optimistically
      state = state.map((d) {
        if (d.id != dilemmaId) return d;
        final votesA = option == 'A' ? [...d.votesA, uid] : d.votesA;
        final votesB = option == 'B' ? [...d.votesB, uid] : d.votesB;
        return Dilemma(
          id: d.id,
          question: d.question,
          optionA: d.optionA,
          optionB: d.optionB,
          votesA: votesA,
          votesB: votesB,
          authorId: d.authorId,
          authorName: d.authorName,
          status: d.status,
          createdAt: d.createdAt,
        );
      }).toList();
    }
  }
}

final dilemmasControllerProvider =
    NotifierProvider<DilemmasController, List<Dilemma>>(DilemmasController.new);

// ── Leaderboard ───────────────────────────────────────────────────────────────

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final result = await ref
      .read(communityServiceProvider)
      .getLeaderboard(limit: 50);
  return result.when(ok: (list) => list, err: (_) => []);
});
