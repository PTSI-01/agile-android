import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/province_service.dart';
import 'city_page.dart';
import 'district_page.dart';

class ProvincePage extends StatefulWidget {
  const ProvincePage({super.key});

  @override
  State<ProvincePage> createState() => _ProvincePageState();
}

class _ProvincePageState extends State<ProvincePage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  int _lastPage = 1;

  bool _can(String action) {
    if (_user?.role?.toLowerCase() == 'superadmin') return true;
    return _user?.permissions['province.${action.toLowerCase()}'] == true;
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await AuthService.refreshCurrentUser();
    if (mounted) setState(() => _user = user);
    await _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final result = await ProvinceService.list(
      search: _searchController.text,
      page: page,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.success ? null : result.message;
      if (result.success) {
        _items = result.items;
        _total = result.total;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 1));
  }

  Future<void> _openForm([Map<String, dynamic>? province]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProvinceFormDialog(province: province),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            province == null
                ? 'Provinsi berhasil ditambahkan.'
                : 'Provinsi berhasil diperbarui.',
          ),
        ),
      );
      await _load(page: province == null ? 1 : _currentPage);
    }
  }

  Future<void> _delete(Map<String, dynamic> province) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Provinsi?'),
        content: Text(
          '${province['code']} - ${province['name']} akan dihapus. Provinsi yang masih memiliki kabupaten/kota tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD14942),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ProvinceService.delete(province['id'].toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Gagal menghapus provinsi.',
        ),
      ),
    );
    if (result['success'] == true) await _load(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F7A2E);
    const ink = Color(0xFF183C32);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Wilayah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Provinsi',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            onPressed: () => _load(page: 1),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _can('create')
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text(
                'Tambah Provinsi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF185A36), Color(0xFF287D3C)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4C430),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.map_rounded, color: ink),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Provinsi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Referensi wilayah untuk supplier dan transaksi',
                          style: TextStyle(
                            color: Color(0xFFD7E8D7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: green,
                        disabledForegroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text(
                        'Provinsi',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CityPage()),
                      ),
                      icon: const Icon(Icons.location_city_rounded, size: 16),
                      label: const Text(
                        'Kab/Kota',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DistrictPage()),
                      ),
                      child: const Text(
                        'Kecamatan',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari kode atau nama provinsi...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _load(page: 1);
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE1E7DE)),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(green, ink)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color green, Color ink) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Color(0xFFD14942),
              ),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _load(page: 1),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Data provinsi tidak ditemukan.'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
        itemCount: _items.length + (_lastPage > 1 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _items.length) return _pagination();
          final province = _items[index];
          final cityCount = province['cities_count'];
          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE1E7DE)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              leading: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  province['code']?.toString() ?? '-',
                  style: TextStyle(
                    color: green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                province['name']?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.w800, color: ink),
              ),
              subtitle: Text(
                cityCount == null
                    ? 'Data provinsi'
                    : '$cityCount kabupaten/kota',
              ),
              trailing: (_can('update') || _can('delete'))
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(province);
                        if (value == 'delete') _delete(province);
                      },
                      itemBuilder: (_) => [
                        if (_can('update'))
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                            ),
                          ),
                        if (_can('delete'))
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFD14942),
                              ),
                              title: Text('Hapus'),
                            ),
                          ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _pagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1
              ? () => _load(page: _currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          'Halaman $_currentPage dari $_lastPage',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: _currentPage < _lastPage
              ? () => _load(page: _currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _ProvinceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? province;

  const _ProvinceFormDialog({this.province});

  @override
  State<_ProvinceFormDialog> createState() => _ProvinceFormDialogState();
}

class _ProvinceFormDialogState extends State<_ProvinceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.province?['code']?.toString() ?? '',
    );
    _nameController = TextEditingController(
      text: widget.province?['name']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ProvinceService.save({
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
    }, id: widget.province?['id']?.toString());
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = result['message']?.toString() ?? 'Gagal menyimpan provinsi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F7A2E);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        widget.province == null ? 'Tambah Provinsi' : 'Edit Provinsi',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _codeController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Kode Provinsi *',
                    hintText: 'Contoh: 35',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kode provinsi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Provinsi *',
                    hintText: 'Contoh: Jawa Timur',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama provinsi wajib diisi'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: green),
          icon: _saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}
