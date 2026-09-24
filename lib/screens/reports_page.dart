import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan & Analisis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Export Laporan',
            icon: const Icon(Icons.download_rounded, color: ink),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
          children: [
            // 1. STATS BANNER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL PENGADAAN BULAN INI',
                    style: TextStyle(
                      color: Color(0xFFD8EFAC),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '3.420,5 Ton',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nilai Pengadaan: Rp 23,8 Miliar (412 Transaksi)',
                    style: TextStyle(color: Color(0xFFB5CBC0), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. DISTRIBUSI KUALITAS / MUTU QC
            const Text(
              'Distribusi Kualitas QC (Bulan Ini)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9EDE5)),
              ),
              child: Column(
                children: [
                  _gradeBar(
                    label: 'Grade A (KA < 17%, Rendemen > 65%)',
                    percentage: 0.58,
                    color: green,
                    tonnage: '1.984 Ton (58%)',
                  ),
                  const SizedBox(height: 14),
                  _gradeBar(
                    label: 'Grade B (KA 17 - 20%, Rendemen 60-64%)',
                    percentage: 0.32,
                    color: const Color(0xFFF57F17),
                    tonnage: '1.094 Ton (32%)',
                  ),
                  const SizedBox(height: 14),
                  _gradeBar(
                    label: 'Grade C / Rafaksi (KA > 20%)',
                    percentage: 0.10,
                    color: const Color(0xFFD84315),
                    tonnage: '342 Ton (10%)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. TOP SUPPLIER
            const Text(
              'Top 5 Pemasok Terbesar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9EDE5)),
              ),
              child: Column(
                children: [
                  _supplierRank(
                    rank: 1,
                    name: 'UD Tani Makmur Mandiri',
                    tonnage: '428 Ton',
                    amount: 'Rp 2,98 M',
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F3ED)),
                  _supplierRank(
                    rank: 2,
                    name: 'H. Rohmat Jaya',
                    tonnage: '385 Ton',
                    amount: 'Rp 2,69 M',
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F3ED)),
                  _supplierRank(
                    rank: 3,
                    name: 'Mitra Padi Sentosa',
                    tonnage: '312 Ton',
                    amount: 'Rp 2,43 M',
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F3ED)),
                  _supplierRank(
                    rank: 4,
                    name: 'Gapoktan Sri Rejeki',
                    tonnage: '276 Ton',
                    amount: 'Rp 1,91 M',
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F3ED)),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF183C32),
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
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            color: color,
            backgroundColor: const Color(0xFFEEF2EC),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: rank == 1
                ? const Color(0xFFD8EFAC)
                : const Color(0xFFF0F4EC),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183C32),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF183C32),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tonnage,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF183C32),
                ),
              ),
              Text(
                amount,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7D8983)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

