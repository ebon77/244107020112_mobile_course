import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repositories.dart';

final Dio _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));

// Bagian 1: Cache-first read untuk data API
Future<List<Post>> loadPostsCacheFirst({
  Future<Database> Function()? openDb,
  Dio? dio,
}) async {
  final cached = await readCachedPosts(openDb: openDb); // dari tabel cached_posts
  // 1. Segera kembalikan cache agar UI tidak blank saat offline.
  // 2. Di background: fetch Dio -> simpan ke cached_posts -> invalidate provider.
  refreshPostsInBackground(openDb: openDb, dio: dio);
  return cached;
}

Future<List<Post>> readCachedPosts({Future<Database> Function()? openDb}) async {
  final db = await (openDb ?? openNotesDb)();
  final rows = await db.query('cached_posts');
  if (rows.isEmpty) return [];

  return rows.map((row) {
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return Post.fromJson(payload);
  }).toList();
}

Future<void> refreshPostsInBackground({
  Future<Database> Function()? openDb,
  Dio? dio,
}) async {
  try {
    final client = dio ?? _dio;
    final response = await client.get('/posts');
    final List data = response.data;

    final db = await (openDb ?? openNotesDb)();
    final batch = db.batch();

    batch.delete('cached_posts');

    for (var item in data) {
      batch.insert('cached_posts', {
        'id': item['id'],
        'payload': jsonEncode(item),
        'cached_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  } catch (e) {
    // ignore: avoid_print
    print("Gagal refresh background: $e");
  }
}

// Bagian 2: Sinkronisasi catatan kotor (dirty)
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
