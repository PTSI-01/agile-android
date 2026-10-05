import 'package:flutter/material.dart';

import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'supplier_form_page.dart';

class SupplierDetailPage extends StatefulWidget {
  final String supplierId;

  const SupplierDetailPage({super.key, required this.supplierId});

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SupplierModel? _supplier;
  UserModel? _user;
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDetail();
    AuthService.getCurrentUser().then((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  bool _can(String action) =>
      _user?.permissions['supplier.${action.toLowerCase()}'] ??
      (_user?.role == 'superadmin');

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final data = await SupplierService.getSupplierDetail(widget.supplierId);
    if (mounted) {
      setState(() {
        _supplier = data;
        _isLoading = false;
      });
    }
  }

  void _openEdit() async {
    if (_supplier == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormPage(supplier: _supplier)),
    );
    if (updated == true) {
      _hasChanged = true;
      _loadDetail();
    }
  }

  void _toggleStatus() async {
    if (_supplier == null) return;
    final isCurrentlyActive = _supplier!.isActive;
    final actionLabel = isCurrentlyActive ? 'nonaktifkan' : 'aktifkan';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi $actionLabel Supplier'),
        content: Text(
          'Apakah Anda yakin ingin $actionLabel status supplier ${_supplier!.namaVendor}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isCurrentlyActive
                  ? Color(0xFFD14942)
                  : Color(0xFF1F7A2E),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isCurrentlyActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await SupplierService.toggleStatus(_supplier!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Status berhasil diubah'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _hasChanged = true;
        _loadDetail();
      }
    }
  }

  Future<void> _forceDelete() async {
    final supplier = _supplier;
    if (supplier == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus supplier permanen?'),
        content: Text(
          'Data ${supplier.namaVendor} akan dihapus permanen dan tidak dapat dipulihkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFD14942)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus Permanen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await SupplierService.forceDelete(supplier.id);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Supplier berhasil dihapus permanen.',
          ),
          backgroundColor: Color(0xFF1F7A2E),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Gagal menghapus supplier permanen.',
          ),
          backgroundColor: Color(0xFFD14942),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    const muted = Color(0xFF7D8983);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanged) {
          // Pass signal back to parent list
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Detail Supplier',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            if (_supplier != null) ...[
              if (_can('update'))
                IconButton(
                  tooltip: 'Edit Data',
                  icon: Icon(Icons.edit_outlined, color: ink),
                  onPressed: _openEdit,
                ),
              if (_can('delete'))
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'toggle_status') _toggleStatus();
                    if (val == 'force_delete') _forceDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            _supplier!.isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: _supplier!.isActive
                                ? Color(0xFFD14942)
                                : green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _supplier!.isActive
                                ? 'Nonaktifkan Supplier'
                                : 'Aktifkan Supplier',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'force_delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever_rounded,
                            size: 18,
                            color: Color(0xFFD14942),
                          ),
                          SizedBox(width: 8),
                          Text('Hapus Permanen'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: green))
            : _supplier == null
            ? Center(child: Text('Data supplier tidak ditemukan.'))
            : SafeArea(
                child: Column(
                  children: [
                    // 1. HEADER PROFILE CARD
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(0xFFE9EDE5)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFFE3EBD9),
                              child: Text(
                                _supplier!.initials,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ink.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Text(
                                          _supplier!.vendorId,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (_supplier!.isActive
                                                      ? green
                                                      : Color(0xFFD84315))
                                                  .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          _supplier!.isActive
                                              ? 'Aktif'
                                              : 'Non-Aktif',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _supplier!.isActive
                                                ? green
                                                : Color(0xFFD84315),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    _supplier!.namaVendor,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  if (_supplier!.supplierGroupName != null) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      'Grup: ${_supplier!.supplierGroupName}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. TABS
                    TabBar(
                      controller: _tabController,
                      labelColor: green,
                      unselectedLabelColor: muted,
                      indicatorColor: green,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: 'Informasi Vendor'),
                        Tab(text: 'Alamat & KTP'),
                        Tab(text: 'Rekening Bank'),
                        Tab(text: 'Data NPWP'),
                      ],
                    ),

                    // 3. TAB VIEWS
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInfoTab(),
                          _buildAddressTab(),
                          _buildBankTab(),
                          _buildNpwpTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: _supplier != null
            ? Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: Color(0xFFE9EDE5))),
                ),
                child: Row(
                  children: [
                    if (_can('update'))
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openEdit,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ink,
                            side: BorderSide(color: Color(0xFFE9EDE5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(Icons.edit_note_rounded, size: 20),
                          label: Text('Edit Supplier'),
                        ),
                      ),
                    if (_can('update') && _can('delete')) SizedBox(width: 12),
                    if (_can('delete'))
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleStatus,
                          style: FilledButton.styleFrom(
                            backgroundColor: _supplier!.isActive
                                ? Color(0xFFD14942)
                                : green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(
                            _supplier!.isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _supplier!.isActive ? 'Nonaktifkan' : 'Aktifkan',
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _infoCard([
          _item('Kode Vendor', _supplier!.vendorId),
          _item('Nama Vendor / Usaha', _supplier!.namaVendor),
          _item('Nomor Telepon / HP', _supplier!.nomorHp ?? '-'),
          _item('Alamat Email', _supplier!.email ?? '-'),
          _item('Grup Supplier', _supplier!.supplierGroupName ?? '-'),
          _item('Buyer Terkait', _supplier!.buyerName ?? '-'),
        ]),
      ],
    );
  }

  Widget _buildAddressTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _infoCard([
          _item('Nomor NIK / KTP', _supplier!.nomorKtp ?? '-'),
          _item('Nama Sesuai KTP', _supplier!.namaKtp ?? '-'),
          _item(
            'Alamat Jalan KTP',
            _supplier!.jalanAlamatKtp ?? _supplier!.alamatLengkapKtp ?? '-',
          ),
          _item(
            'RT / RW',
            'RT ${_supplier!.rtKtp ?? '-'} / RW ${_supplier!.rwKtp ?? '-'}',
          ),
          _item('Provinsi', _supplier!.ktpProvinceName ?? '-'),
          _item('Kota / Kabupaten', _supplier!.ktpCityName ?? '-'),
        ]),
      ],
    );
  }

  Widget _buildBankTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _infoCard([
          _item('Nama Bank', _supplier!.namaBank ?? '-'),
          _item('Nomor Rekening', _supplier!.nomorRekening ?? '-'),
          _item('Nama Pemilik Rekening', _supplier!.namaPenerimaBank ?? '-'),
          _item('Kantor Cabang', _supplier!.cabangBank ?? '-'),
        ]),
      ],
    );
  }

  Widget _buildNpwpTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _infoCard([
          _item('Nomor Pokok Wajib Pajak (NPWP)', _supplier!.nomorNpwp ?? '-'),
          _item('Nama Wajib Pajak Sesuai NPWP', _supplier!.namaNpwp ?? '-'),
        ]),
      ],
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE9EDE5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7D8983),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
