import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'messaging/push_service.dart';
import 'routes.dart';
import 'pages/home_page.dart'; 
import 'pages/announcement_page.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.home, 
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(title: 'Campus Notify'),
    ),
    GoRoute(
      path: AppRoutes.announcement,
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