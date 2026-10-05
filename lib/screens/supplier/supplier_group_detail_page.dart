import 'package:flutter/material.dart';

import '../../models/supplier_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/supplier_group_service.dart';
import 'supplier_detail_page.dart';

class SupplierGroupDetailPage extends StatefulWidget {
  final SupplierGroupModel group;

  const SupplierGroupDetailPage({super.key, required this.group});

  @override
  State<SupplierGroupDetailPage> createState() =>
      _SupplierGroupDetailPageState();
}

class _SupplierGroupDetailPageState extends State<SupplierGroupDetailPage> {
  static const _ink = Color(0xFF183C32);
  static const _green = Color(0xFF1F7A2E);
  static const _gold = Color(0xFFE0A800);

  final _searchController = TextEditingController();
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _suppliers = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AuthService.getCurrentUser().then((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canViewSupplier =>
      _user?.role == 'superadmin' ||
      (_user?.permissions['supplier.view'] ?? false);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await SupplierGroupService.detail(widget.group.id);
    if (!mounted) return;
    if (result['success'] != true || result['data'] is! Map) {
      setState(() {
        _loading = false;
        _error =
            result['message']?.toString() ??
            'Gagal memuat detail supplier group.';
      });
      return;
    }

    final group = Map<String, dynamic>.from(result['data'] as Map);
    final rawSuppliers = group['suppliers'];
    final suppliers = rawSuppliers is List
        ? rawSuppliers
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    setState(() {
      _group = group;
      _suppliers = suppliers;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredSuppliers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _suppliers;
    return _suppliers.where((supplier) {
      final buyer = supplier['master_buyer'] ?? supplier['masterBuyer'];
      final buyerName = buyer is Map ? buyer['full_name'] : '';
      final text =
          '${supplier['vendor_id'] ?? ''} ${supplier['nama_vendor'] ?? ''} $buyerName'
              .toLowerCase();
      return text.contains(query);
    }).toList();
  }

  String _nestedName(
    Map<String, dynamic> supplier,
    List<String> keys,
    List<String> nameKeys,
  ) {
    for (final key in keys) {
      final nested = supplier[key];
      if (nested is Map) {
        for (final nameKey in nameKeys) {
          final value = nested[nameKey];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
      }
    }
    return '-';
  }

  void _openSupplier(Map<String, dynamic> supplier) {
    if (!_canViewSupplier) return;
    final id = supplier['id']?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierDetailPage(supplierId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_group?['group_name'] ?? widget.group.name).toString();
    final code = (_group?['group_code'] ?? widget.group.code).toString();
    final status =
        (_group?['status'] ?? (widget.group.isActive ? 'active' : 'inactive'))
            .toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Supplier Group',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF173F32), Color(0xFF286246)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.groups_2_rounded,
                                color: Color(0xFFFFD75E),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$code \u2022 ${status == 'active' ? 'Aktif' : 'Nonaktif'}',
                                    style: const TextStyle(
                                      color: Color(0xFFD5E3DC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_suppliers.length} supplier',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari kode, nama supplier, atau buyer...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE1E8DF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_filteredSuppliers.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('Belum ada supplier dalam group ini.'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverList.separated(
                        itemCount: _filteredSuppliers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final supplier = _filteredSuppliers[index];
                          final active =
                              supplier['status_user']?.toString() == '1';
                          final buyerName = _nestedName(
                            supplier,
                            const ['master_buyer', 'masterBuyer'],
                            const ['full_name', 'name'],
                          );
                          final bankName = _nestedName(
                            supplier,
                            const ['master_bank', 'masterBank'],
                            const ['bank_name', 'name'],
                          );
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              onTap: _canViewSupplier
                                  ? () => _openSupplier(supplier)
                                  : null,
                              leading: CircleAvatar(
                                backgroundColor: active
                                    ? const Color(0xFFE5F2E7)
                                    : const Color(0xFFF0F1EF),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: active ? _green : Colors.black45,
                                ),
                              ),
                              title: Text(
                                '${supplier['nama_vendor'] ?? '-'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${supplier['vendor_id'] ?? '-'}\nBuyer: $buyerName \u2022 Bank: $bankName',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              isThreeLine: true,
                              trailing: _canViewSupplier
                                  ? const Icon(Icons.chevron_right_rounded)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
