import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sesuaikan import ini dengan nama project Anda
// import 'package:week3_todo/pages/stats_page.dart'; 

void main() {
  test('StatsNotifier memancarkan status loading lalu data atau error secara acak', () async {
    // 1. Buat ProviderContainer untuk menampung dan menguji state secara terisolasi
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 2. Verifikasi state awal adalah AsyncLoading sebelum delay selesai
    expect(
      container.read(statsProvider),
      const AsyncLoading<List<String>>(),
      reason: 'State pertama saat provider dibaca haruslah loading.',
    );

    // 3. Tunggu proses asinkron (delay 2 detik) selesai
    try {
      final data = await container.read(statsProvider.future);
      
      // 4a. Jika lolos dari peluang error 30% (sukses), pastikan state berupa AsyncData
      expect(container.read(statsProvider).value, equals(data));
      // Verifikasi data success memiliki 3 item
      expect(data.length, 3);
      
    } catch (e) {
      // 4b. Jika masuk ke peluang error 30% (gagal), pastikan state berupa AsyncError
      expect(container.read(statsProvider).hasError, isTrue);
      expect(
        container.read(statsProvider).error.toString(), 
        contains('Gagal mengambil data statistik server.'),
      );
    }
  });
}