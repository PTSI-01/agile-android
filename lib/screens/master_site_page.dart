import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';

class MasterSitePage extends StatefulWidget {
  const MasterSitePage({super.key});

  @override
  State<MasterSitePage> createState() => _MasterSitePageState();
}

class _MasterSitePageState extends State<MasterSitePage> {
  static const _green = Color(0xFF1F7A2E);
  static const _ink = Color(0xFF183C32);
  static const _gold = Color(0xFFE7AA19);

  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _sites = [];
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
      _user?.permissions['master_site.${action.toLowerCase()}'] == true;

  bool _active(Map<String, dynamic> site) {
    final value = site['status']?.toString().toLowerCase();
    return value == 'aktif' || value == 'active' || value == '1';
  }

  int _relationCount(Map<String, dynamic> site, String key) {
    final count = site['${key}_count'];
    if (count != null) return int.tryParse(count.toString()) ?? 0;
    return (site[key] as List?)?.length ?? 0;
  }

  List<Map<String, dynamic>> get _visibleSites {
    if (_status == 'semua') return _sites;
    final showActive = _status == 'aktif';
    return _sites.where((site) => _active(site) == showActive).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await MasterDataService.listSites(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _sites = rows);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 400), _load);
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

  Future<void> _openForm([Map<String, dynamic>? site]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SiteFormSheet(site: site),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus site?'),
        content: Text(
          '${site['site_code']} - ${site['site_name']} akan dihapus. Site yang masih dipakai gudang atau item tidak dapat dihapus.',
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
      await MasterDataService.deleteSite(site['id'].toString());
      if (!mounted) return;
      _notice('Site berhasil dihapus.');
      _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> initial) async {
    Map<String, dynamic> site = initial;
    try {
      site = await MasterDataService.getSite(initial['id'].toString());
    } catch (_) {
      // Data daftar sudah memuat relasi dan tetap dapat ditampilkan.
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SiteDetailSheet(
        site: site,
        canUpdate: _can('update'),
        canDelete: _can('delete'),
        onEdit: () {
          Navigator.pop(sheetContext);
          _openForm(site);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _delete(site);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalWarehouses = _sites.fold<int>(
      0,
      (total, site) => total + _relationCount(site, 'warehouses'),
    );
    final active = _sites.where(_active).length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Master Site',
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
              label: Text('Tambah Site'),
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
                hintText: 'Cari kode atau nama site...',
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
                    value: '${_sites.length}',
                    label: 'Site',
                    icon: Icons.location_city_rounded,
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
                    value: '$totalWarehouses',
                    label: 'Gudang',
                    icon: Icons.warehouse_rounded,
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
    final rows = _visibleSites;
    if (rows.isEmpty) {
      return Center(child: Text('Data site tidak ditemukan.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(18, 2, 18, 96),
        itemCount: rows.length,
        separatorBuilder: (_, _) => SizedBox(height: 10),
        itemBuilder: (_, index) {
          final site = rows[index];
          final warehouseCount = _relationCount(site, 'warehouses');
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDetail(site),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F3E4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.location_city_rounded,
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
                            site['site_name']?.toString() ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${site['site_code'] ?? '-'}  \u2022  $warehouseCount gudang',
                            style: TextStyle(
                              color: Color(0xFF66756D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _active(site)
                            ? Color(0xFFE4F4DF)
                            : Color(0xFFFFE5E1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _active(site) ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          color: _active(site) ? _green : Color(0xFFB3261E),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF829087)),
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

class _SiteFormSheet extends StatefulWidget {
  final Map<String, dynamic>? site;
  const _SiteFormSheet({this.site});

  @override
  State<_SiteFormSheet> createState() => _SiteFormSheetState();
}

class _SiteFormSheetState extends State<_SiteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(
      text: widget.site?['site_code']?.toString() ?? '',
    );
    _name = TextEditingController(
      text: widget.site?['site_name']?.toString() ?? '',
    );
    final status = widget.site?['status']?.toString().toLowerCase();
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
      await MasterDataService.saveSite({
        'site_code': _code.text.trim().toUpperCase(),
        'site_name': _name.text.trim(),
        'status': _status,
      }, id: widget.site?['id']?.toString());
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
                  widget.site == null ? 'Tambah Site' : 'Ubah Site',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Lengkapi kode, nama, dan status site.',
                  style: TextStyle(color: Color(0xFF66756D)),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kode site *',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kode site wajib diisi'
                      : null,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Nama site *',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama site wajib diisi'
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
                          backgroundColor: Color(0xFF1F7A2E),
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

class _SiteDetailSheet extends StatelessWidget {
  final Map<String, dynamic> site;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SiteDetailSheet({
    required this.site,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  List<Map<String, dynamic>> _rows(String key) => (site[key] as List? ?? [])
      .whereType<Map>()
      .map((row) => row.cast<String, dynamic>())
      .toList();

  @override
  Widget build(BuildContext context) {
    final warehouses = _rows('warehouses');
    final active = [
      'aktif',
      'active',
      '1',
    ].contains(site['status']?.toString().toLowerCase());
    return DraggableScrollableSheet(
      initialChildSize: .76,
      minChildSize: .45,
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
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F1DF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
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
                        site['site_name']?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        site['site_code']?.toString() ?? '-',
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
            SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _CountTile(
                    label: 'Jumlah gudang',
                    value: warehouses.length,
                    icon: Icons.warehouse_rounded,
                  ),
                ),
              ],
            ),
            if (warehouses.isNotEmpty) ...[
              SizedBox(height: 24),
              Text(
                'GUDANG DALAM SITE INI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                  color: Color(0xFF66756D),
                ),
              ),
              SizedBox(height: 8),
              for (final warehouse in warehouses)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFE8F3E4),
                    child: Icon(
                      Icons.warehouse_outlined,
                      color: Color(0xFF1F7A2E),
                      size: 19,
                    ),
                  ),
                  title: Text(
                    warehouse['warehouse_name']?.toString() ?? '-',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${warehouse['warehouse_code'] ?? '-'}  \u2022  ${warehouse['status'] ?? '-'}',
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE3EAE0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF1F7A2E)),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Color(0xFF66756D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
