import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';
import 'master_bank_detail_page.dart';

class MasterBankPage extends StatefulWidget {
  const MasterBankPage({super.key});
  @override State<MasterBankPage> createState() => _MasterBankPageState();
}

class _MasterBankPageState extends State<MasterBankPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;

  bool _can(String action) => _user?.role?.toLowerCase() == 'superadmin' || _user?.permissions['master_bank.$action'] == true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _user = await AuthService.refreshCurrentUser();
      final rows = await MasterDataService.banks(search: _search.text);
      if (mounted) setState(() { _items = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _edit([Map<String, dynamic>? bank]) async {
    final code = TextEditingController(text: bank?['bank_code']?.toString() ?? '');
    final name = TextEditingController(text: bank?['bank_name']?.toString() ?? '');
    String status = bank?['status']?.toString() == 'inactive' ? 'inactive' : 'active';
    final result = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(bank == null ? 'Tambah Master Bank' : 'Edit Master Bank'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Kode Bank', hintText: 'BBRI')),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama Bank', hintText: 'Bank BRI')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: 'active', child: Text('Aktif')), DropdownMenuItem(value: 'inactive', child: Text('Nonaktif'))], onChanged: (v) => setDialogState(() => status = v ?? 'active')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () async {
        if (code.text.trim().isEmpty || name.text.trim().isEmpty) return;
        try {
          await MasterDataService.saveBank({'bank_code': code.text.trim().toUpperCase(), 'bank_name': name.text.trim(), 'status': status}, id: bank?['id']?.toString());
          if (context.mounted) Navigator.pop(context, true);
        } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
      }, child: const Text('Simpan'))],
    )));
    code.dispose(); name.dispose();
    if (result == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> bank) async {
    try { await MasterDataService.deleteBank(bank['id'].toString()); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Master Bank', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: _can('create') ? FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Tambah Bank')) : null,
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: TextField(controller: _search, onSubmitted: (_) => _load(), decoration: InputDecoration(hintText: 'Cari kode atau nama bank...', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () { _search.clear(); _load(); }, icon: const Icon(Icons.clear)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 90), itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) { final bank = _items[i]; final active = bank['status'] == 'active'; return Card(child: ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MasterBankDetailPage(bankId: bank['id'].toString()))), leading: CircleAvatar(backgroundColor: active ? const Color(0xFFE5F2E4) : const Color(0xFFE8E8E8), child: Icon(Icons.account_balance_rounded, color: active ? const Color(0xFF1B5E20) : Colors.black54)), title: Text('${bank['bank_code'] ?? '-'} • ${bank['bank_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${active ? 'Aktif' : 'Nonaktif'} • ${bank['bank_accounts_count'] ?? 0} rekening'), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _edit(bank); if (v == 'delete') _delete(bank); }, itemBuilder: (_) => [if (_can('update')) const PopupMenuItem(value: 'edit', child: Text('Edit')), if (_can('delete')) const PopupMenuItem(value: 'delete', child: Text('Hapus'))]))); }))),
    ]),
  );
}
