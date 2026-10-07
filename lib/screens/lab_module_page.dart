import 'package:flutter/material.dart';
import '../services/lab_module_service.dart';

class LabModulePage extends StatefulWidget {
  final String title;
  final String? resource;
  final bool parameters;
  const LabModulePage({super.key, required this.title, this.resource, this.parameters = false});

  @override
  State<LabModulePage> createState() => _LabModulePageState();
}

class _LabModulePageState extends State<LabModulePage> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = widget.parameters
          ? await LabModuleService.parameters(search: _search.text)
          : await LabModuleService.list(widget.resource!, search: _search.text);
      if (mounted) setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(controller: _search, onSubmitted: (_) => _load(), decoration: InputDecoration(hintText: 'Cari data...', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : _rows.isEmpty ? const Center(child: Text('Belum ada data.')) : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _rows.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) => _card(_rows[i])))),
    ]),
  );

  Widget _card(Map<String, dynamic> row) {
    final primary = widget.parameters ? row['legal_number'] : row['legal_number'];
    final secondary = widget.parameters
        ? 'Tanggal PO: ${row['tanggal_po'] ?? '-'}'
        : 'Buyer: ${row['buyer'] is Map ? row['buyer']['kode_transaksi'] ?? row['buyer_code'] : row['buyer_code'] ?? '-'}';
    return Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE3EBD9), child: Icon(widget.parameters ? Icons.tune : Icons.science, color: const Color(0xFF1F5B42))), title: Text(primary?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(secondary), trailing: widget.parameters ? Text('Atas ${row['harga_atas'] ?? '-'}\nBawah ${row['harga_bawah'] ?? '-'}', textAlign: TextAlign.end) : Text(row['status_lab']?.toString() ?? 'Proses')));
  }
}
