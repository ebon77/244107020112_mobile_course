import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Deklarasi Notifier menggunakan AsyncNotifier (Modern Riverpod API)
// Tidak menggunakan StateProvider atau StateNotifierProvider yang sudah usang.
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    // Simulasi delay jaringan (loading) selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi kemungkinan gagal 30% menggunakan Random
    final isSuccess = Random().nextDouble() > 0.3;
    if (!isSuccess) {
      throw Exception('Gagal mengambil data statistik server.');
    }

    // Jika sukses (70%), kembalikan 3 item data (state akan diubah secara immutable)
    return ['Statistik Pengguna: 1.2M', 'Pendapatan: \$45K', 'Server Uptime: 99.9%'];
  }
}

// 2. Deklarasi Provider dengan tipe eksplisit (AsyncNotifierProvider)
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);

// 3. UI menggunakan ConsumerWidget
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch HANYA digunakan di dalam metode build untuk memantau perubahan state
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Statistik')),
      // Menangani ketiga kondisi state AsyncValue: loading, error, dan data (success)
      body: statsAsync.when(
        // Kondisi 1: Menangani loading (spinner)
        loading: () => const Center(
          child: CircularProgressIndicator(), 
        ),
        // Kondisi 2: Menangani error (pesan + tombol retry)
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                // ref.invalidate digunakan di dalam callback untuk menjalankan ulang provider
                onPressed: () => ref.invalidate(statsProvider), 
                child: const Text('Retry'), 
              ),
            ],
          ),
        ),
        // Kondisi 3: Menangani success (ListView 3 item)
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.analytics),
            title: Text(stats[index]), 
          ),
        ),
      ),
    );
  }
}
