import 'package:flutter/material.dart';

class TransactionItem {
  final String poNumber;
  final String supplierName;
  final String commodity;
  final String date;
  final double tonnageKg;
  final double? moistureContent; // Kadar Air (KA)
  final double? yieldRate; // Rendemen
  final double totalAmount;
  final String status;
  final Color statusColor;
  final String step;

  const TransactionItem({
    required this.poNumber,
    required this.supplierName,
    required this.commodity,
    required this.date,
    required this.tonnageKg,
    this.moistureContent,
    this.yieldRate,
    required this.totalAmount,
    required this.status,
    required this.statusColor,
    required this.step,
  });
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<TransactionItem> _transactions = const [
    TransactionItem(
      poNumber: 'PO-2026/09/0048',
      supplierName: 'H. Rohmat Jaya (Kediri)',
      commodity: 'Gabah Kering Panen (GKP Super)',
      date: 'Hari ini, 08:30 WIB',
      tonnageKg: 8420,
      moistureContent: 17.8,
      yieldRate: 64.5,
      totalAmount: 58940000,
      status: 'Menunggu Approval Finance',
      statusColor: Color(0xFFF57F17),
      step: 'Step 4/5: Otorisasi Faktur',
    ),
    TransactionItem(
      poNumber: 'PO-2026/09/0047',
      supplierName: 'UD Tani Makmur Mandiri',
      commodity: 'Gabah Kering Panen (GKP Rendeng)',
      date: 'Hari ini, 07:45 WIB',
      tonnageKg: 12150,
      moistureContent: 19.2,
      yieldRate: 62.0,
      totalAmount: 82620000,
      status: 'Proses Timbangan Keluar (Tara)',
      statusColor: Color(0xFFD84315),
      step: 'Step 3/5: Penimbangan Netto',
    ),
    TransactionItem(
      poNumber: 'PO-2026/09/0046',
      supplierName: 'Gapoktan Sri Rejeki Nganjuk',
      commodity: 'Gabah Kering Panen (GKP)',
      date: 'Hari ini, 07:15 WIB',
      tonnageKg: 6800,
      moistureContent: null,
      yieldRate: null,
      totalAmount: 46240000,
      status: 'Sampling QC Lab Incoming',
      statusColor: Color(0xFF8E24AA),
      step: 'Step 2/5: Uji Laboratorium',
    ),
    TransactionItem(
      poNumber: 'PO-2026/09/0045',
      supplierName: 'Mitra Padi Sentosa',
      commodity: 'Gabah Kering Giling (GKG Premium)',
      date: 'Kemarin, 16:20 WIB',
      tonnageKg: 15300,
      moistureContent: 13.5,
      yieldRate: 68.2,
      totalAmount: 119340000,
      status: 'Selesai & Terbayar',
      statusColor: Color(0xFF2E7D32),
      step: 'Step 5/5: Pelunasan Lunas',
    ),
    TransactionItem(
      poNumber: 'PO-2026/09/0044',
      supplierName: 'Kelompok Tani Berkah Tani',
      commodity: 'Gabah Kering Panen (GKP)',
      date: 'Kemarin, 14:10 WIB',
      tonnageKg: 9100,
      moistureContent: 18.0,
      yieldRate: 63.8,
      totalAmount: 62790000,
      status: 'Selesai & Terbayar',
      statusColor: Color(0xFF2E7D32),
      step: 'Step 5/5: Pelunasan Lunas',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TransactionItem> _getFiltered(int tabIndex) {
    if (tabIndex == 0) return _transactions;
    if (tabIndex == 1) {
      return _transactions
          .where((t) =>
              t.status.contains('Timbangan') || t.status.contains('Sampling'))
          .toList();
    }
    if (tabIndex == 2) {
      return _transactions
          .where((t) => t.status.contains('Approval'))
          .toList();
    }
    return _transactions
        .where((t) => t.status.contains('Selesai'))
        .toList();
  }

  void _showDetail(TransactionItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.poNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.supplierName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5D6864),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: item.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _infoRow('Komoditas', item.commodity),
            _infoRow('Waktu Transaksi', item.date),
            _infoRow(
              'Tonase',
              '${item.tonnageKg.toStringAsFixed(0)} Kg (${(item.tonnageKg / 1000).toStringAsFixed(2)} Ton)',
            ),
            _infoRow(
              'Kadar Air (QC Lab)',
              item.moistureContent != null ? '${item.moistureContent}%' : 'Sedang diuji',
            ),
            _infoRow(
              'Rendemen',
              item.yieldRate != null ? '${item.yieldRate}%' : 'Sedang diuji',
            ),
            _infoRow(
              'Estimasi Nilai',
              'Rp ${item.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
              isBold: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Membuka detail transaksi ${item.poNumber}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Buka Lembar Kerja Penuh'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7D8983)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? const Color(0xFF1F7A2E) : const Color(0xFF183C32),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitoring Transaksi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: green,
          unselectedLabelColor: const Color(0xFF7D8983),
          indicatorColor: green,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Semua (5)'),
            Tab(text: 'Timbang & QC (2)'),
            Tab(text: 'Approval (1)'),
            Tab(text: 'Selesai (2)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (tabIndex) {
          final items = _getFiltered(tabIndex);
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada transaksi pada kategori ini.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildCard(item);
            },
          );
        }),
      ),
    );
  }

  Widget _buildCard(TransactionItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetail(item),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9EDE5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF183C32).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.poNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183C32),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.supplierName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183C32),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.commodity,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5D6864),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F3ED)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tonase',
                        style: TextStyle(fontSize: 10, color: Color(0xFF7D8983)),
                      ),
                      Text(
                        '${(item.tonnageKg / 1000).toStringAsFixed(2)} Ton',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF183C32),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kadar Air (KA)',
                        style: TextStyle(fontSize: 10, color: Color(0xFF7D8983)),
                      ),
                      Text(
                        item.moistureContent != null
                            ? '${item.moistureContent}%'
                            : 'Diuji',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: item.moistureContent != null
                              ? const Color(0xFF1E88E5)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Biaya',
                        style: TextStyle(fontSize: 10, color: Color(0xFF7D8983)),
                      ),
                      Text(
                        'Rp ${(item.totalAmount / 1000000).toStringAsFixed(1)} Jt',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F7A2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
