import 'package:flutter/material.dart';
import '../services/master_data_service.dart';

class BuyerDetailPage extends StatefulWidget {
  final String id;
  const BuyerDetailPage({super.key, required this.id});
  @override State<BuyerDetailPage> createState() => _BuyerDetailPageState();
}

class _BuyerDetailPageState extends State<BuyerDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _buyer;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { final data = await MasterDataService.buyerDetail(widget.id); if (mounted) setState(() { _buyer = data; _loading = false; }); }
    catch (e) { if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); }); }
  }
  @override Widget build(BuildContext context) {
    final suppliers = (_buyer?['suppliers'] as List? ?? []).cast<Map<String, dynamic>>();
    final group = _buyer?['purchasing_group'];
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Buyer', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
          _header(), const SizedBox(height: 10),
          _info('Email', _buyer?['email_buyer']), _info('Telepon', _buyer?['phone_buyer']),
          _info('Buyer Group', group is Map ? '${group['group_code'] ?? '-'} • ${group['group_name'] ?? '-'}' : '-'),
          _info('Jumlah Supplier', '${_buyer?['suppliers_count'] ?? suppliers.length}'), const SizedBox(height: 14),
          Text('Supplier terkait', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
          if (suppliers.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada supplier terkait.')))),
          ...suppliers.map((supplier) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE5F2E4), child: Icon(Icons.storefront_rounded, color: Color(0xFF1B5E20))),
            title: Text('${supplier['vendor_id'] ?? '-'} • ${supplier['nama_vendor'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(supplier['status_user']?.toString() == '1' ? 'Aktif' : 'Nonaktif'),
          )))
        ]),
      ),
    );
  }
  Widget _header() => Card(color: const Color(0xFFE8F3E5), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    const CircleAvatar(radius: 28, backgroundColor: Color(0xFF1B5E20), child: Icon(Icons.person_rounded, color: Colors.white, size: 28)), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_buyer?['buyer_id'] ?? '-'} • ${_buyer?['full_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 4), Text(_buyer?['status'] == 'active' ? 'Aktif' : 'Nonaktif', style: const TextStyle(color: Colors.black54))])),
  ])));
  Widget _info(String label, dynamic value) => Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(title: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)), subtitle: Text(value?.toString().isNotEmpty == true ? value.toString() : '-', style: const TextStyle(fontWeight: FontWeight.w600))));
}
