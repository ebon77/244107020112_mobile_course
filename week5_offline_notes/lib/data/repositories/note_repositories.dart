import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';
import '../models/post.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }

  Future<int> syncNotes(NoteRepository repo) async {
    final dirtyCount = await repo.countDirty();
    if (dirtyCount == 0) return 0;
    await Future.delayed(const Duration(seconds: 1));
    await repo.markAllSynced();
    return dirtyCount;
  }

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts');
    if (rows.isEmpty) return [];

    return rows.map((row) {
      final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return Post.fromJson(payload);
    }).toList();
  }

  Future<void> refreshPostsInBackground() async {
    try {
      final response = await _dio.get('/posts');
      final List data = response.data;
      
      final db = await _openDb();
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
      print("Gagal refresh background: $e");
    }
  }

  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await readCachedPosts(); 
    refreshPostsInBackground();
    return cached;
  }
}

final _defaultNoteRepository = NoteRepository();

