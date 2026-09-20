import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/pengaturan_provider.dart';

class QRPembayaranScreen extends StatelessWidget {
  const QRPembayaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pengaturanProvider = context.watch<PengaturanProvider>();
    final toko = pengaturanProvider.pengaturan;
    final rekeningBank = pengaturanProvider.rekeningBank;
    final dataQr = toko.qris;
    final adaGambarQr =
        toko.qrisGambar.isNotEmpty && File(toko.qrisGambar).existsSync();
    final adaQr = dataQr.isNotEmpty || adaGambarQr;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR Pembayaran',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Tampilkan QR untuk pelanggan',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
      body: !adaQr
          ? const Center(child: Text('Data QRIS belum diatur.'))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 42,
                            color: Color(0xFF1E7A4C),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            toko.namaToko,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scan QR untuk melakukan pembayaran',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE3E8E5),
                              ),
                            ),
                            child: adaGambarQr
                                ? Image.file(
                                    File(toko.qrisGambar),
                                    width: 240,
                                    height: 240,
                                    fit: BoxFit.contain,
                                  )
                                : QrImageView(
                                    data: dataQr,
                                    version: QrVersions.auto,
                                    size: 240,
                                    gapless: false,
                                  ),
                          ),
                          const SizedBox(height: 18),
                          if (rekeningBank.isNotEmpty)
                            Text(
                              rekeningBank
                                  .map(
                                    (rekening) =>
                                        '${rekening.namaBank} • ${rekening.nomorRekening}\n${rekening.namaRekening}',
                                  )
                                  .join('\n\n'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
