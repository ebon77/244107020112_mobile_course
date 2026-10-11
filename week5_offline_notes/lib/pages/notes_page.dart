import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Masukkan judul catatan',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                hintText: 'Tulis isi catatan di sini',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isNotEmpty) {
                await ref
                    .read(noteRepositoryProvider)
                    .addNote(title: title, body: body);
                ref.invalidate(notesProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Catatan',
            onPressed: () async {
              final repo = ref.read(noteRepositoryProvider);
              final count = await syncNotes(repo);
              ref.invalidate(notesProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? '$count catatan berhasil disinkronkan!'
                          : 'Semua catatan sudah tersinkron.',
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terjadi kesalahan: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(notesProvider),
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada catatan.\nTekan tombol + untuk menambahkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return NoteTile(
                  note: note,
                  onTap: () async {
                    await context.push('/note/${note.id}');
                    ref.invalidate(notesProvider);
                  },
                  onDelete: () async {
                    await ref
                        .read(noteRepositoryProvider)
                        .deleteNote(note.id!);
                    ref.invalidate(notesProvider);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
