import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Laporan & Analisis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Export Laporan',
            icon: Icon(Icons.download_rounded, color: ink),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menyiapkan file export Excel & PDF...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 90),
          children: [
            // 1. STATS BANNER
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PENGADAAN BULAN INI',
                    style: TextStyle(
                      color: Color(0xFFD8EFAC),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3.420,5 Ton',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nilai Pengadaan: Rp 23,8 Miliar (412 Transaksi)',
                    style: TextStyle(color: Color(0xFFB5CBC0), fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // 2. DISTRIBUSI KUALITAS / MUTU QC
            Text(
              'Distribusi Kualitas QC (Bulan Ini)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Color(0xFFE9EDE5)),
              ),
              child: Column(
                children: [
                  _gradeBar(
                    label: 'Grade A (KA < 17%, Rendemen > 65%)',
                    percentage: 0.58,
                    color: green,
                    tonnage: '1.984 Ton (58%)',
                  ),
                  SizedBox(height: 14),
                  _gradeBar(
                    label: 'Grade B (KA 17 - 20%, Rendemen 60-64%)',
                    percentage: 0.32,
                    color: Color(0xFFF57F17),
                    tonnage: '1.094 Ton (32%)',
                  ),
                  SizedBox(height: 14),
                  _gradeBar(
                    label: 'Grade C / Rafaksi (KA > 20%)',
                    percentage: 0.10,
                    color: Color(0xFFD84315),
                    tonnage: '342 Ton (10%)',
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // 3. TOP SUPPLIER
            Text(
              'Top 5 Pemasok Terbesar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Color(0xFFE9EDE5)),
              ),
              child: Column(
                children: [
                  _supplierRank(
                    rank: 1,
                    name: 'UD Tani Makmur Mandiri',
                    tonnage: '428 Ton',
                    amount: 'Rp 2,98 M',
                  ),
                  Divider(height: 1, color: Color(0xFFF0F3ED)),
                  _supplierRank(
                    rank: 2,
                    name: 'H. Rohmat Jaya',
                    tonnage: '385 Ton',
                    amount: 'Rp 2,69 M',
                  ),
                  Divider(height: 1, color: Color(0xFFF0F3ED)),
                  _supplierRank(
                    rank: 3,
                    name: 'Mitra Padi Sentosa',
                    tonnage: '312 Ton',
                    amount: 'Rp 2,43 M',
                  ),
                  Divider(height: 1, color: Color(0xFFF0F3ED)),
                  _supplierRank(
                    rank: 4,
                    name: 'Gapoktan Sri Rejeki',
                    tonnage: '276 Ton',
                    amount: 'Rp 1,91 M',
                  ),
                  Divider(height: 1, color: Color(0xFFF0F3ED)),
                  _supplierRank(
                    rank: 5,
                    name: 'CV Berkah Tani Bersama',
                    tonnage: '210 Ton',
                    amount: 'Rp 1,46 M',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeBar({
    required String label,
    required double percentage,
    required Color color,
    required String tonnage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeService.isDark
                      ? Color(0xFFEAF3EE)
                      : Color(0xFF183C32),
                ),
              ),
            ),
            Text(
              tonnage,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            color: color,
            backgroundColor: Color(0xFFEEF2EC),
          ),
        ),
      ],
    );
  }

  Widget _supplierRank({
    required int rank,
    required String name,
    required String tonnage,
    required String amount,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: rank == 1 ? Color(0xFFD8EFAC) : Color(0xFFF0F4EC),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: ThemeService.isDark
                    ? Color(0xFFEAF3EE)
                    : Color(0xFF183C32),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark
                    ? Color(0xFFEAF3EE)
                    : Color(0xFF183C32),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tonnage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ThemeService.isDark
                      ? Color(0xFFEAF3EE)
                      : Color(0xFF183C32),
                ),
              ),
              Text(
                amount,
                style: TextStyle(fontSize: 10, color: Color(0xFF7D8983)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
