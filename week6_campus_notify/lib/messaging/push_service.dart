import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../main.dart';
import '../routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

final pushServiceProvider = Provider<PushService>((ref) {
  final router = ref.watch(routerProvider);
  return PushService(router: router);
});

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

  Future<void> initialize() async {
    registerBackgroundHandler();
    await requestPermission();
    await _initLocalNotifications();
    _setupForegroundListener();
    _setupBackgroundClickListener();
    await _handleTerminatedNotification();
    await _setupTokenAndTopic();
  }

  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

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

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _pendingDeepLink = payload;
          _navigate(payload);
        }
      },
    );

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

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final route = routeFromMessage(message.data);
      final title = message.notification?.title ?? 'Pengumuman';
      final body = message.notification?.body ?? '';

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

  void _setupBackgroundClickListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = routeFromMessage(message.data);
      _navigate(route);
    });
  }

  Future<void> _handleTerminatedNotification() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final route = routeFromMessage(initialMessage.data);
      _navigate(route);
    }

    if (_pendingDeepLink != null) {
      _navigate(_pendingDeepLink!);
      _pendingDeepLink = null;
    }
  }

  Future<void> _setupTokenAndTopic() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _syncTokenToBackend(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _syncTokenToBackend(newToken);
    });

    await subscribeToTopic(topicPengumuman);
  }

  Future<void> _syncTokenToBackend(String token) async {
    await _storage.write(key: 'fcm_token', value: token);

    try {
      final platformName = Platform.isAndroid ? 'android' : 'ios';
      await _dio.post('/devices', data: {
        'fcm_token': token,
        'platform': platformName,
      });
    } catch (e) {
      debugPrint('Sync token error: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  void _navigate(String route) {
    try {
      router.go(route);
    } catch (e) {
      debugPrint('Navigate error: $e');
    }
  }
}

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