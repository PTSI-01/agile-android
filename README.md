# Agile Mobile

Aplikasi Flutter untuk Android milik Agile Jaya Abadi (E-Procurement).
Backend yang direncanakan adalah proyek Laravel Agile yang sudah ada.

## Status

- Halaman login mengikuti desain mobile Laravel, menggunakan logo asli.
- Validasi email/password, tampilkan password, dan mode gelap tersedia.
- Checkbox Ingat saya belum menyimpan sesi.
- Autentikasi dan API Laravel belum terhubung; tombol Masuk belum melakukan login.
- Prototype dashboard proyek/sprint masih ada di source untuk referensi, bukan dashboard operasional final.

## Menjalankan

Siapkan Flutter stable yang memenuhi versi Dart pada pubspec.yaml, Android SDK,
dan HP Android dengan USB debugging aktif.

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

## Pemeriksaan

```sh
flutter analyze
flutter test
```

## Struktur utama

- `lib/main.dart`: entry point dan prototype homepage.
- `lib/screens/login_page.dart`: halaman login Android.
- `assets/images/logo_agile.jpg`: logo perusahaan.
- `test/widget_test.dart`: pengujian form dan layout login.

Konfigurasi SDK lokal, file build, kredensial, dan keystore tidak disertakan.
