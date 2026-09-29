import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'supplier_detail_page.dart';
import 'supplier_form_page.dart';

enum _SupplierStatusFilterChoice { all, active, inactive }

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
  int _lastPage = 1;

  int? _statusFilter; // null: all, 1: active, 0: inactive
  String? _groupIdFilter;
  List<SupplierGroupRef> _groups = [];
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadReferences();
    _fetchSuppliers();
    AuthService.getCurrentUser().then((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  bool _can(String action) =>
      _user?.permissions['supplier.${action.toLowerCase()}'] ??
      (_user?.role == 'superadmin');

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
        _lastPage = res.lastPage;
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

  String get _statusFilterLabel => switch (_statusFilter) {
    1 => 'Aktif',
    0 => 'Nonaktif',
    _ => 'Semua Status',
  };

  String get _groupFilterLabel {
    if (_groupIdFilter == null) return 'Semua Grup';
    for (final group in _groups) {
      if (group.id.toString() == _groupIdFilter) return group.name;
    }
    return 'Grup Supplier';
  }

  Future<void> _showStatusFilterSheet() async {
    final selected = await showModalBottomSheet<_SupplierStatusFilterChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Status Supplier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183C32),
                ),
              ),
              const SizedBox(height: 10),
              for (final option
                  in const <
                    (_SupplierStatusFilterChoice, int?, String, IconData)
                  >[
                    (
                      _SupplierStatusFilterChoice.all,
                      null,
                      'Semua Status',
                      Icons.groups_rounded,
                    ),
                    (
                      _SupplierStatusFilterChoice.active,
                      1,
                      'Aktif',
                      Icons.check_circle_outline_rounded,
                    ),
                    (
                      _SupplierStatusFilterChoice.inactive,
                      0,
                      'Nonaktif',
                      Icons.block_rounded,
                    ),
                  ])
                ListTile(
                  leading: Icon(option.$4, color: const Color(0xFF1F7A2E)),
                  title: Text(option.$3),
                  trailing: _statusFilter == option.$2
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1F7A2E),
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, option.$1),
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || selected == null) return;
    final nextStatus = switch (selected) {
      _SupplierStatusFilterChoice.all => null,
      _SupplierStatusFilterChoice.active => 1,
      _SupplierStatusFilterChoice.inactive => 0,
    };
    setState(() => _statusFilter = nextStatus);
    await _fetchSuppliers(page: 1);
  }

  Future<void> _showGroupFilterSheet() async {
    var searchQuery = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          final filteredGroups = _groups.where((group) {
            final searchable = '${group.code} ${group.name}'.toLowerCase();
            return searchable.contains(searchQuery);
          }).toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.68,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Grup Supplier',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183C32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      onChanged: (value) => refresh(
                        () => searchQuery = value.trim().toLowerCase(),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari kode atau nama grup...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.all_inclusive_rounded,
                              color: Color(0xFF1F7A2E),
                            ),
                            title: const Text('Semua Grup'),
                            trailing: _groupIdFilter == null
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF1F7A2E),
                                  )
                                : null,
                            onTap: () => Navigator.pop(ctx, '__all__'),
                          ),
                          if (filteredGroups.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text('Grup supplier tidak ditemukan'),
                              ),
                            )
                          else
                            ...filteredGroups.map(
                              (group) => ListTile(
                                leading: const Icon(
                                  Icons.group_work_outlined,
                                  color: Color(0xFF1F7A2E),
                                ),
                                title: Text(group.name),
                                subtitle: Text(group.code),
                                trailing: _groupIdFilter == group.id.toString()
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xFF1F7A2E),
                                      )
                                    : null,
                                onTap: () =>
                                    Navigator.pop(ctx, group.id.toString()),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!mounted || selected == null) return;
    setState(() => _groupIdFilter = selected == '__all__' ? null : selected);
    await _fetchSuppliers(page: 1);
  }

  void _openAddSupplier() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SupplierFormPage()),
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
      floatingActionButton: _can('create') || _can('update')
          ? FloatingActionButton.extended(
              onPressed: _openAddSupplier,
              backgroundColor: green,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Tambah Supplier',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // 1. STATS BANNER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  _statItem(
                    'Total Pemasok',
                    '$_total',
                    const Color(0xFF1E88E5),
                    const Color(0xFFE3F2FD),
                  ),
                  const SizedBox(width: 10),
                  _statItem(
                    'Aktif',
                    '$_totalActive',
                    green,
                    const Color(0xFFE8F5E9),
                  ),
                  const SizedBox(width: 10),
                  _statItem(
                    'Non-Aktif',
                    '$_totalInactive',
                    const Color(0xFFD84315),
                    const Color(0xFFFBE9E7),
                  ),
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

            // 3. FILTER BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _filterDropdownButton(
                      icon: Icons.tune_rounded,
                      label: _statusFilterLabel,
                      active: _statusFilter != null,
                      onTap: _showStatusFilterSheet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _filterDropdownButton(
                      icon: Icons.group_work_outlined,
                      label: _groupFilterLabel,
                      active: _groupIdFilter != null,
                      onTap: _showGroupFilterSheet,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. SUPPLIER LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
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
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _fetchSuppliers(page: 1),
                      color: green,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                        itemCount: _suppliers.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _suppliers.length) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'Halaman sebelumnya',
                                    onPressed: _currentPage > 1
                                        ? () => _fetchSuppliers(
                                            page: _currentPage - 1,
                                          )
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                    ),
                                  ),
                                  Text(
                                    'Halaman $_currentPage dari $_lastPage',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Halaman berikutnya',
                                    onPressed: _currentPage < _lastPage
                                        ? () => _fetchSuppliers(
                                            page: _currentPage + 1,
                                          )
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
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

  Widget _filterDropdownButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    const green = Color(0xFF1F7A2E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F3E6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? green : const Color(0xFFE1E7DE)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: active ? green : const Color(0xFF7D8983),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? green : const Color(0xFF183C32),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
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
                                color:
                                    (supplier.isActive
                                            ? green
                                            : const Color(0xFFD84315))
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
              if (supplier.namaBank != null &&
                  supplier.nomorRekening != null) ...[
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
