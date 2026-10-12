import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'messaging/push_service.dart';

import 'pages/home_page.dart'; 
import 'pages/announcement_page.dart';

// GoRouter dengan rute beranda dan detail pengumuman (Praktikum 3)
final appRouter = GoRouter(
  initialLocation: '/', 
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(title: 'Campus Notify'),
    ),
    GoRoute(
      path: '/pengumuman/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return AnnouncementPage(id: id);
      },
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) => appRouter);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  
  // 1. Background handler wajib top-level (Praktikum 3)
  registerBackgroundHandler();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router, 
    );
  }
}