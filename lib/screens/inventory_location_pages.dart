import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';

enum _LocationKind { warehouse, bin }

class MasterWarehousePage extends StatelessWidget {
  const MasterWarehousePage({super.key});

  @override
  Widget build(BuildContext context) =>
      _InventoryLocationPage(kind: _LocationKind.warehouse);
}

class MasterBinPage extends StatelessWidget {
  const MasterBinPage({super.key});

  @override
  Widget build(BuildContext context) =>
      _InventoryLocationPage(kind: _LocationKind.bin);
}

class _InventoryLocationPage extends StatefulWidget {
  final _LocationKind kind;

  const _InventoryLocationPage({required this.kind});

  @override
  State<_InventoryLocationPage> createState() => _InventoryLocationPageState();
}

class _InventoryLocationPageState extends State<_InventoryLocationPage> {
  static const _green = Color(0xFF1F7A2E);
  static const _ink = Color(0xFF183C32);
  static const _gold = Color(0xFFE7AA19);

  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _rows = [];
  UserModel? _user;
  String _status = 'semua';
  String? _error;
  bool _loading = true;

  bool get _warehouse => widget.kind == _LocationKind.warehouse;
  String get _title => _warehouse ? 'Master Gudang' : 'Master Bin';
  String get _entity => _warehouse ? 'Gudang' : 'Bin';
  String get _permission => _warehouse ? 'master_warehouse' : 'master_bin';
  String get _codeKey => _warehouse ? 'warehouse_code' : 'bin_code';
  String get _nameKey => _warehouse ? 'warehouse_name' : 'bin_name';

  @override
  void initState() {
    super.initState();
    _load();
    AuthService.refreshCurrentUser().then((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _can(String action) =>
      _user?.role?.toLowerCase() == 'superadmin' ||
      _user?.permissions['$_permission.${action.toLowerCase()}'] == true;

  bool _active(Map<String, dynamic> row) => {
    'aktif',
    'active',
    '1',
  }.contains(row['status']?.toString().toLowerCase());

  List<Map<String, dynamic>> get _visibleRows {
    if (_status == 'semua') return _rows;
    final active = _status == 'aktif';
    return _rows.where((row) => _active(row) == active).toList();
  }

  int _relationCount(Map<String, dynamic> row) {
    if (_warehouse) {
      final count = row['bins_count'];
      if (count != null) return int.tryParse(count.toString()) ?? 0;
      return (row['bins'] as List?)?.length ?? 0;
    }
    return row['warehouse_id'] == null ? 0 : 1;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = _warehouse
          ? await MasterDataService.listWarehouses(
              search: _searchController.text,
            )
          : await MasterDataService.listBins(search: _searchController.text);
      if (mounted) setState(() => _rows = rows);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 400), _load);
    setState(() {});
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Color(0xFFB3261E) : _green,
      ),
    );
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationFormSheet(kind: widget.kind, record: row),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${_entity.toLowerCase()}?'),
        content: Text(
          '${row[_codeKey]} - ${row[_nameKey]} akan dihapus.${_warehouse ? ' Gudang yang masih dipakai bin atau item tidak dapat dihapus.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (_warehouse) {
        await MasterDataService.deleteWarehouse(row['id'].toString());
      } else {
        await MasterDataService.deleteBin(row['id'].toString());
      }
      if (!mounted) return;
      _notice('$_entity berhasil dihapus.');
      _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> initial) async {
    var row = initial;
    try {
      row = _warehouse
          ? await MasterDataService.getWarehouse(initial['id'].toString())
          : await MasterDataService.getBin(initial['id'].toString());
    } catch (_) {
      // Relasi pada data daftar tetap cukup untuk tampilan cadangan.
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LocationDetailSheet(
        kind: widget.kind,
        record: row,
        canUpdate: _can('update'),
        canDelete: _can('delete'),
        onEdit: () {
          Navigator.pop(sheetContext);
          _openForm(row);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _delete(row);
        },
      ),
    );
  }

  String _relationLabel(Map<String, dynamic> row) {
    final relation = row[_warehouse ? 'site' : 'warehouse'];
    if (relation is Map) {
      final code = relation[_warehouse ? 'site_code' : 'warehouse_code'];
      final name = relation[_warehouse ? 'site_name' : 'warehouse_name'];
      if (code != null || name != null) {
        return '${code ?? '-'} - ${name ?? '-'}';
      }
    }
    return _warehouse ? 'Site belum dipilih' : 'Gudang belum dipilih';
  }

  @override
  Widget build(BuildContext context) {
    final active = _rows.where(_active).length;
    final related = _warehouse
        ? _rows.fold<int>(0, (total, row) => total + _relationCount(row))
        : _rows
              .map((row) => row['warehouse_id']?.toString())
              .whereType<String>()
              .toSet()
              .length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _title,
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _can('create')
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add_rounded),
              label: Text('Tambah $_entity'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari kode atau nama ${_entity.toLowerCase()}...',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                        icon: Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFD9E3D7)),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    value: '${_rows.length}',
                    label: _entity,
                    icon: _warehouse
                        ? Icons.warehouse_rounded
                        : Icons.inventory_2_rounded,
                    color: _green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    value: '$active',
                    label: 'Aktif',
                    icon: Icons.check_circle_rounded,
                    color: _gold,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    value: '$related',
                    label: _warehouse ? 'Bin' : 'Gudang',
                    icon: _warehouse
                        ? Icons.inventory_2_rounded
                        : Icons.warehouse_rounded,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final option in [
                  ('semua', 'Semua'),
                  ('aktif', 'Aktif'),
                  ('nonaktif', 'Nonaktif'),
                ]) ...[
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: _status == option.$1,
                    onSelected: (_) => setState(() => _status = option.$1),
                    selectedColor: Color(0xFFDCEED7),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _status == option.$1 ? _green : _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 42, color: _green),
              SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 14),
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
    final rows = _visibleRows;
    if (rows.isEmpty) {
      return Center(
        child: Text('Data ${_entity.toLowerCase()} tidak ditemukan.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(18, 2, 18, 96),
        itemCount: rows.length,
        separatorBuilder: (_, _) => SizedBox(height: 10),
        itemBuilder: (_, index) {
          final row = rows[index];
          final isActive = _active(row);
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDetail(row),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F3E4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _warehouse
                            ? Icons.warehouse_rounded
                            : Icons.inventory_2_rounded,
                        color: _green,
                        size: 27,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row[_nameKey]?.toString() ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            row[_codeKey]?.toString() ?? '-',
                            style: TextStyle(
                              color: Color(0xFFA66F00),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            _relationLabel(row),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF66756D),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text(isActive ? 'Aktif' : 'Nonaktif'),
                      backgroundColor: isActive
                          ? Color(0xFFE2F2DD)
                          : Color(0xFFFFE4DF),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: isActive ? _green : Color(0xFFB3261E),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey),
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

class _LocationFormSheet extends StatefulWidget {
  final _LocationKind kind;
  final Map<String, dynamic>? record;

  const _LocationFormSheet({required this.kind, this.record});

  @override
  State<_LocationFormSheet> createState() => _LocationFormSheetState();
}

class _LocationFormSheetState extends State<_LocationFormSheet> {
  static const _green = Color(0xFF1F7A2E);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  String? _relationId;
  String _status = 'aktif';
  bool _loadingReferences = true;
  bool _saving = false;
  String? _referenceError;
  List<Map<String, dynamic>> _references = [];

  bool get _warehouse => widget.kind == _LocationKind.warehouse;
  String get _entity => _warehouse ? 'Gudang' : 'Bin';
  String get _codeKey => _warehouse ? 'warehouse_code' : 'bin_code';
  String get _nameKey => _warehouse ? 'warehouse_name' : 'bin_name';
  String get _relationKey => _warehouse ? 'site_id' : 'warehouse_id';
  String get _relationName => _warehouse ? 'Site' : 'Gudang';
  String get _referenceCodeKey => _warehouse ? 'site_code' : 'warehouse_code';
  String get _referenceNameKey => _warehouse ? 'site_name' : 'warehouse_name';

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(
      text: widget.record?[_codeKey]?.toString() ?? '',
    );
    _name = TextEditingController(
      text: widget.record?[_nameKey]?.toString() ?? '',
    );
    _relationId = widget.record?[_relationKey]?.toString();
    final status = widget.record?['status']?.toString().toLowerCase();
    _status = status == 'nonaktif' || status == 'inactive' || status == '0'
        ? 'nonaktif'
        : 'aktif';
    _loadReferences();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _loadingReferences = true;
      _referenceError = null;
    });
    try {
      final rows = _warehouse
          ? await MasterDataService.listSites()
          : await MasterDataService.listWarehouses();
      if (!mounted) return;
      setState(() => _references = rows);
    } catch (error) {
      if (mounted) {
        setState(() {
          _referenceError = error.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loadingReferences = false);
    }
  }

  String _referenceLabel(Map<String, dynamic> row) =>
      '${row[_referenceCodeKey] ?? '-'} - ${row[_referenceNameKey] ?? '-'}';

  Map<String, dynamic>? get _selectedReference {
    for (final row in _references) {
      if (row['id']?.toString() == _relationId) return row;
    }
    final nested = widget.record?[_warehouse ? 'site' : 'warehouse'];
    return nested is Map ? nested.cast<String, dynamic>() : null;
  }

  Future<void> _chooseReference() async {
    if (_loadingReferences) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReferencePickerSheet(
        title: 'Pilih $_relationName',
        rows: _references,
        selectedId: _relationId,
        codeKey: _referenceCodeKey,
        nameKey: _referenceNameKey,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _relationId = selected['id'].toString());
      _formKey.currentState?.validate();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      _codeKey: _code.text.trim().toUpperCase(),
      _nameKey: _name.text.trim(),
      _relationKey: _relationId,
      'status': _status,
    };
    try {
      if (_warehouse) {
        await MasterDataService.saveWarehouse(
          data,
          id: widget.record?['id']?.toString(),
        );
      } else {
        await MasterDataService.saveBin(
          data,
          id: widget.record?['id']?.toString(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFFB3261E),
          content: Text(
            error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedReference;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(0xFFCAD5C9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  widget.record == null ? 'Tambah $_entity' : 'Ubah $_entity',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _warehouse
                      ? 'Pilih site lalu lengkapi identitas gudang.'
                      : 'Pilih gudang lalu lengkapi identitas bin.',
                  style: TextStyle(color: Color(0xFF66756D)),
                ),
                SizedBox(height: 20),
                FormField<String>(
                  initialValue: _relationId,
                  validator: (_) => _relationId == null || _relationId!.isEmpty
                      ? '$_relationName wajib dipilih'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _referenceError == null
                            ? _chooseReference
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '$_relationName *',
                            prefixIcon: Icon(
                              _warehouse
                                  ? Icons.location_city_rounded
                                  : Icons.warehouse_rounded,
                            ),
                            suffixIcon: _loadingReferences
                                ? Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.search_rounded),
                            errorText: field.errorText,
                          ),
                          child: Text(
                            selected == null
                                ? 'Cari dan pilih $_relationName'
                                : _referenceLabel(selected),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected == null
                                  ? Color(0xFF66756D)
                                  : Color(0xFF183C32),
                              fontWeight: selected == null
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (_referenceError != null) ...[
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _referenceError!,
                                style: TextStyle(
                                  color: Color(0xFFB3261E),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadReferences,
                              child: Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kode $_entity *',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kode $_entity wajib diisi'
                      : null,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Nama $_entity *',
                    prefixIcon: Icon(
                      _warehouse
                          ? Icons.warehouse_rounded
                          : Icons.inventory_2_rounded,
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama $_entity wajib diisi'
                      : null,
                ),
                SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.toggle_on_rounded),
                  ),
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
                SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context, false),
                        child: Text('Batal'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _saving
                            ? SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferencePickerSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> rows;
  final String? selectedId;
  final String codeKey;
  final String nameKey;

  const _ReferencePickerSheet({
    required this.title,
    required this.rows,
    required this.selectedId,
    required this.codeKey,
    required this.nameKey,
  });

  @override
  State<_ReferencePickerSheet> createState() => _ReferencePickerSheetState();
}

class _ReferencePickerSheetState extends State<_ReferencePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase().trim();
    final rows = query.isEmpty
        ? widget.rows
        : widget.rows.where((row) {
            final value =
                '${row[widget.codeKey] ?? ''} ${row[widget.nameKey] ?? ''}'
                    .toLowerCase();
            return value.contains(query);
          }).toList();
    return DraggableScrollableSheet(
      initialChildSize: .72,
      minChildSize: .45,
      maxChildSize: .92,
      expand: false,
      builder: (_, controller) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFCAD5C9),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari dengan contains...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(child: Text('Data tidak ditemukan.'))
                  : ListView.separated(
                      controller: controller,
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => Divider(height: 1),
                      itemBuilder: (_, index) {
                        final row = rows[index];
                        final selected =
                            row['id']?.toString() == widget.selectedId;
                        return ListTile(
                          onTap: () => Navigator.pop(context, row),
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFFE8F3E4),
                            child: Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.location_on_outlined,
                              color: Color(0xFF1F7A2E),
                            ),
                          ),
                          title: Text(
                            row[widget.nameKey]?.toString() ?? '-',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${row[widget.codeKey] ?? '-'}  \u2022  ${row['status'] ?? '-'}',
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

class _LocationDetailSheet extends StatelessWidget {
  final _LocationKind kind;
  final Map<String, dynamic> record;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocationDetailSheet({
    required this.kind,
    required this.record,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _warehouse => kind == _LocationKind.warehouse;

  @override
  Widget build(BuildContext context) {
    final codeKey = _warehouse ? 'warehouse_code' : 'bin_code';
    final nameKey = _warehouse ? 'warehouse_name' : 'bin_name';
    final active = {
      'aktif',
      'active',
      '1',
    }.contains(record['status']?.toString().toLowerCase());
    final relation = record[_warehouse ? 'site' : 'warehouse'];
    final relationMap = relation is Map
        ? relation.cast<String, dynamic>()
        : <String, dynamic>{};
    final relationCode =
        relationMap[_warehouse ? 'site_code' : 'warehouse_code'];
    final relationName =
        relationMap[_warehouse ? 'site_name' : 'warehouse_name'];
    final bins = (record['bins'] as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
    final site = relationMap['site'];
    final siteMap = site is Map ? site.cast<String, dynamic>() : null;

    return DraggableScrollableSheet(
      initialChildSize: _warehouse ? .78 : .62,
      minChildSize: .42,
      maxChildSize: .94,
      expand: false,
      builder: (_, controller) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFCAD5C9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F1DF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _warehouse
                        ? Icons.warehouse_rounded
                        : Icons.inventory_2_rounded,
                    color: Color(0xFF1F7A2E),
                    size: 30,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record[nameKey]?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        record[codeKey]?.toString() ?? '-',
                        style: TextStyle(
                          color: Color(0xFFA66F00),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(active ? 'Aktif' : 'Nonaktif'),
                  backgroundColor: active
                      ? Color(0xFFE2F2DD)
                      : Color(0xFFFFE4DF),
                  side: BorderSide.none,
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFE3EAE0)),
              ),
              child: Row(
                children: [
                  Icon(
                    _warehouse
                        ? Icons.location_city_rounded
                        : Icons.warehouse_rounded,
                    color: Color(0xFF1F7A2E),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _warehouse ? 'Site' : 'Gudang',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF66756D),
                          ),
                        ),
                        Text(
                          relationMap.isEmpty
                              ? 'Belum dipilih'
                              : '${relationCode ?? '-'} - ${relationName ?? '-'}',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (!_warehouse && siteMap != null)
                          Text(
                            'Site: ${siteMap['site_code'] ?? '-'} - ${siteMap['site_name'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF66756D),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_warehouse) ...[
              SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'BIN DALAM GUDANG INI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                        color: Color(0xFF66756D),
                      ),
                    ),
                  ),
                  Text(
                    '${bins.length} bin',
                    style: TextStyle(
                      color: Color(0xFF1F7A2E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (bins.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Belum ada bin di gudang ini.'),
                )
              else
                for (final bin in bins)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFE8F3E4),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF1F7A2E),
                        size: 19,
                      ),
                    ),
                    title: Text(
                      bin['bin_name']?.toString() ?? '-',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${bin['bin_code'] ?? '-'}  \u2022  ${bin['status'] ?? '-'}',
                    ),
                  ),
            ],
            if (canUpdate || canDelete) ...[
              SizedBox(height: 24),
              Row(
                children: [
                  if (canDelete)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFFB3261E),
                        ),
                        icon: Icon(Icons.delete_outline_rounded),
                        label: Text('Hapus'),
                      ),
                    ),
                  if (canDelete && canUpdate) SizedBox(width: 12),
                  if (canUpdate)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Color(0xFF1F7A2E),
                        ),
                        icon: Icon(Icons.edit_rounded),
                        label: Text('Ubah'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFFE6ECE3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Color(0xFF66756D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
