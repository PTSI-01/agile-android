import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import 'supplier/supplier_list_page.dart';
import 'supplier/supplier_group_page.dart';
import 'buyer_page.dart';
import 'buyer_group_page.dart';
import 'master_bank_page.dart';
import 'master_data_page.dart';
import 'purchase_page.dart';

class ModulesPage extends StatefulWidget { final DashboardData? dashboard; const ModulesPage({super.key,this.dashboard}); @override State<ModulesPage> createState()=>ModulesPageState(); }
class ModulesPageState extends State<ModulesPage>{
  final search=TextEditingController();
  final parents=<DashboardMenuModel>[];
  String query='';

  bool handleBack() {
    if (parents.isNotEmpty) {
      setState(() => parents.removeLast());
      return true;
    }
    return false;
  }

  List<DashboardMenuModel> get items{final s=parents.isEmpty?(widget.dashboard?.menus??const <DashboardMenuModel>[]):parents.last.children;if(query.isEmpty)return s;final q=query.toLowerCase();return s.where((x)=>x.title.toLowerCase().contains(q)||x.code.toLowerCase().contains(q)).toList();} @override void dispose(){search.dispose();super.dispose();}
IconData _icon(DashboardMenuModel x){final v='${x.icon} ${x.title}'.toLowerCase();if(v.contains('supplier'))return Icons.people_alt_rounded;if(v.contains('buyer'))return Icons.badge_rounded;if(v.contains('pembelian'))return Icons.shopping_bag_rounded;if(v.contains('penerimaan'))return Icons.scale_rounded;if(v.contains('qc')||v.contains('lab'))return Icons.science_rounded;if(v.contains('finance'))return Icons.payments_rounded;if(v.contains('laporan'))return Icons.analytics_rounded;if(v.contains('user'))return Icons.manage_accounts_rounded;return Icons.dashboard_customize_rounded;}
Color _color(DashboardMenuModel x){final v=x.title.toLowerCase();if(v.contains('pembelian')||v.contains('penerimaan'))return const Color(0xff1f7a2e);if(v.contains('master')||v.contains('target'))return const Color(0xffa66f00);if(v.contains('finance')||v.contains('user'))return const Color(0xff183c32);return const Color(0xff2e7d32);}
void _open(DashboardMenuModel x) {
  if (x.children.isNotEmpty) {
    setState(() => parents.add(x));
    return;
  }
  final u = x.url ?? '';
  Widget? p;
  if (u.contains('supplier-group')) {
    p = const SupplierGroupPage();
  } else if (u.contains('supplier')) {
    p = const SupplierListPage();
  } else if (u.contains('master-buyer')) {
    p = const BuyerPage();
  } else if (u.contains('buyer-group') || u.contains('purchasing-group')) {
    p = const BuyerGroupPage();
  } else if (u.contains('master-bank')) {
    p = const MasterBankPage();
  } else if (u == '/pembelian/transaksi' || u == '/buyer') {
    p = const PurchasePage();
  } else if (u.contains('/master-data/item')) {
    p = const MasterDataPage(type: 'item', title: 'Master Item');
  } else if (u.contains('warehouse')) {
    p = const MasterDataPage(type: 'warehouse', title: 'Master Gudang');
  } else if (u.contains('surveyor')) {
    p = const MasterDataPage(type: 'surveyor', title: 'Master Surveyor');
  } else if (u.contains('wilayah')) {
    p = const MasterDataPage(type: 'wilayah', title: 'Master Wilayah');
  }

  if (p != null) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => p!));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${x.title} belum tersedia di Android')));
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(parents.isEmpty ? 'Modul' : parents.last.title, style: const TextStyle(fontWeight: FontWeight.w800)), leading: parents.isEmpty ? null : IconButton(onPressed: () => setState(() => parents.removeLast()), icon: const Icon(Icons.arrow_back))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 10), child: TextField(controller: search, onChanged: (v) => setState(() => query = v.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari menu...', border: OutlineInputBorder()))),
        Expanded(child: items.isEmpty ? const Center(child: Text('Menu belum tersedia atau belum memiliki hak akses.')) : GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 28), itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .9),
          itemBuilder: (_, i) => _moduleCard(items[i]),
        )),
      ]),
    );
  }
  Widget _moduleCard(DashboardMenuModel x) {
    final c = _color(x);
    final bg = c.toARGB32() == 0xffa66f00 ? const Color(0xfffff3c4) : c.toARGB32() == 0xff183c32 ? const Color(0xffe2e9e3) : const Color(0xffe5f2e7);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: c.withValues(alpha: .18),
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: c.withValues(alpha: .18))),
      child: InkWell(
        onTap: () => _open(x),
        borderRadius: BorderRadius.circular(15),
        child: Padding(padding: const EdgeInsets.all(11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .62), borderRadius: BorderRadius.circular(10)), child: Icon(_icon(x), color: c, size: 19)),
          const Spacer(),
          Text(x.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.15, fontWeight: FontWeight.w800, color: Color(0xff183c32))),
          const SizedBox(height: 5),
          Align(alignment: Alignment.bottomRight, child: Icon(Icons.arrow_forward_rounded, size: 15, color: c)),
        ])),
      ),
    );
  }
}
