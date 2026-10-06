import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'paged_posts.dart';
import 'repositories/post_repository.dart';

export 'network_errors.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>((ref) =>
    PostRepository(ref.watch(dioProvider)));

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(() {
  return PostListNotifier();
});

final postDetailProvider = FutureProvider.family<Post, int>((ref, id) async {
  // 1. Cek dari state postListProvider di memori
  final listState = ref.read(postListProvider);
  if (listState.hasValue && listState.value != null) {
    final matches = listState.value!.where((p) => p.id == id);
    if (matches.isNotEmpty) {
      return matches.first;
    }
  }

  // 2. Cek dari state pagedPostsProvider di memori
  final pagedState = ref.read(pagedPostsProvider);
  final pagedMatches = pagedState.items.where((p) => p.id == id);
  if (pagedMatches.isNotEmpty) {
    return pagedMatches.first;
  }

  // 3. Jika tidak ada di memori, panggil via PostRepository
  final repository = ref.read(postRepositoryProvider);
  return repository.fetchPost(id);
});

Future<List<Post>> readPostsOnce(ProviderContainer container) async {
  container.read(postListProvider);
  await Future.delayed(Duration.zero);
  return container.read(postListProvider).requireValue;
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) async {
  container.read(postListProvider);
  await Future.delayed(Duration.zero);
  return container.read(postListProvider).error;
}
