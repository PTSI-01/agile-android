import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';

class UnitConversionPage extends StatefulWidget {
  const UnitConversionPage({super.key});

  @override
  State<UnitConversionPage> createState() => _UnitConversionPageState();
}

class _UnitConversionPageState extends State<UnitConversionPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _conversions = [];
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

  bool _can(String action) {
    final permissions = _user?.permissions ?? <String, bool>{};
    return permissions['master_unit_conversion.$action'] == true ||
        _user?.role == 'superadmin';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await MasterDataService.listUnitConversions(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _conversions = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 400), _load);
  }

  String _unitLabel(dynamic raw) {
    if (raw is! Map) return '-';
    final unit = raw.cast<String, dynamic>();
    final code = unit['kode_satuan']?.toString() ?? '-';
    final name = unit['nama_satuan']?.toString() ?? '-';
    return '$code - $name';
  }

  bool _isActive(Map<String, dynamic> row) => row['status'] == 'aktif';

  Future<void> _openForm([Map<String, dynamic>? conversion]) async {
    try {
      final references = await MasterDataService.unitConversionReferences(
        conversionId: conversion?['id']?.toString(),
      );
      if (!mounted) return;
      final payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _UnitConversionForm(
          conversion: conversion,
          units: (references['units'] as List? ?? [])
              .whereType<Map>()
              .map((row) => row.cast<String, dynamic>())
              .toList(),
        ),
      );
      if (payload == null || !mounted) return;
      await MasterDataService.saveUnitConversion(
        payload,
        id: conversion?['id']?.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conversion == null
                ? 'Konversi satuan berhasil ditambahkan.'
                : 'Konversi satuan berhasil diperbarui.',
          ),
          backgroundColor: Color(0xFF1F7A2E),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Color(0xFFD14942),
        ),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> conversion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus konversi satuan?'),
        content: Text(
          '${_unitLabel(conversion['from_unit'])} ke ${_unitLabel(conversion['to_unit'])} akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFD14942)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await MasterDataService.deleteUnitConversion(conversion['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konversi satuan berhasil dihapus.'),
          backgroundColor: Color(0xFF1F7A2E),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Color(0xFFD14942),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    final activeCount = _conversions.where(_isActive).length;
    final inactiveCount = _conversions.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Konversi Satuan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, color: ink),
          ),
        ],
      ),
      floatingActionButton: _can('create')
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add_rounded),
              label: Text(
                'Tambah Konversi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  _statItem(
                    'Total Konversi',
                    '${_conversions.length}',
                    Color(0xFF1E88E5),
                  ),
                  SizedBox(width: 10),
                  _statItem('Aktif', '$activeCount', green),
                  SizedBox(width: 10),
                  _statItem('Nonaktif', '$inactiveCount', Color(0xFFD84315)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari kode atau nama satuan...',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            _load();
                          },
                          icon: Icon(Icons.clear_rounded),
                        ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Color(0xFFE9EDE5)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Expanded(child: _buildList(ink, green)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(0xFFE9EDE5)),
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
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Color(0xFF7D8983)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Color ink, Color green) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF1F7A2E)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFD14942)),
              SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_conversions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: 150),
            Icon(Icons.swap_horiz_rounded, size: 52, color: Color(0xFF9AA49F)),
            SizedBox(height: 12),
            Center(child: Text('Belum ada konversi satuan')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: green,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 90),
        itemCount: _conversions.length,
        separatorBuilder: (_, _) => SizedBox(height: 10),
        itemBuilder: (_, index) {
          final row = _conversions[index];
          final fromUnit = _unitLabel(row['from_unit']);
          final toUnit = _unitLabel(row['to_unit']);
          final active = _isActive(row);
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _can('update') ? () => _openForm(row) : null,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Color(0xFFE9EDE5)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFE3EBD9),
                      child: Icon(Icons.swap_horiz_rounded, color: ink),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$fromUnit  \u2192  $toUnit',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (active ? green : Color(0xFFD84315))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  active ? 'Aktif' : 'Nonaktif',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: active ? green : Color(0xFFD84315),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Nilai konversi: ${row['conversion_value'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7D8983),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_can('update') || _can('delete'))
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _openForm(row);
                          if (value == 'delete') _delete(row);
                        },
                        itemBuilder: (_) => [
                          if (_can('update'))
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                          if (_can('delete'))
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                        ],
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
}

class _UnitConversionForm extends StatefulWidget {
  final Map<String, dynamic>? conversion;
  final List<Map<String, dynamic>> units;

  const _UnitConversionForm({required this.units, this.conversion});

  @override
  State<_UnitConversionForm> createState() => _UnitConversionFormState();
}

class _UnitConversionFormState extends State<_UnitConversionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late String? _fromUnitId;
  late String? _toUnitId;
  late String _status;

  bool get _isEdit => widget.conversion != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.conversion?['conversion_value']?.toString() ?? '',
    );
    _fromUnitId = widget.conversion?['from_unit_id']?.toString();
    _toUnitId = widget.conversion?['to_unit_id']?.toString();
    _status = widget.conversion?['status']?.toString() == 'nonaktif'
        ? 'nonaktif'
        : 'aktif';
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _unitName(Map<String, dynamic> unit) =>
      '${unit['kode_satuan']} - ${unit['nama_satuan']}';

  String? _validateValue(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return 'Nilai harus lebih besar dari 0';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_fromUnitId == _toUnitId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satuan asal dan tujuan harus berbeda.')),
      );
      return;
    }
    Navigator.pop(context, {
      'from_unit_id': _fromUnitId,
      'to_unit_id': _toUnitId,
      'conversion_value': _valueController.text.trim().replaceAll(',', '.'),
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Konversi Satuan' : 'Tambah Konversi Satuan'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _fromUnitId,
                  decoration: InputDecoration(labelText: 'Dari Satuan'),
                  validator: (value) =>
                      value == null ? 'Pilih satuan asal' : null,
                  items: widget.units
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit['id'].toString(),
                          child: Text(_unitName(unit)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _fromUnitId = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _toUnitId,
                  decoration: InputDecoration(labelText: 'Ke Satuan'),
                  validator: (value) =>
                      value == null ? 'Pilih satuan tujuan' : null,
                  items: widget.units
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit['id'].toString(),
                          child: Text(_unitName(unit)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _toUnitId = value),
                ),
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(labelText: 'Nilai Konversi'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _validateValue,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(labelText: 'Status'),
                  items: [
                    DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'nonaktif',
                      child: Text('Nonaktif'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'aktif'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
