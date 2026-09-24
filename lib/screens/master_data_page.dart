import 'package:flutter/material.dart';
import '../services/master_data_service.dart';

class MasterDataPage extends StatefulWidget {
  final String type;
  final String title;
  const MasterDataPage({super.key, required this.type, required this.title});

  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await MasterDataService.list(widget.type, search: _search.text);
      if (mounted) setState(() { _items = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  String _primary(Map<String, dynamic> row) => switch (widget.type) {
    'buyer' => '${row['buyer_id'] ?? '-'} • ${row['full_name'] ?? '-'}',
    'item' => '${row['kode_item'] ?? '-'} • ${row['nama_item'] ?? '-'}',
    'warehouse' => '${row['warehouse_code'] ?? '-'} • ${row['warehouse_name'] ?? '-'}',
    'surveyor' => '${row['legal_number'] ?? '-'} • ${row['nama_surveyor'] ?? '-'}',
    _ => '${row['code'] ?? '-'} • ${row['name'] ?? '-'}',
  };

  String _secondary(Map<String, dynamic> row) => switch (widget.type) {
    'buyer' => row['status']?.toString() ?? '-',
    'item' => '${row['kategori_item'] ?? row['jenis_item'] ?? '-'} • ${row['status'] ?? '-'}',
    'warehouse' => row['status']?.toString() ?? '-',
    'surveyor' => '${row['phone_surveyor'] ?? '-'} • ${row['status'] ?? '-'}',
    _ => 'Data wilayah referensi',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        controller: _search, onSubmitted: (_) => _load(),
        decoration: InputDecoration(hintText: 'Cari ${widget.title.toLowerCase()}...', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () { _search.clear(); _load(); }, icon: const Icon(Icons.clear)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
      )),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : RefreshIndicator(onRefresh: _load, child: _items.isEmpty ? ListView(children: const [SizedBox(height: 180), Center(child: Text('Belum ada data'))]) : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) => Card(child: ListTile(leading: CircleAvatar(child: Text('${i + 1}')), title: Text(_primary(_items[i]), style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(_secondary(_items[i]))))))),
    ]),
  );
}
