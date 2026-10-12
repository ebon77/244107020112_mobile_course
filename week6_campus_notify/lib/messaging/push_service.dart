import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../main.dart'; // import appRouter

// ============================================================================
// 1. TOP-LEVEL BACKGROUND HANDLER
// ⚠️ ATURAN KRUSIAL: TIDAK BOLEH MENGAKSES BuildContext ATAU Riverpod!
// Alasan: Fungsi ini dieksekusi di Isolate Dart terpisah saat aplikasi mati/background.
// Tidak ada widget tree, Navigator, atau BuildContext yang aktif di sini.
// ============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Wajib inisialisasi Firebase jika background task membutuhkan akses resource Firebase
  await Firebase.initializeApp();
  debugPrint('📥 [Background FCM] Pesan diterima: ${message.messageId}');
  // ⛔ JANGAN panggil context.go() / Navigator.push() / ref.read() di sini!
  // Navigasi HANYA dilakukan saat user mengklik notifikasi (melalui onMessageOpenedApp / getInitialMessage).
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================
final pushServiceProvider = Provider<PushService>((ref) {
  final router = ref.watch(routerProvider);
  return PushService(router: router);
});

// ============================================================================
// PUSH SERVICE CLASS
// ============================================================================
class PushService {
  PushService({
    required this.router,
    Dio? dioClient,
    FlutterSecureStorage? storage,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _dio = dioClient ?? Dio(BaseOptions(baseUrl: 'https://example-campus-api.test')),
        _storage = storage ?? const FlutterSecureStorage(),
        _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final GoRouter router;
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final FlutterLocalNotificationsPlugin _local;

  static const String topicPengumuman = 'pengumuman-kampus';
  static const String channelId = 'pengumuman';
  static const String channelName = 'Pengumuman Kampus';

  String? _pendingDeepLink;

  /// Inisialisasi lengkap Push Service
  Future<void> initialize() async {
    // 1. Registrasi handler background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request izin notifikasi
    await requestPermission();

    // 3. Konfigurasi channel & local notifications (Foreground)
    await _initLocalNotifications();

    // 4. Setup listeners untuk 3 App States
    _setupForegroundListener();
    _setupBackgroundClickListener();
    await _handleTerminatedNotification();

    // 5. Setup Token FCM (get + refresh listener) & langganan topik
    await _setupTokenAndTopic();
  }

  // ==========================================================================
  // A. REQUEST PERMISSION
  // 🔄 PERBEDAAN ANDROID 13+ VS iOS:
  // - iOS: Memerlukan prompt native APNs (alert, badge, sound).
  // - Android 13+ (API 33+): Memerlukan izin runtime POST_NOTIFICATIONS
  //   yang diminta via FlutterLocalNotificationsPlugin / requestPermission.
  // - Android 12 ke bawah: Izin otomatis diberikan saat install aplikasi.
  // ==========================================================================
  Future<bool> requestPermission() async {
    // [iOS & Android] Permintaan izin FCM standar
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 🔄 [KHUSUS ANDROID 13+] Minta izin POST_NOTIFICATIONS eksplisit
    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    // 🔄 [KHUSUS iOS] Konfigurasi agar banner tetap muncul di foreground (jika didukung APNs)
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ==========================================================================
  // B. LOCAL NOTIFICATIONS SETUP
  // 🔄 PERBEDAAN ANDROID VS iOS:
  // - Android 8.0+: Wajib mendaftarkan AndroidNotificationChannel berprioritas tinggi.
  // - iOS: Memerlukan DarwinInitializationSettings.
  // ==========================================================================
  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Klik banner lokal foreground -> arahkan rute
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _pendingDeepLink = payload;
          _navigate(payload);
        }
      },
    );

    // 🔄 [KHUSUS ANDROID 8+] Buat Notification Channel
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Channel notifikasi resmi kampus',
        importance: Importance.max,
      );

      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(androidChannel);
    }
  }

  // ==========================================================================
  // C. FOREGROUND LISTENER (onMessage)
  // Saat aplikasi AKTIF di layar, FCM tidak memunculkan banner pop-up otomatis.
  // Kita harus menampilkannya secara manual menggunakan local notifications.
  // ==========================================================================
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🔔 [Foreground FCM] Pesan masuk: ${message.notification?.title}');

      final route = message.data['route'] ?? '/';
      final title = message.notification?.title ?? 'Pengumuman';
      final body = message.notification?.body ?? '';

      // Tampilkan notifikasi banner lokal manual
      await _local.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Channel notifikasi resmi kampus',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: route,
      );
    });
  }

  // ==========================================================================
  // D. BACKGROUND CLICK LISTENER (onMessageOpenedApp)
  // Aplikasi di latar belakang (diminimalkan) -> user klik notifikasi sistem tray
  // ==========================================================================
  void _setupBackgroundClickListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 [Background Click] Membuka pesan dari tray');
      final route = message.data['route'];
      if (route != null && route.isNotEmpty) {
        _navigate(route);
      }
    });
  }

  // ==========================================================================
  // E. TERMINATED HANDLER (getInitialMessage)
  // Aplikasi dalam keadaan MATI TOTAL (Terminated) -> user klik notifikasi
  // ==========================================================================
  Future<void> _handleTerminatedNotification() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 [Terminated Launch] Cold start dari notifikasi');
      final route = initialMessage.data['route'];
      if (route != null && route.isNotEmpty) {
        _navigate(route);
      }
    }

    if (_pendingDeepLink != null) {
      _navigate(_pendingDeepLink!);
      _pendingDeepLink = null;
    }
  }

  // ==========================================================================
  // F. TOKEN MANAGEMENT (getToken, onTokenRefresh, & POST /devices)
  // Token disimpan di flutter_secure_storage dan dikirim ke backend server.
  // ==========================================================================
  Future<void> _setupTokenAndTopic() async {
    // 1. Ambil token perangkat saat ini
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _syncTokenToBackend(token);
    }

    // 2. Pasang listener token refresh (jika reinstall / token expired)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _syncTokenToBackend(newToken);
    });

    // 3. Otomatis subscribe ke topik default
    await subscribeToTopic(topicPengumuman);
  }

  Future<void> _syncTokenToBackend(String token) async {
    // Simpan ke Secure Storage
    await _storage.write(key: 'fcm_token', value: token);

    // Kirim ke endpoint backend: POST /devices
    try {
      final platformName = Platform.isAndroid ? 'android' : 'ios';
      await _dio.post('/devices', data: {
        'fcm_token': token,
        'platform': platformName,
      });
      debugPrint('✅ [Backend Sync] Token berhasil dikirim ke /devices: $token');
    } catch (e) {
      debugPrint('⚠️ [Backend Sync Error] Gagal kirim token ke server: $e');
    }
  }

  // ==========================================================================
  // G. TOPIC MESSAGING (subscribe / unsubscribe 'pengumuman-kampus')
  // ==========================================================================
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('📢 Berlangganan topik: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('🔇 Berhenti langganan topik: $topic');
  }

  // ==========================================================================
  // ⚠️ ATURAN NAVIGASI: HINDARI DEPENDENSI LANGSUNG BuildContext
  // Menggunakan GoRouter instance langsung agar navigasi aman dijalankan
  // dari callback FCM asynchronous kapan pun tanpa crash BuildContext!
  // ==========================================================================
  void _navigate(String route) {
    try {
      router.go(route);
    } catch (e) {
      debugPrint('Navigasi error: $e');
    }
  }
}

// ============================================================================
// TOP-LEVEL CONVENIENCE DELEGATES (Untuk kemudahan pemanggilan langsung di UI)
// ============================================================================
final PushService defaultPushService = PushService(router: appRouter);

Future<bool> requestNotificationPermission() => defaultPushService.requestPermission();

Future<void> initLocalNotifications([void Function(String route)? onNotificationTap]) async {
  await defaultPushService._initLocalNotifications();
}

void listenForeground(void Function(String route) go) {
  defaultPushService._setupForegroundListener();
}

Future<void> handleTerminated(void Function(String route) go) async {
  await defaultPushService._handleTerminatedNotification();
}

Future<void> initFcmToken({required Future<void> Function(String token) onToken}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
  await defaultPushService.subscribeToTopic(PushService.topicPengumuman);
}

Future<void> subscribeToTopic(String topic) => defaultPushService.subscribeToTopic(topic);
Future<void> unsubscribeFromTopic(String topic) => defaultPushService.unsubscribeFromTopic(topic);