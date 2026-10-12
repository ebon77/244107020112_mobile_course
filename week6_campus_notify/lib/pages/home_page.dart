import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, this.title = 'Campus Notify'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _fcmTokenDisplay = 'Mengambil token...';
  String? _fullToken;
  bool _isSubscribedTopic = true;
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  Future<void> _setupFcm() async {
    await requestNotificationPermission();

    await initLocalNotifications((route) {
      if (mounted) context.go(route);
    });

    listenForeground((route) {
      if (mounted) context.go(route);
    });

    await handleTerminated((route) {
      if (mounted) context.go(route);
    });

    await initFcmToken(
      onToken: (token) async {
        if (!mounted) return;
        setState(() {
          _fullToken = token;
          _fcmTokenDisplay = token.length > 14
              ? '${token.substring(0, 14)}...'
              : token;
        });

        try {
          await dio.post('/devices', data: {
            'fcm_token': token,
            'platform': 'android',
          });
        } catch (_) {}
      },
    );
  }

  Future<void> _toggleTopic() async {
    if (_isSubscribedTopic) {
      await unsubscribeFromTopic('pengumuman-kampus');
      setState(() => _isSubscribedTopic = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhenti langganan: pengumuman-kampus')),
        );
      }
    } else {
      await subscribeToTopic('pengumuman-kampus');
      setState(() => _isSubscribedTopic = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil langganan topik: pengumuman-kampus')),
        );
      }
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'FCM Token (Perangkat):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _fcmTokenDisplay,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_fullToken != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _fullToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token FCM lengkap disalin ke clipboard!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Salin Token Lengkap'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Icon(
                  _isSubscribedTopic ? Icons.notifications_active : Icons.notifications_off,
                  color: _isSubscribedTopic ? Colors.green : Colors.grey,
                  size: 32,
                ),
                title: const Text(
                  'Topik: pengumuman-kampus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isSubscribedTopic ? 'Status: Berlangganan (Subscribed)' : 'Status: Tidak Berlangganan',
                ),
                trailing: ElevatedButton(
                  onPressed: _toggleTopic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubscribedTopic ? Colors.red.shade100 : Colors.green.shade100,
                    foregroundColor: _isSubscribedTopic ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                  child: Text(_isSubscribedTopic ? 'Unsubscribe' : 'Subscribe'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uji Coba Rute Tujuan Notifikasi:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Rute target payload: /pengumuman/3',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.announcementDetail('3')),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Buka Halaman /pengumuman/3'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}