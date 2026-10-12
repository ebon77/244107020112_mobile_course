import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, this.title = 'Campus Notify'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _fcmTokenDisplay = 'Mengambil token...';
  String? _fullToken;
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  Future<void> _setupFcm() async {
    await requestNotificationPermission();
    await initLocalNotifications();
    await initFcmToken(
      onToken: (token) async {
        if (!mounted) return;
        setState(() {
          _fullToken = token;
          _fcmTokenDisplay = token.length > 12 
              ? '${token.substring(0, 12)}...' 
              : token;
        });

        try {
          await dio.post('/devices', data: {
            'fcm_token': token,
            'platform': 'android', 
          });
          debugPrint('Berhasil kirim token penuh ke backend: $token');
        } catch (e) {
          debugPrint('Simulasi kirim token: $e'); 
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FCM Token (Debug):', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _fcmTokenDisplay,
              style: const TextStyle(fontSize: 22, color: Colors.deepPurple, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_fullToken != null)
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _fullToken!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Token FCM lengkap berhasil disalin!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Salin Token Lengkap untuk Firebase Test'),
              ),
          ],
        ),
      ),
    );
  }
}