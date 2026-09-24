import 'package:flutter/material.dart';
import '../services/buyer_group_service.dart';

class BuyerGroupDetailPage extends StatefulWidget {
  final String id;
  const BuyerGroupDetailPage({super.key, required this.id});
  @override State<BuyerGroupDetailPage> createState() => _BuyerGroupDetailPageState();
}

class _BuyerGroupDetailPageState extends State<BuyerGroupDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _group;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { final data = await BuyerGroupService.detail(widget.id); if (mounted) setState(() { _group = data; _loading = false; }); }
    catch (e) { if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); }); }
  }
  @override Widget build(BuildContext context) {
    final buyers = (_group?['buyers'] as List? ?? []).cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Buyer Group', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!, textAlign: TextAlign.center)) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
          _header(), const SizedBox(height: 14),
          Text('Buyer di dalam group', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
          if (buyers.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada buyer pada group ini.')))),
          ...buyers.map((buyer) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE5F2E4), child: Icon(Icons.person_rounded, color: Color(0xFF1B5E20))),
            title: Text('${buyer['buyer_id'] ?? '-'} • ${buyer['full_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${buyer['email_buyer'] ?? '-'}\n${buyer['suppliers_count'] ?? 0} supplier'),
          )))
        ]),
      ),
    );
  }
  Widget _header() => Card(color: const Color(0xFFE8F3E5), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    const CircleAvatar(radius: 28, backgroundColor: Color(0xFF1B5E20), child: Icon(Icons.groups_rounded, color: Colors.white, size: 28)), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_group?['group_code'] ?? '-'} • ${_group?['group_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 4), Text('${_group?['buyers_count'] ?? 0} buyer terdaftar', style: const TextStyle(color: Colors.black54))])),
  ])));
}
