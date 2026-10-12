# week6_campus_notify - Praktikum 3: Payload, Tiga App State, Klik dan Topik

## Deskripsi
Implementasi penanganan Push Notification Firebase Cloud Messaging (FCM) pada tiga status aplikasi (Foreground, Background, dan Terminated), penanganan payload navigasi deep link ke rute `/pengumuman/:id`, serta fitur Topic Messaging (`pengumuman-kampus`).

---

## Contoh JSON Payload FCM (HTTP v1)

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

---

## 3. Matriks Pengujian Wajib

| State | Yang Diharapkan | Cara Uji | Status / Hasil |
| :--- | :--- | :--- | :--- |
| **Foreground** | Banner lokal muncul via `flutter_local_notifications`, klik banner mengarahkan ke `/pengumuman/3` | Buka aplikasi di layar, kirim notifikasi dari Firebase Console / backend dengan data `route: /pengumuman/3` | Berhasil (Banner lokal muncul dan diarahkan ke rute `/pengumuman/3`) |
| **Background** | Banner sistem muncul di status bar, klik banner mengarahkan ke rute yang benar (`/pengumuman/3`) | Buka aplikasi lalu tekan tombol Home (aplikasi diminimalkan), kirim notifikasi, lalu klik banner notifikasi | Berhasil (Aplikasi terbuka langsung menuju `/pengumuman/3`) |
| **Terminated** | Aplikasi terbuka dari kondisi tertutup penuh langsung menuju rute yang benar via `getInitialMessage()` | Tutup aplikasi sepenuhnya (swipe-close dari recent apps), kirim notifikasi, klik banner notifikasi | Berhasil (Aplikasi start lalu langsung membuka `/pengumuman/3`) |

---

## 4. Topic Messaging
- Berlangganan topik kampus: `FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus')`
- Berhenti langganan topik: `FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus')`

---

## 5. Audit Arsitektur (Praktikum 1 - Clean Architecture)

### Pemetaan File ke Layer

| File | Layer saat ini | Masalah |
| :--- | :--- | :--- |
| `lib/pages/home_page.dart` | Presentation | Memanggil API (Dio POST `/devices`) langsung di UI, instansiasi Dio manual (`BaseOptions`), serta memanggil push service langsung di widget state. |
| `lib/pages/announcement_page.dart` | Presentation | Konten pengumuman masih hardcoded di UI, belum menggunakan Entity domain atau State Management pengumuman. |
| `lib/pages/login_page.dart` | Presentation | File masih kosong (stub) belum terimplementasi. |
| `lib/data/api_client.dart` | Data | Berisi konfigurasi Dio dan interceptor. Memiliki dependensi konkret ke `TokenStore` dan `AuthRepository` (bukan interface/abstraksi). |
| `lib/data/api_errors.dart` | Data | Error handling terikat kuat dengan `DioException`, belum diabstraksikan ke Failure domain (murni Dart). |
| `lib/data/auth_repository.dart` | Data (+ kontrak tercampur) | Interface dan implementasi masih digabung dalam satu kelas konkret; Model `AuthSession` tercampur di data layer tanpa domain entity. |
| `lib/data/token_store.dart` | Data | Mengakses `FlutterSecureStorage` langsung tanpa kontrak/interface DataSource. |
| `lib/providers/auth_provider.dart` | Presentation (State) | DI bocor: Melakukan instansiasi langsung kelas konkret `AuthRepository()` dan `TokenStore()` tanpa abstraksi interface. |
| `lib/messaging/push_service.dart` | Infrastructure / Data | God class (SRP violation): Mencampur FCM, local notifications, routing GoRouter, penyimpanan secure storage, dan HTTP network call Dio di satu tempat. |
| `lib/routes.dart` | Core / Routing | Berisi konfigurasi rute dan helper parsing rute notifikasi. |
| `lib/main.dart` | Bootstrap / Core | Inisialisasi awal aplikasi (Firebase, GoRouter, Riverpod ProviderScope). |

### Temuan 3 Pelanggaran Klasik

1. **Widget menyentuh jaringan/database langsung:**
   - `lib/pages/home_page.dart` (baris 22 & 56): Memanggil `Dio(BaseOptions(...))` dan melakukan HTTP request `dio.post('/devices', ...)`.
2. **Logika bisnis di UI (`DateFormat`, `jsonDecode`, `.toIso8601String`):**
   - Tidak ditemukan pemanggilan `DateFormat`, `jsonDecode`, atau `.toIso8601String` pada `lib/pages/` (0 temuan). Namun, terdapat formatting manual string token (`token.substring(0, 14)...`) langsung di UI widget.
3. **Dependency Injection bocor (Instansiasi manual):**
   - `lib/pages/home_page.dart` (baris 22): Instansiasi manual `Dio(BaseOptions(...))` di UI layer.
   - `lib/providers/auth_provider.dart` (baris 5 & 6): Instansiasi manual `TokenStore()` dan `AuthRepository()`.

