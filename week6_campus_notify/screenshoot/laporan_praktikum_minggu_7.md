# Laporan Praktikum Minggu 7: Clean Architecture & Feature-First
**Nama:** Muhammad Shabran  
**NIM:** 244107020112  
**Pekan ke:** 7  

## 1. Praktikum 1: Audit Layer Project Lama
Sebelum memulai refactoring, saya melakukan komit snapshot awal. Setelah itu, saya mengaudit file-file lama dan memetakannya ke dalam layer saat ini. Saya menemukan beberapa pelanggaran arsitektur klasik seperti pemanggilan `Dio` secara langsung di dalam UI (widget) dan adanya logika *parsing* JSON serta format tanggal di layer *presentation*. 
Saya kemudian menyusun struktur folder baru menggunakan pendekatan *feature-first* di mana fitur `notes` dan `auth` masing-masing memiliki layer `domain`, `data`, dan `presentation` sendiri.

## 2. Praktikum 2: Domain dan Data per Fitur
Pada tahap ini, saya memisahkan logika bisnis dan data untuk fitur catatan (notes):
- **Domain:** Saya membuat *entity* murni (`Note`) yang terbebas dari import Flutter/JSON, menentukan kontrak *interface* di `NoteRepository`, serta membuat *use case* (`GetNotes`). Saya juga membuat *file* `failures.dart` untuk menangani *error* secara spesifik tanpa melempar *exception* mentah.
- **Data:** Saya membuat `NoteModel` yang mewarisi `Note` untuk menangani proses konversi data (`toMap`/`fromMap`), lalu membuat implementasi nyatanya di `NoteRepositoryImpl` yang terhubung dengan SQLite.

## 3. Praktikum 3: Presentation, DI, dan Verifikasi
Saya merapikan layer *presentation* agar murni hanya membaca *state*:
- Saya menggunakan Riverpod sebagai *Dependency Injection* (DI) terpusat pada file `notes_providers.dart` agar *widget* tidak lagi menginisialisasi kelas secara manual.
- File `notes_page.dart` dibersihkan dari logika pengambilan data dan hanya menggunakan `ConsumerWidget` untuk merender tampilan berdasarkan *state* (loading, error, data).
- Saya menjalankan perintah verifikasi (`grep`) dan memastikan layer *presentation* steril dari data mentah, serta layer *domain* steril dari *package* eksternal. Semua *test* dan `flutter analyze` juga telah lolos.

## 4. AI Challenge
Saya meminta bantuan AI untuk merestrukturisasi fitur `auth` dan `announcements` menjadi *feature-first*. Setelah AI memberikan usulan, saya mengevaluasinya secara saksama. Saya menolak beberapa saran AI yang menerapkan *over-engineering* (seperti membuat *use case* untuk sekadar fungsi *get* data satu baris). Pemetaan objek tetap saya pertahankan hanya di dalam *Model*, bukan di *Entity*. Hasil evaluasi dan *trade-off* ini menjadi dasar keputusan final arsitektur aplikasi saya.

## 5. Refactoring, Testing, dan Error Umum
Saya menerapkan pola yang sama ke sisa fitur aplikasi. Logika format tanggal diekstrak menjadi fungsi murni di `lib/core/format.dart` agar mudah diuji. Saya juga membuat *Fake Repository* untuk menguji `GetNotes` secara murni (unit test) tanpa melibatkan database asli, memastikan domain layer aman dari *error* teknis implementasi.

---

## Refleksi Mandiri

**1. Mengapa interface repository harus tinggal di domain, bukan di data? Apa yang rusak bila dibalik?**
Agar layer `domain` (yang berisi logika bisnis utama) tetap independen dan tidak bergantung pada hal teknis eksternal. Jika dibalik, `domain` akan bergantung pada layer `data` (melanggar *Dependency Inversion Principle*). Akibatnya, logika bisnis tidak bisa diuji secara murni (*unit test* tanpa database) dan akan rusak atau perlu dirombak besar-besaran jika teknologi database diganti.

**2. Kapan use case benar-benar dibutuhkan, dan kapan repository langsung ke notifier sudah cukup?**
*Use case* benar-benar dibutuhkan jika ada operasi bisnis yang melibatkan logika tambahan (seperti validasi data, kalkulasi rumit, atau menggabungkan data dari lebih dari satu *repository*). Jika operasinya hanya sekadar CRUD sederhana satu baris (membaca/menyimpan data langsung), memanggil *repository* langsung ke *notifier* sudah cukup.

**3. Apa biaya over-engineering (use case per CRUD satu-baris) bagi tim kecil? Kapan biayanya sepadan?**
Bagi tim kecil, biayanya adalah penumpukan *boilerplate code*, melambatnya kecepatan pengembangan (*development time*), dan aplikasi menjadi sulit dinavigasi karena terlalu banyak *file* yang melakukan hal sepele. Biaya ini baru sepadan pada proyek berskala raksasa, kompleks, dikerjakan oleh tim besar yang terpisah, dan memiliki logika bisnis yang sangat dinamis.

**4. Bagian mana dari usulan AI yang Anda tolak atau sederhanakan, dan mengapa?**
Saya menolak usulan AI yang membuat *Use Case* khusus untuk setiap operasi CRUD tunggal (misalnya *use case* hanya untuk mengambil profil *user* tanpa logika validasi). Saya menyederhanakannya dengan memanggil *repository* langsung dari *Provider/Notifier* karena fitur tersebut terlalu sederhana sehingga penambahan *use case* hanya akan menambah kerumitan (*over-engineering*) tanpa memberikan *value* arsitektural yang berarti.
