import 'package:flutter/material.dart';
import '../services/master_data_service.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});
  @override State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { final rows = await MasterDataService.buyers(search: _search.text); if (mounted) setState(() { _rows = rows; _loading = false; }); }
    catch (e) { if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); }); }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final buyerId = TextEditingController(text: row?['buyer_id']?.toString() ?? '');
    final name = TextEditingController(text: row?['full_name']?.toString() ?? '');
    final email = TextEditingController(text: row?['email_buyer']?.toString() ?? '');
    final phone = TextEditingController(text: row?['phone_buyer']?.toString() ?? '');
    String status = row?['status']?.toString() == 'inactive' ? 'inactive' : 'active';
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => AlertDialog(
      title: Text(row == null ? 'Tambah Buyer' : 'Edit Buyer'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: buyerId, decoration: const InputDecoration(labelText: 'Kode Buyer *'), validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null),
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama Buyer *'), validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null),
        TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
        TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Nomor Telepon'), keyboardType: TextInputType.phone),
        DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: 'active', child: Text('Aktif')), DropdownMenuItem(value: 'inactive', child: Text('Nonaktif'))], onChanged: (v) => setModal(() => status = v ?? 'active')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () async { if (!formKey.currentState!.validate()) return; try { await MasterDataService.saveBuyer({'buyer_id': buyerId.text.trim(), 'full_name': name.text.trim(), 'email_buyer': email.text.trim().isEmpty ? null : email.text.trim(), 'phone_buyer': phone.text.trim().isEmpty ? null : phone.text.trim(), 'status': status, 'active_date': row?['active_date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10)}, id: row?['id']?.toString()); if (ctx.mounted) Navigator.pop(ctx, true); } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }, child: const Text('Simpan'))],
    )));
    for (final c in [buyerId, name, email, phone]) c.dispose();
    if (saved == true) _load();
  }

  Future<void> _deactivate(Map<String, dynamic> row) async { try { await MasterDataService.deactivateBuyer(row['id'].toString()); _load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Master Buyer'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Tambah')),
    body: Column(children: [Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _search, onSubmitted: (_) => _load(), decoration: InputDecoration(hintText: 'Cari kode atau nama buyer...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))), Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 90), itemCount: _rows.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) { final row = _rows[i]; return Card(child: ListTile(title: Text('${row['buyer_id'] ?? '-'} • ${row['full_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${row['email_buyer'] ?? '-'} • ${row['status'] ?? '-'}'), onTap: () => _edit(row), trailing: IconButton(icon: const Icon(Icons.person_off_outlined), onPressed: () => _deactivate(row))); })))]),
  );
}
