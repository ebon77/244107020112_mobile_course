# responsive_dashboard

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AI Design Exploration & Prompt Challenge

**1. Prompt desain: Bandingkan GridView vs LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya.**
*   **GridView:** Sangat mudah untuk membuat elemen berukuran seragam yang otomatis berpindah baris (wrap) berdasarkan `crossAxisCount`. Aksesibilitasnya baik karena urutan baca layar (*screen reader*) mengalir secara natural dari kiri-kanan, atas-bawah. Kelemahannya, GridView memaksakan rasio aspek (`childAspectRatio`), sehingga sulit menangani kartu dengan tinggi konten yang dinamis/berbeda-beda.
*   **LayoutBuilder + Column/Row:** Memberikan kontrol tingkat tinggi untuk elemen dengan tinggi tidak beraturan. Kelemahannya, kode menjadi jauh lebih panjang dan rumit karena harus membuat logika "membungkus" (wrap) secara manual. Jika urutan kodenya tidak terstruktur dengan baik, aksesibilitas bisa terganggu karena *screen reader* mungkin melompat secara tidak logis.

**2. Prompt penguatan konsep: Kapan penggunaan `Expanded` menyebabkan overflow di dalam Row?**
`Expanded` dirancang untuk mencegah overflow karena ia akan membatasi widget agar hanya menggunakan "sisa ruang" yang ada. Namun, **overflow atau error render** sering terjadi jika `Expanded` diletakkan di dalam parent yang panjangnya tidak terbatas (unbounded), seperti `SingleChildScrollView` atau `Row` yang di-scroll. 
*Contoh Error:* Meletakkan `Expanded` langsung di dalam `ListView` atau `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [Expanded(...)])).`
*Perbaikan:* Hapus `Expanded` jika parent-nya bisa di-scroll, atau batasi ukuran parent-nya menggunakan `SizedBox` atau `Container` dengan lebar absolut.

**3. Verification Prompt: Audit Hasil Kode.**
Setelah mengaudit kode `main.dart`, struktur kode ini valid dan direkomendasikan. Aplikasi sepenuhnya responsif (beralih dari 1 ke 2 kolom di batas 700px), menggunakan Semantic Web Label (`Semantics`, `MergeSemantics`) yang memastikan tidak ada pengurangan aksesibilitas, dan hanya menggunakan widget bawaan (stable) Flutter murni tanpa *package* eksternal.