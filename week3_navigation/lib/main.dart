import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mengimpor file StatsPage yang baru dibuat
import 'pages/stats_page.dart'; 

void main() {
  // Aplikasi wajib dibungkus ProviderScope agar state Riverpod bisa dibaca
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Challenge - Stats',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      // Mengubah halaman utama (home) menjadi StatsPage
      home: const StatsPage(), 
    );
  }
}