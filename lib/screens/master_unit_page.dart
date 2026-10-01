import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';

class MasterUnitPage extends StatefulWidget {
  const MasterUnitPage({super.key});

  @override
  State<MasterUnitPage> createState() => _MasterUnitPageState();
}

class _MasterUnitPageState extends State<MasterUnitPage> {
  static const _green = Color(0xFF1F7A2E);
  static const _ink = Color(0xFF183C32);
  static const _gold = Color(0xFFE7AA19);

  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _units = [];
  UserModel? _user;
  String _status = 'semua';
  String? _error;
  bool _loading = true;

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
      _user?.permissions['master_unit.${action.toLowerCase()}'] == true;

  bool _active(Map<String, dynamic> unit) {
    final value = unit['status']?.toString().toLowerCase();
    return value == 'aktif' || value == 'active' || value == '1';
  }

  int _relationCount(Map<String, dynamic> unit, String key) {
    final count = unit['${key}_count'];
    if (count != null) return int.tryParse(count.toString()) ?? 0;
    return (unit[key] as List?)?.length ?? 0;
  }

  List<Map<String, dynamic>> get _visibleUnits {
    if (_status == 'semua') return _units;
    final showActive = _status == 'aktif';
    return _units.where((unit) => _active(unit) == showActive).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await MasterDataService.listUnits(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _units = rows);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB3261E) : _green,
      ),
    );
  }

  Future<void> _openForm([Map<String, dynamic>? unit]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitFormSheet(unit: unit),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus satuan?'),
        content: Text(
          '${unit['kode_satuan']} - ${unit['nama_satuan']} akan dihapus. Satuan yang masih dipakai item atau konversi tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await MasterDataService.deleteUnit(unit['id'].toString());
      if (!mounted) return;
      _notice('Satuan berhasil dihapus.');
      _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> initial) async {
    Map<String, dynamic> unit = initial;
    try {
      unit = await MasterDataService.getUnit(initial['id'].toString());
    } catch (_) {
      // Data daftar sudah memuat relasi dan tetap dapat ditampilkan.
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _UnitDetailSheet(
        unit: unit,
        canUpdate: _can('update'),
        canDelete: _can('delete'),
        onEdit: () {
          Navigator.pop(sheetContext);
          _openForm(unit);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _delete(unit);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _units.fold<int>(
      0,
      (total, unit) => total + _relationCount(unit, 'items'),
    );
    final active = _units.where(_active).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF4),
      appBar: AppBar(
        title: const Text(
          'Master Satuan',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _can('create')
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Satuan'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari kode atau nama satuan...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFD9E3D7)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    value: '${_units.length}',
                    label: 'Satuan',
                    icon: Icons.straighten_rounded,
                    color: _green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    value: '$active',
                    label: 'Aktif',
                    icon: Icons.check_circle_rounded,
                    color: _gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    value: '$totalItems',
                    label: 'Item',
                    icon: Icons.inventory_2_rounded,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final option in const [
                  ('semua', 'Semua'),
                  ('aktif', 'Aktif'),
                  ('nonaktif', 'Nonaktif'),
                ]) ...[
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: _status == option.$1,
                    onSelected: (_) => setState(() => _status = option.$1),
                    selectedColor: const Color(0xFFDCEED7),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _status == option.$1 ? _green : _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 42, color: _green),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final rows = _visibleUnits;
    if (rows.isEmpty) {
      return const Center(child: Text('Data satuan tidak ditemukan.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 96),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final unit = rows[index];
          final itemCount = _relationCount(unit, 'items');
          final conversionCount =
              _relationCount(unit, 'conversions_from') +
              _relationCount(unit, 'conversions_to');
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDetail(unit),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3E4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        unit['kode_satuan']?.toString() ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit['nama_satuan']?.toString() ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$itemCount item  •  $conversionCount konversi',
                            style: const TextStyle(
                              color: Color(0xFF66756D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _active(unit)
                            ? const Color(0xFFE4F4DF)
                            : const Color(0xFFFFE5E1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _active(unit) ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          color: _active(unit)
                              ? _green
                              : const Color(0xFFB3261E),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF829087),
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE6ECE3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF66756D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitFormSheet extends StatefulWidget {
  final Map<String, dynamic>? unit;
  const _UnitFormSheet({this.unit});

  @override
  State<_UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends State<_UnitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(
      text: widget.unit?['kode_satuan']?.toString() ?? '',
    );
    _name = TextEditingController(
      text: widget.unit?['nama_satuan']?.toString() ?? '',
    );
    final status = widget.unit?['status']?.toString().toLowerCase();
    _status = status == 'nonaktif' || status == 'inactive' || status == '0'
        ? 'nonaktif'
        : 'aktif';
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await MasterDataService.saveUnit({
        'kode_satuan': _code.text.trim().toUpperCase(),
        'nama_satuan': _name.text.trim(),
        'status': _status,
      }, id: widget.unit?['id']?.toString());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB3261E),
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: const Color(0xFFF8FBF5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
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
                      color: const Color(0xFFCAD5C9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.unit == null ? 'Tambah Satuan' : 'Ubah Satuan',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF183C32),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Lengkapi kode, nama, dan status satuan.',
                  style: TextStyle(color: Color(0xFF66756D)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode satuan *',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kode satuan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nama satuan *',
                    prefixIcon: Icon(Icons.straighten_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama satuan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.toggle_on_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'nonaktif',
                      child: Text('Nonaktif'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'aktif'),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A2E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
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

class _UnitDetailSheet extends StatelessWidget {
  final Map<String, dynamic> unit;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitDetailSheet({
    required this.unit,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  List<Map<String, dynamic>> _rows(String key) => (unit[key] as List? ?? [])
      .whereType<Map>()
      .map((row) => row.cast<String, dynamic>())
      .toList();

  @override
  Widget build(BuildContext context) {
    final items = _rows('items');
    final from = _rows('conversions_from');
    final to = _rows('conversions_to');
    final active = [
      'aktif',
      'active',
      '1',
    ].contains(unit['status']?.toString().toLowerCase());
    return DraggableScrollableSheet(
      initialChildSize: .76,
      minChildSize: .45,
      maxChildSize: .94,
      expand: false,
      builder: (_, controller) => Material(
        color: const Color(0xFFF8FBF5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCAD5C9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F1DF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.straighten_rounded,
                    color: Color(0xFF1F7A2E),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit['nama_satuan']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF183C32),
                        ),
                      ),
                      Text(
                        unit['kode_satuan']?.toString() ?? '-',
                        style: const TextStyle(
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
                      ? const Color(0xFFE2F2DD)
                      : const Color(0xFFFFE4DF),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _CountTile(
                    label: 'Dipakai item',
                    value: items.length,
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountTile(
                    label: 'Konversi',
                    value: from.length + to.length,
                    icon: Icons.swap_horiz_rounded,
                  ),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'ITEM DENGAN SATUAN INI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                  color: Color(0xFF66756D),
                ),
              ),
              const SizedBox(height: 8),
              for (final item in items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F3E4),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF1F7A2E),
                      size: 19,
                    ),
                  ),
                  title: Text(
                    item['nama_item']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(item['kode_item']?.toString() ?? '-'),
                ),
            ],
            if (from.isNotEmpty || to.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'KONVERSI SATUAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                  color: Color(0xFF66756D),
                ),
              ),
              const SizedBox(height: 8),
              for (final conversion in [...from, ...to])
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Color(0xFFA66F00),
                  ),
                  title: Text(
                    'Nilai konversi: ${conversion['conversion_value'] ?? '-'}',
                  ),
                  subtitle: Text(conversion['status']?.toString() ?? '-'),
                ),
            ],
            if (canUpdate || canDelete) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  if (canDelete)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB3261E),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus'),
                      ),
                    ),
                  if (canDelete && canUpdate) const SizedBox(width: 12),
                  if (canUpdate)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A2E),
                        ),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Ubah'),
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

class _CountTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _CountTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAE0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1F7A2E)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF66756D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
