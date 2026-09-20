import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'providers/aplikasi_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/kasir_provider.dart';
import 'providers/pengaturan_provider.dart';
import 'providers/produk_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk DateFormat.
  await initializeDateFormatting('id_ID');

  // Inisialisasi SQLite FFI untuk Windows/Linux/macOS.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await DatabaseLokal.instance.inisialisasi();
  }

  runApp(const AplikasiPos());
}

class AplikasiPos extends StatelessWidget {
  const AplikasiPos({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AplikasiProvider()),
        ChangeNotifierProvider(create: (_) => KasirProvider()),
        ChangeNotifierProvider(create: (_) => ProdukProvider()),
        ChangeNotifierProvider(create: (_) => PengaturanProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'POS UMKM',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0F9D58),
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
