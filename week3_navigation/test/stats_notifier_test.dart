import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import file stats_page.dart dari project week3_navigation Anda
import 'package:week3_navigation/pages/stats_page.dart'; 

void main() {
  test('StatsNotifier memancarkan status loading lalu data atau error secara acak', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(statsProvider),
      const AsyncLoading<List<String>>(),
      reason: 'State pertama saat provider dibaca haruslah loading.',
    );

    try {
      final data = await container.read(statsProvider.future);
      
      expect(container.read(statsProvider).value, equals(data));
      // Tambahkan tanda seru (!) agar compiler tahu data tidak null
      expect(data.length, 3); 
      
    } catch (e) {
      expect(container.read(statsProvider).hasError, isTrue);
      expect(
        container.read(statsProvider).error.toString(), 
        contains('Gagal mengambil data statistik server.'),
      );
    }
  });
}