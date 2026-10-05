import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/city_service.dart';
import '../services/district_service.dart';
import '../services/village_service.dart';
import '../services/province_service.dart';
import 'city_page.dart';
import 'district_page.dart';
import 'province_page.dart';

class VillagePage extends StatefulWidget {
  const VillagePage({super.key});

  @override
  State<VillagePage> createState() => _VillagePageState();
}

class _VillagePageState extends State<VillagePage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  UserModel? _user;
  bool _loading = true;
  bool _loadingCities = false;
  bool _loadingDistricts = false;
  String? _error;
  String? _provinceFilter;
  String? _cityFilter;
  String? _districtFilter;
  int _total = 0;
  int _currentPage = 1;
  int _lastPage = 1;

  bool _can(String action) {
    if (_user?.role?.toLowerCase() == 'superadmin') return true;
    return _user?.permissions['village.${action.toLowerCase()}'] == true;
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
    final result = await VillageService.list(
      search: _searchController.text,
      provinceCode: _provinceFilter,
      cityCode: _cityFilter,
      districtCode: _districtFilter,
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

  Future<void> _loadCities(String provinceCode) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
    });
    final result = await CityService.list(provinceCode: provinceCode);
    if (!mounted) return;
    setState(() {
      _loadingCities = false;
      _cities = result.success ? result.items : [];
    });
  }

  Future<void> _loadDistricts(String cityCode) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
    });
    final result = await DistrictService.list(cityCode: cityCode);
    if (!mounted) return;
    setState(() {
      _loadingDistricts = false;
      _districts = result.success ? result.items : [];
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 1));
  }

  String get _provinceFilterLabel =>
      _labelFor(_provinces, _provinceFilter, fallback: 'Semua Provinsi');

  String get _cityFilterLabel => _labelFor(
    _cities,
    _cityFilter,
    fallback: _provinceFilter == null
        ? 'Pilih provinsi dahulu'
        : 'Semua Kab/Kota',
  );

  String get _districtFilterLabel => _labelFor(
    _districts,
    _districtFilter,
    fallback: _cityFilter == null
        ? 'Pilih kabupaten/kota dahulu'
        : 'Semua Kecamatan',
  );

  Future<void> _chooseProvinceFilter() async {
    final selected = await _showRegionPicker(
      context,
      title: 'Pilih Provinsi',
      hint: 'Cari kode atau nama provinsi...',
      items: _provinces,
      selectedCode: _provinceFilter,
      allowAll: true,
      allLabel: 'Semua Provinsi',
      icon: Icons.map_outlined,
    );
    if (!mounted || selected == null) return;
    if (selected == '__all__') {
      setState(() {
        _provinceFilter = null;
        _cityFilter = null;
        _districtFilter = null;
        _cities = [];
        _districts = [];
      });
      await _load(page: 1);
      return;
    }
    setState(() {
      _provinceFilter = selected;
      _cityFilter = null;
      _districtFilter = null;
      _districts = [];
    });
    await _loadCities(selected);
    await _load(page: 1);
  }

  Future<void> _chooseCityFilter() async {
    if (_provinceFilter == null || _loadingCities) return;
    final selected = await _showRegionPicker(
      context,
      title: 'Pilih Kabupaten/Kota',
      hint: 'Cari kode atau nama kabupaten/kota...',
      items: _cities,
      selectedCode: _cityFilter,
      allowAll: true,
      allLabel: 'Semua Kabupaten/Kota',
      icon: Icons.location_city_outlined,
    );
    if (!mounted || selected == null) return;
    if (selected == '__all__') {
      setState(() {
        _cityFilter = null;
        _districtFilter = null;
        _districts = [];
      });
      await _load(page: 1);
      return;
    }
    setState(() {
      _cityFilter = selected;
      _districtFilter = null;
    });
    await _loadDistricts(selected);
    await _load(page: 1);
  }

  Future<void> _chooseDistrictFilter() async {
    if (_cityFilter == null || _loadingDistricts) return;
    final selected = await _showRegionPicker(
      context,
      title: 'Pilih Kecamatan',
      hint: 'Cari kode atau nama kecamatan...',
      items: _districts,
      selectedCode: _districtFilter,
      allowAll: true,
      allLabel: 'Semua Kecamatan',
      icon: Icons.route_outlined,
    );
    if (!mounted || selected == null) return;
    setState(() => _districtFilter = selected == '__all__' ? null : selected);
    await _load(page: 1);
  }

  Future<void> _openForm([Map<String, dynamic>? village]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _VillageFormDialog(village: village, provinces: _provinces),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            village == null
                ? 'Desa/Kelurahan berhasil ditambahkan.'
                : 'Desa/Kelurahan berhasil diperbarui.',
          ),
        ),
      );
      await _load(page: village == null ? 1 : _currentPage);
    }
  }

  Future<void> _delete(Map<String, dynamic> village) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Desa/Kelurahan?'),
        content: Text(
          '${village['code']} - ${village['name']} akan dihapus. Desa/Kelurahan yang masih digunakan tidak dapat dihapus.',
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
    final result = await VillageService.delete(village['id'].toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Gagal menghapus desa/kelurahan.',
        ),
      ),
    );
    if (result['success'] == true) await _load(page: 1);
  }

  void _openProvince() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const ProvincePage()),
  );

  void _openCity() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const CityPage()),
  );

  void _openDistrict() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const DistrictPage()),
  );

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
              'Desa/Kelurahan',
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
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text(
                'Tambah Desa/Kelurahan',
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
                    child: const Icon(Icons.route_rounded, color: ink),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Desa/Kelurahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Wilayah turunan dari kecamatan',
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
                    child: OutlinedButton(
                      onPressed: _openProvince,
                      child: const Text(
                        'Provinsi',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openCity,
                      child: const Text(
                        'Kab/Kota',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openDistrict,
                      child: const Text(
                        'Kecamatan',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: green,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: const Text('Desa', style: TextStyle(fontSize: 9)),
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
                  hintText: 'Cari kode, desa/kelurahan, kota, atau provinsi...',
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
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _provinces.isEmpty
                          ? null
                          : _chooseProvinceFilter,
                      icon: const Icon(Icons.map_outlined, size: 17),
                      label: Text(
                        _provinceFilterLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _provinceFilter == null || _loadingCities
                          ? null
                          : _chooseCityFilter,
                      icon: _loadingCities
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.location_city_outlined, size: 17),
                      label: Text(
                        _cityFilterLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cityFilter == null || _loadingDistricts
                      ? null
                      : _chooseDistrictFilter,
                  icon: _loadingDistricts
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.route_outlined, size: 17),
                  label: Text(
                    _districtFilterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      return const Center(child: Text('Desa/Kelurahan tidak ditemukan.'));
    }
    return RefreshIndicator(
      onRefresh: () => _load(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
        itemCount: _items.length + (_lastPage > 1 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _items.length) return _pagination();
          final village = _items[index];
          final district = village['kecamatan'] is Map
              ? (village['kecamatan'] as Map).cast<String, dynamic>()
              : <String, dynamic>{};
          final city = district['kota'] is Map
              ? (district['kota'] as Map).cast<String, dynamic>()
              : <String, dynamic>{};
          final province = city['provinsi'] is Map
              ? (city['provinsi'] as Map)['name']?.toString()
              : null;
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
                width: 58,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  village['code']?.toString() ?? '-',
                  style: TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                village['name']?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.w800, color: ink),
              ),
              subtitle: Text(
                [
                  district['name']?.toString() ??
                      village['district_code']?.toString() ??
                      '-',
                  city['name']?.toString() ?? '-',
                  province ?? '-',
                ].join(' \u2022 '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: (_can('update') || _can('delete'))
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(village);
                        if (value == 'delete') _delete(village);
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

class _VillageFormDialog extends StatefulWidget {
  final Map<String, dynamic>? village;
  final List<Map<String, dynamic>> provinces;

  const _VillageFormDialog({required this.provinces, this.village});

  @override
  State<_VillageFormDialog> createState() => _VillageFormDialogState();
}

class _VillageFormDialogState extends State<_VillageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cityFieldKey = GlobalKey<FormFieldState<String>>();
  final _districtFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  String? _provinceCode;
  String? _cityCode;
  String? _districtCode;
  bool _loadingCities = false;
  bool _loadingDistricts = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.village?['code']?.toString() ?? '',
    );
    _nameController = TextEditingController(
      text: widget.village?['name']?.toString() ?? '',
    );
    _districtCode = widget.village?['district_code']?.toString();
    final district = widget.village?['kecamatan'];
    if (district is Map) {
      _cityCode = district['city_code']?.toString();
      final city = district['kota'];
      if (city is Map) {
        _provinceCode = city['province_code']?.toString();
      }
    }
    _initializeParents();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCities(String provinceCode) async {
    setState(() => _loadingCities = true);
    final result = await CityService.list(provinceCode: provinceCode);
    if (!mounted) return;
    setState(() {
      _loadingCities = false;
      _cities = result.success ? result.items : [];
    });
  }

  Future<void> _loadDistricts(String cityCode) async {
    setState(() => _loadingDistricts = true);
    final result = await DistrictService.list(cityCode: cityCode);
    if (!mounted) return;
    setState(() {
      _loadingDistricts = false;
      _districts = result.success ? result.items : [];
    });
  }

  Future<void> _initializeParents() async {
    if (_provinceCode == null) return;
    await _loadCities(_provinceCode!);
    if (_cityCode != null) await _loadDistricts(_cityCode!);
  }

  Future<void> _pickProvince(FormFieldState<String> field) async {
    final selected = await _showRegionPicker(
      context,
      title: 'Pilih Provinsi',
      hint: 'Cari kode atau nama provinsi...',
      items: widget.provinces,
      selectedCode: _provinceCode,
      icon: Icons.map_outlined,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _provinceCode = selected;
      _cityCode = null;
      _districtCode = null;
      _cities = [];
      _districts = [];
    });
    field.didChange(selected);
    _cityFieldKey.currentState?.didChange(null);
    _districtFieldKey.currentState?.didChange(null);
    await _loadCities(selected);
  }

  Future<void> _pickCity(FormFieldState<String> field) async {
    if (_provinceCode == null || _loadingCities) return;
    final selected = await _showRegionPicker(
      context,
      title: 'Pilih Kabupaten/Kota',
      hint: 'Cari kode atau nama kabupaten/kota...',
      items: _cities,
      selectedCode: _cityCode,
      icon: Icons.location_city_outlined,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _cityCode = selected;
      _districtCode = null;
      _districts = [];
    });
    field.didChange(selected);
    _districtFieldKey.currentState?.didChange(null);
    await _loadDistricts(selected);
  }

  Future<void> _pickDistrict(FormFieldState<String> field) async {
    if (_cityCode == null || _loadingDistricts) return;
    final selected = await _showRegionPicker(
      context,
      title: 'Pilih Kecamatan',
      hint: 'Cari kode atau nama kecamatan...',
      items: _districts,
      selectedCode: _districtCode,
      icon: Icons.route_outlined,
    );
    if (!mounted || selected == null) return;
    setState(() => _districtCode = selected);
    field.didChange(selected);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await VillageService.save({
      'code': _codeController.text.trim(),
      'district_code': _districtCode,
      'name': _nameController.text.trim(),
    }, id: widget.village?['id']?.toString());
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
        widget.village == null
            ? 'Tambah Desa/Kelurahan'
            : 'Edit Desa/Kelurahan',
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
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Provinsi *',
                        prefixIcon: const Icon(Icons.map_outlined),
                        errorText: field.errorText,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _labelFor(
                                widget.provinces,
                                _provinceCode,
                                fallback: 'Pilih Provinsi',
                                withCode: true,
                              ),
                            ),
                          ),
                          const Icon(Icons.search_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FormField<String>(
                  key: _cityFieldKey,
                  initialValue: _cityCode,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Kabupaten/kota wajib dipilih'
                      : null,
                  builder: (field) => InkWell(
                    onTap: _saving || _provinceCode == null || _loadingCities
                        ? null
                        : () => _pickCity(field),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kabupaten/Kota *',
                        prefixIcon: _loadingCities
                            ? const Padding(
                                padding: EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.location_city_outlined),
                        errorText: field.errorText,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _labelFor(
                                _cities,
                                _cityCode,
                                fallback: _provinceCode == null
                                    ? 'Pilih provinsi dahulu'
                                    : 'Pilih Kabupaten/Kota',
                                withCode: true,
                              ),
                            ),
                          ),
                          const Icon(Icons.search_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FormField<String>(
                  key: _districtFieldKey,
                  initialValue: _districtCode,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Kecamatan wajib dipilih'
                      : null,
                  builder: (field) => InkWell(
                    onTap: _saving || _cityCode == null || _loadingDistricts
                        ? null
                        : () => _pickDistrict(field),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kecamatan *',
                        prefixIcon: _loadingDistricts
                            ? const Padding(
                                padding: EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.route_outlined),
                        errorText: field.errorText,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _labelFor(
                                _districts,
                                _districtCode,
                                fallback: _cityCode == null
                                    ? 'Pilih kabupaten/kota dahulu'
                                    : 'Pilih Kecamatan',
                                withCode: true,
                              ),
                            ),
                          ),
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
                    labelText: 'Kode Desa/Kelurahan *',
                    hintText: 'Contoh: 3571010001',
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
                    labelText: 'Nama Desa/Kelurahan *',
                    hintText: 'Contoh: Bandar Lor',
                    prefixIcon: Icon(Icons.route_outlined),
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

String _labelFor(
  List<Map<String, dynamic>> items,
  String? selectedCode, {
  required String fallback,
  bool withCode = false,
}) {
  if (selectedCode == null) return fallback;
  final match = items.where((item) => item['code']?.toString() == selectedCode);
  if (match.isEmpty) return fallback;
  final item = match.first;
  return withCode
      ? '${item['code']} - ${item['name']}'
      : item['name']?.toString() ?? fallback;
}

Future<String?> _showRegionPicker(
  BuildContext context, {
  required String title,
  required String hint,
  required List<Map<String, dynamic>> items,
  required IconData icon,
  String? selectedCode,
  bool allowAll = false,
  String allLabel = 'Semua',
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
        final filtered = items.where((item) {
          final text = '${item['code'] ?? ''} ${item['name'] ?? ''}'
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (value) =>
                        refresh(() => query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: hint,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        if (allowAll)
                          ListTile(
                            leading: const Icon(Icons.public_rounded),
                            title: Text(allLabel),
                            trailing: selectedCode == null
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF1F7A2E),
                                  )
                                : null,
                            onTap: () => Navigator.pop(sheetContext, '__all__'),
                          ),
                        ...filtered.map((item) {
                          final code = item['code']?.toString() ?? '';
                          return ListTile(
                            leading: Icon(icon, color: const Color(0xFF1F7A2E)),
                            title: Text(item['name']?.toString() ?? '-'),
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
