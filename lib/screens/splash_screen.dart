import 'dart:async';

import 'package:flutter/material.dart';

import 'beranda_screen.dart';

/// Halaman pembuka aplikasi.
///
/// Logo yang digunakan di sini adalah LOGO APLIKASI,
/// bukan logo toko milik pengguna.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Menjalankan proses perpindahan halaman
    // setelah Splash tampil selama beberapa detik.
    _mulaiAplikasi();
  }

  Future<void> _mulaiAplikasi() async {
    // Memberikan waktu kepada pengguna untuk melihat Splash.
    await Future.delayed(const Duration(seconds: 10));

    // Memastikan widget masih ada sebelum menggunakan context.
    if (!mounted) {
      return;
    }

    // Setelah Splash selesai, masuk ke halaman utama.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BerandaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F9D58), Color(0xFF087F46)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ==============================
              // LOGO APLIKASI
              // ==============================
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo_aplikasi.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 28),

              // ==============================
              // NAMA APLIKASI
              // ==============================
              const Text(
                'POS UMKM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Point of Sales Offline',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // ==============================
              // LOADING INDICATOR
              // ==============================
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

              const Spacer(),

              // ==============================
              // INFORMASI VERSI
              // ==============================
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  'Versi 1.0.0',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
