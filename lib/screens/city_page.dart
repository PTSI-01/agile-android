import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/city_service.dart';
import '../services/province_service.dart';
import 'district_page.dart';

class CityPage extends StatefulWidget {
  const CityPage({super.key});

  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _provinces = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;
  String? _provinceFilter;
  int _total = 0;
  int _currentPage = 1;
  int _lastPage = 1;

  bool _can(String action) {
    if (_user?.role?.toLowerCase() == 'superadmin') return true;
    return _user?.permissions['city.${action.toLowerCase()}'] == true;
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final results = await Future.wait([
      AuthService.refreshCurrentUser(),
      ProvinceService.list(),
    ]);
    if (!mounted) return;
    final provinceResult = results[1] as ProvinceListResult;
    setState(() {
      _user = results[0] as UserModel?;
      _provinces = provinceResult.items;
    });
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
    final result = await CityService.list(
      search: _searchController.text,
      provinceCode: _provinceFilter,
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

  String get _provinceFilterLabel {
    if (_provinceFilter == null) return 'Semua Provinsi';
    final match = _provinces.where(
      (province) => province['code']?.toString() == _provinceFilter,
    );
    return match.isEmpty
        ? 'Provinsi'
        : match.first['name']?.toString() ?? 'Provinsi';
  }

  Future<void> _chooseFilter() async {
    final selected = await _showProvincePicker(
      context,
      provinces: _provinces,
      selectedCode: _provinceFilter,
      allowAll: true,
    );
    if (!mounted || selected == null) return;
    setState(() => _provinceFilter = selected == '__all__' ? null : selected);
    await _load(page: 1);
  }

  Future<void> _openForm([Map<String, dynamic>? city]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CityFormDialog(city: city, provinces: _provinces),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            city == null
                ? 'Kabupaten/kota berhasil ditambahkan.'
                : 'Kabupaten/kota berhasil diperbarui.',
          ),
        ),
      );
      await _load(page: city == null ? 1 : _currentPage);
    }
  }

  Future<void> _delete(Map<String, dynamic> city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kabupaten/Kota?'),
        content: Text(
          '${city['code']} - ${city['name']} akan dihapus. Data yang sudah memiliki kecamatan tidak dapat dihapus.',
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
    final result = await CityService.delete(city['id'].toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Gagal menghapus kabupaten/kota.',
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
              'Kabupaten / Kota',
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
              onPressed: _provinces.isEmpty ? null : _openForm,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text(
                'Tambah Kabupaten/Kota',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(18, 10, 18, 10),
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
                    child: const Icon(Icons.location_city_rounded, color: ink),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Kabupaten/Kota',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Wilayah turunan dari master provinsi',
                          style: TextStyle(
                            color: Color(0xFFD7E8D7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
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
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text(
                        'Provinsi',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: green,
                        disabledForegroundColor: Colors.white,
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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari kode, kota, atau provinsi...',
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
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _provinces.isEmpty ? null : _chooseFilter,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: Text(
                    _provinceFilterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
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
      return const Center(child: Text('Kabupaten/kota tidak ditemukan.'));
    }
    return RefreshIndicator(
      onRefresh: () => _load(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
        itemCount: _items.length + (_lastPage > 1 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _items.length) return _pagination();
          final city = _items[index];
          final province = city['provinsi'] is Map
              ? (city['provinsi'] as Map)['name']?.toString()
              : null;
          final districtCount = city['districts_count'];
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
                width: 52,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  city['code']?.toString() ?? '-',
                  style: TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                city['name']?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.w800, color: ink),
              ),
              subtitle: Text(
                [
                  province ?? city['province_code']?.toString() ?? '-',
                  if (districtCount != null) '$districtCount kecamatan',
                ].join(' • '),
              ),
              trailing: (_can('update') || _can('delete'))
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(city);
                        if (value == 'delete') _delete(city);
                      },
                      itemBuilder: (_) => [
                        if (_can('update'))
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (_can('delete'))
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus'),
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

  Widget _pagination() => Row(
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

class _CityFormDialog extends StatefulWidget {
  final Map<String, dynamic>? city;
  final List<Map<String, dynamic>> provinces;

  const _CityFormDialog({required this.provinces, this.city});

  @override
  State<_CityFormDialog> createState() => _CityFormDialogState();
}

class _CityFormDialogState extends State<_CityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  String? _provinceCode;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.city?['code']?.toString() ?? '',
    );
    _nameController = TextEditingController(
      text: widget.city?['name']?.toString() ?? '',
    );
    _provinceCode = widget.city?['province_code']?.toString();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _provinceLabel {
    final match = widget.provinces.where(
      (province) => province['code']?.toString() == _provinceCode,
    );
    return match.isEmpty
        ? 'Pilih Provinsi'
        : '${match.first['code']} - ${match.first['name']}';
  }

  Future<void> _pickProvince(FormFieldState<String> field) async {
    final selected = await _showProvincePicker(
      context,
      provinces: widget.provinces,
      selectedCode: _provinceCode,
    );
    if (!mounted || selected == null) return;
    setState(() => _provinceCode = selected);
    field.didChange(selected);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await CityService.save({
      'code': _codeController.text.trim(),
      'province_code': _provinceCode,
      'name': _nameController.text.trim(),
    }, id: widget.city?['id']?.toString());
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = result['message']?.toString() ?? 'Gagal menyimpan data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F7A2E);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        widget.city == null ? 'Tambah Kabupaten/Kota' : 'Edit Kabupaten/Kota',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 430,
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
                FormField<String>(
                  initialValue: _provinceCode,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Provinsi wajib dipilih'
                      : null,
                  builder: (field) => InkWell(
                    onTap: _saving ? null : () => _pickProvince(field),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Provinsi *',
                        prefixIcon: const Icon(Icons.map_outlined),
                        errorText: field.errorText,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(_provinceLabel)),
                          const Icon(Icons.search_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Kode Kabupaten/Kota *',
                    hintText: 'Contoh: 3571',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kode wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kabupaten/Kota *',
                    hintText: 'Contoh: Kabupaten Kediri',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi'
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

Future<String?> _showProvincePicker(
  BuildContext context, {
  required List<Map<String, dynamic>> provinces,
  String? selectedCode,
  bool allowAll = false,
}) async {
  var query = '';
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, refresh) {
        final filtered = provinces.where((province) {
          final text = '${province['code'] ?? ''} ${province['name'] ?? ''}'
              .toLowerCase();
          return text.contains(query);
        }).toList();
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.68,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Provinsi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (value) =>
                        refresh(() => query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Cari kode atau nama provinsi...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        if (allowAll)
                          ListTile(
                            leading: const Icon(Icons.public_rounded),
                            title: const Text('Semua Provinsi'),
                            trailing: selectedCode == null
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF1F7A2E),
                                  )
                                : null,
                            onTap: () => Navigator.pop(sheetContext, '__all__'),
                          ),
                        ...filtered.map((province) {
                          final code = province['code']?.toString() ?? '';
                          return ListTile(
                            leading: const Icon(
                              Icons.map_outlined,
                              color: Color(0xFF1F7A2E),
                            ),
                            title: Text(province['name']?.toString() ?? '-'),
                            subtitle: Text(code),
                            trailing: selectedCode == code
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF1F7A2E),
                                  )
                                : null,
                            onTap: () => Navigator.pop(sheetContext, code),
                          );
                        }),
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
}
