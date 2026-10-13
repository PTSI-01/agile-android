import 'package:flutter/material.dart';

import '../services/dashboard_analytics_service.dart';

class DashboardAnalyticsPage extends StatefulWidget {
  final String kind;
  final String title;

  const DashboardAnalyticsPage({
    super.key,
    required this.kind,
    required this.title,
  });

  @override
  State<DashboardAnalyticsPage> createState() => _DashboardAnalyticsPageState();
}

class _DashboardAnalyticsPageState extends State<DashboardAnalyticsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardAnalyticsService.fetch(widget.kind);
  }

  void _reload() => setState(() {
    _future = DashboardAnalyticsService.fetch(widget.kind);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  data['period_label']?.toString() ??
                      data['periode_label']?.toString() ??
                      'Periode berjalan',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (widget.kind == 'pembelian') _purchaseSummary(data),
                if (widget.kind == 'laba-rugi') _profitSummary(data),
                if (widget.kind == 'hasil-lab') _labSummary(data),
                const SizedBox(height: 20),
                _dataRows(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _purchaseSummary(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    return _summaryGrid([
      _summary(
        'Transaksi',
        summary['total_transactions'] ?? 0,
        Icons.receipt_long_rounded,
      ),
      _summary('Qty Final', summary['total_qty'] ?? 0, Icons.scale_rounded),
      _summary('Buyer', summary['buyer_count'] ?? 0, Icons.person_rounded),
      _summary(
        'Supplier',
        summary['supplier_count'] ?? 0,
        Icons.local_shipping_rounded,
      ),
    ]);
  }

  Widget _profitSummary(Map<String, dynamic> data) {
    final rows = _list(_map(data['laba_rugi'])['rows']);
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + _number(row['laba_rugi']),
    );
    return _summaryGrid([
      _summary('Total Laba Rugi', _money(total), Icons.payments_rounded),
    ]);
  }

  Widget _labSummary(Map<String, dynamic> data) {
    final rows = _list(data['hargaLabPerSupplier']);
    final double avg = rows.isEmpty
        ? 0.0
        : rows
                  .map((r) => _number(r['avg_aktual'] ?? r['avg_lab']))
                  .reduce((a, b) => a + b) /
              rows.length;
    return _summaryGrid([
      _summary('Rata-rata Harga Aktual', _money(avg), Icons.science_rounded),
    ]);
  }

  Widget _dataRows(Map<String, dynamic> data) {
    final source = widget.kind == 'pembelian'
        ? _map(data['buyer'])['rows']
        : widget.kind == 'laba-rugi'
        ? _map(data['laba_rugi'])['rows']
        : data['hargaLabPerSupplier'];
    final rows = _list(source);
    if (rows.isEmpty) return const _EmptyState();
    return Column(
      children: rows.take(30).map((row) {
        final title =
            row['buyer_name'] ?? row['buyer'] ?? row['nama_supplier'] ?? 'Data';
        final value =
            row['total_qty'] ??
            row['laba_rugi'] ??
            row['avg_aktual'] ??
            row['avg_lab'] ??
            0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE4F0E5),
              child: Icon(
                widget.kind == 'hasil-lab'
                    ? Icons.science_rounded
                    : Icons.analytics_rounded,
                color: const Color(0xFF1F5B42),
              ),
            ),
            title: Text(
              title.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              row['supplier_name']?.toString() ??
                  row['buyer_code']?.toString() ??
                  '',
            ),
            trailing: Text(
              _display(value),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryGrid(List<Widget> items) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 2.5,
    children: items,
  );

  Widget _summary(String label, dynamic value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1F5B42), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  _display(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
  double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  String _money(double value) => 'Rp ${value.toStringAsFixed(0)}';
  String _display(dynamic value) => value is num
      ? (value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2))
      : value.toString();
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Center(child: Text('Belum ada data dashboard pada periode ini.')),
  );
}
