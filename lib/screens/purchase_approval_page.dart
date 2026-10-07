import 'package:flutter/material.dart';
import '../services/purchase_approval_service.dart';

class PurchaseApprovalPage extends StatefulWidget {
  const PurchaseApprovalPage({super.key});

  @override
  State<PurchaseApprovalPage> createState() => _PurchaseApprovalPageState();
}

class _PurchaseApprovalPageState extends State<PurchaseApprovalPage> {
  bool _history = false;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await PurchaseApprovalService.list(history: _history);
      if (mounted) setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Approval Pembelian'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'DEAL'), child: const Text('DEAL')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'NEGO'), child: const Text('NEGO')),
        ],
      ),
    );
    if (action == null || !mounted) return;
    final reaction = action == 'NEGO' ? await _negoValue() : null;
    if (action == 'NEGO' && reaction == null) return;
    try {
      await PurchaseApprovalService.approve(row['id'].toString(), aksiHarga: action, reaksiHarga: reaction, kualitasGabah: 'OK');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approval pembelian berhasil disimpan')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<num?> _negoValue() async {
    final controller = TextEditingController();
    return showDialog<num>(context: context, builder: (context) => AlertDialog(
      title: const Text('Nilai Nego'),
      content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Tambahan harga / Kg')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(context, num.tryParse(controller.text.replaceAll(',', '.'))), child: const Text('Lanjut'))],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Approval Pembelian'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Menunggu')), ButtonSegment(value: true, label: Text('Riwayat'))], selected: {_history}, onSelectionChanged: (v) { setState(() => _history = v.first); _load(); })),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : _rows.isEmpty ? Center(child: Text(_history ? 'Belum ada riwayat approval.' : 'Tidak ada PO yang menunggu approval.')) : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _rows.length, itemBuilder: (_, i) => _card(_rows[i])))),
    ]),
  );

  Widget _card(Map<String, dynamic> row) {
    final lab = row['lab_aktual'] is Map ? Map<String, dynamic>.from(row['lab_aktual']) : <String, dynamic>{};
    final pending = !_history;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.receipt_long, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(row['kode_transaksi']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))), Chip(label: Text(pending ? 'Menunggu' : 'Selesai'))]),
      const SizedBox(height: 8),
      Text('Supplier: ${row['nama_supplier'] ?? row['supplier']?['nama_vendor'] ?? '-'}'),
      Text('Tonase: ${row['tonase_supplier'] ?? '-'} Kg'),
      Text('Harga lab: ${lab['plan_harga_beli_gabah'] ?? '-'}'),
      if (pending) Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => _approve(row), icon: const Icon(Icons.check), label: const Text('Proses Approval'))),
    ])));
  }
}
