import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';
import 'supplier_detail_page.dart';
import 'supplier_form_page.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoading = true;
  String? _errorMessage;
  List<SupplierModel> _suppliers = [];
  int _total = 0;
  int _totalActive = 0;
  int _totalInactive = 0;
  int _currentPage = 1;

  int? _statusFilter; // null: all, 1: active, 0: inactive
  String? _groupIdFilter;
  List<SupplierGroupRef> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadReferences();
    _fetchSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    final ref = await SupplierService.getReferences();
    if (mounted && ref != null) {
      setState(() {
        _groups = ref.supplierGroups;
      });
    }
  }

  Future<void> _fetchSuppliers({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await SupplierService.getSuppliers(
      search: _searchController.text.trim(),
      groupId: _groupIdFilter,
      status: _statusFilter,
      page: page,
    );

    if (!mounted) return;

    if (res.success) {
      setState(() {
        _suppliers = res.items;
        _total = res.total;
        _totalActive = res.totalActive;
        _totalInactive = res.totalInactive;
        _currentPage = res.currentPage;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchSuppliers(page: 1);
    });
  }

  void _openAddSupplier() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const SupplierFormPage(),
      ),
    );
    if (created == true) {
      _fetchSuppliers(page: 1);
    }
  }

  void _openDetail(SupplierModel supplier) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailPage(supplierId: supplier.id),
      ),
    );
    if (changed == true) {
      _fetchSuppliers(page: _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    const muted = Color(0xFF7D8983);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Master Data Supplier',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded, color: ink),
            onPressed: () => _fetchSuppliers(page: 1),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSupplier,
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Tambah Supplier',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. STATS BANNER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  _statItem('Total Pemasok', '$_total', const Color(0xFF1E88E5), const Color(0xFFE3F2FD)),
                  const SizedBox(width: 10),
                  _statItem('Aktif', '$_totalActive', green, const Color(0xFFE8F5E9)),
                  const SizedBox(width: 10),
                  _statItem('Non-Aktif', '$_totalInactive', const Color(0xFFD84315), const Color(0xFFFBE9E7)),
                ],
              ),
            ),

            // 2. SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari supplier, kode, KTP, atau telepon...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _fetchSuppliers(page: 1);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: green, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. FILTER CHIPS
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip('Semua Status', _statusFilter == null, () {
                    setState(() => _statusFilter = null);
                    _fetchSuppliers(page: 1);
                  }),
                  _filterChip('Aktif', _statusFilter == 1, () {
                    setState(() => _statusFilter = 1);
                    _fetchSuppliers(page: 1);
                  }),
                  _filterChip('Non-Aktif', _statusFilter == 0, () {
                    setState(() => _statusFilter = 0);
                    _fetchSuppliers(page: 1);
                  }),
                  if (_groups.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String?>(
                      tooltip: 'Filter Grup Supplier',
                      onSelected: (val) {
                        setState(() => _groupIdFilter = val);
                        _fetchSuppliers(page: 1);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('Semua Grup'),
                        ),
                        ..._groups.map(
                          (g) => PopupMenuItem(
                            value: g.id?.toString(),
                            child: Text(g.name),
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _groupIdFilter != null
                              ? green.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _groupIdFilter != null
                                ? green
                                : const Color(0xFFE9EDE5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.group_work_outlined,
                              size: 16,
                              color: _groupIdFilter != null ? green : muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _groupIdFilter != null
                                  ? (_groups.firstWhere((e) => e.id.toString() == _groupIdFilter, orElse: () => SupplierGroupRef(id: '', code: '', name: 'Grup')).name)
                                  : 'Grup Supplier',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _groupIdFilter != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _groupIdFilter != null ? green : ink,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. SUPPLIER LIST
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: green),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_off_rounded,
                                  size: 48,
                                  color: Color(0xFFD14942),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFD14942),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _fetchSuppliers(page: 1),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: green,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _suppliers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Belum ada data supplier',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Gunakan tombol di bawah untuk menambah supplier baru.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _fetchSuppliers(page: 1),
                              color: green,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  90,
                                ),
                                itemCount: _suppliers.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final supplier = _suppliers[index];
                                  return _buildSupplierCard(supplier);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9EDE5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7D8983),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183C32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1F7A2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1F7A2E)
                  : const Color(0xFFE9EDE5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF183C32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(SupplierModel supplier) {
    const green = Color(0xFF1F7A2E);
    const ink = Color(0xFF183C32);
    const muted = Color(0xFF7D8983);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetail(supplier),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9EDE5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE3EBD9),
                    child: Text(
                      supplier.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ink.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                supplier.vendorId,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: (supplier.isActive ? green : const Color(0xFFD84315))
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                supplier.isActive ? 'Aktif' : 'Non-Aktif',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: supplier.isActive
                                      ? green
                                      : const Color(0xFFD84315),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supplier.namaVendor,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F3ED)),
              const SizedBox(height: 10),

              // Info Items
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: muted),
                  const SizedBox(width: 6),
                  Text(
                    supplier.nomorHp ?? '-',
                    style: const TextStyle(fontSize: 12, color: ink),
                  ),
                  const Spacer(),
                  if (supplier.supplierGroupName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        supplier.supplierGroupName!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (supplier.namaBank != null && supplier.nomorRekening != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 14,
                      color: muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${supplier.namaBank} • ${supplier.nomorRekening}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
