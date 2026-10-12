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
