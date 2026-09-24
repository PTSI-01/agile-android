import 'package:flutter/material.dart';
import '../services/master_data_service.dart';

class MasterBankDetailPage extends StatefulWidget {
  final String bankId;
  const MasterBankDetailPage({super.key, required this.bankId});
  @override State<MasterBankDetailPage> createState() => _MasterBankDetailPageState();
}

class _MasterBankDetailPageState extends State<MasterBankDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _bank;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await MasterDataService.bankDetail(widget.bankId);
      if (mounted) setState(() { _bank = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = _bank;
    final accounts = (bank?['accounts'] as List? ?? []).cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Master Bank', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        Card(color: const Color(0xFFE8F3E5), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const CircleAvatar(radius: 28, backgroundColor: Color(0xFF1B5E20), child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${bank?['bank_code'] ?? '-'} • ${bank?['bank_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 4), Text('${bank?['bank_accounts_count'] ?? accounts.length} rekening terdaftar', style: const TextStyle(color: Colors.black54))])),
        ]))),
        const SizedBox(height: 14),
        Text('Daftar Rekening Supplier', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (accounts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada rekening supplier pada bank ini.')))),
        ...accounts.map((account) {
          final vendor = account['supplier_name']?.toString();
          final buyer = account['buyer_name']?.toString() ?? account['buyer_id']?.toString();
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(isThreeLine: true, leading: CircleAvatar(backgroundColor: const Color(0xFFE5F2E4), child: const Icon(Icons.credit_card_rounded, color: Color(0xFF1B5E20))), title: Text(vendor?.isNotEmpty == true ? vendor! : 'Supplier ID: ${account['supplier_id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Rekening: ${account['account_number'] ?? '-'}\nPemilik: ${account['account_holder_name'] ?? '-'}\nBuyer: ${buyer?.isNotEmpty == true ? buyer : '-'}'), trailing: account['is_primary'] == true ? const Tooltip(message: 'Rekening utama', child: Icon(Icons.star_rounded, color: Color(0xFFB58412))) : null));
        }),
      ])),
    );
  }
}
