import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';
import '../services/theme_service.dart';

class MasterItemPage extends StatefulWidget {
  const MasterItemPage({super.key});

  @override
  State<MasterItemPage> createState() => _MasterItemPageState();
}

class _MasterItemPageState extends State<MasterItemPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AuthService.refreshCurrentUser().then((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  bool _can(String action) {
    final permissions = _user?.permissions ?? <String, bool>{};
    return permissions['master_item.$action'] == true ||
        permissions['item.$action'] == true ||
        permissions['master_data.item.$action'] == true ||
        _user?.role?.toLowerCase() == 'superadmin';
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
      final rows = await MasterDataService.listItems(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _items = rows;
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

  String _field(Map<String, dynamic> item, List<String> names) {
    for (final name in names) {
      final value = item[name]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return '-';
  }

  bool _isActive(Map<String, dynamic> item) {
    final status = _field(item, ['status', 'status_item']).toLowerCase();
    return status == '1' || status == 'active' || status == 'aktif';
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MasterItemForm(item: item),
    );
    if (payload == null || !mounted) return;
    try {
      await MasterDataService.saveItem(payload, id: item?['id']?.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null
                ? 'Item berhasil ditambahkan.'
                : 'Item berhasil diperbarui.',
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

  Future<void> _openDetail(Map<String, dynamic> item) async {
    try {
      final detail = await MasterDataService.getItem(item['id'].toString());
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _MasterItemDetailSheet(
          item: detail,
          canUpdate: _can('update'),
          onEdit: () {
            Navigator.pop(context);
            _openForm(detail);
          },
        ),
      );
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

  Future<void> _delete(Map<String, dynamic> item) async {
    final name = _field(item, ['nama_item', 'name']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus item?'),
        content: Text('Data "$name" akan dihapus permanen.'),
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
      await MasterDataService.deleteItem(item['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item berhasil dihapus.'),
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
    final activeCount = _items.where(_isActive).length;
    final inactiveCount = _items.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Master Data Item',
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
              icon: Icon(Icons.add_box_rounded),
              label: Text(
                'Tambah Item',
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
                    'Total Item',
                    '${_items.length}',
                    Color(0xFF1E88E5),
                    Color(0xFFE3F2FD),
                  ),
                  SizedBox(width: 10),
                  _statItem('Aktif', '$activeCount', green, Color(0xFFE8F5E9)),
                  SizedBox(width: 10),
                  _statItem(
                    'Nonaktif',
                    '$inactiveCount',
                    Color(0xFFD84315),
                    Color(0xFFFBE9E7),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari nama, kode, atau kategori item...',
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

  Widget _statItem(String label, String value, Color color, Color background) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAF6),
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFD14942)),
              ),
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
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: 150),
            Icon(
              Icons.inventory_2_outlined,
              size: 52,
              color: Color(0xFF9AA49F),
            ),
            SizedBox(height: 12),
            Center(child: Text('Belum ada data item')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: green,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 90),
        itemCount: _items.length,
        separatorBuilder: (_, _) => SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = _items[index];
          final code = _field(item, ['kode_item', 'item_code', 'code']);
          final name = _field(item, ['nama_item', 'item_name', 'name']);
          final category = _field(item, [
            'kategori_item',
            'jenis_item',
            'category_name',
          ]);
          final active = _isActive(item);
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDetail(item),
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
                      child: Text(
                        name == '-' || name.isEmpty
                            ? 'I'
                            : name.characters.first.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
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
                                  code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
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
                          SizedBox(height: 5),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          if (value == 'edit') _openForm(item);
                          if (value == 'delete') _delete(item);
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

class _MasterItemDetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool canUpdate;
  final VoidCallback onEdit;

  const _MasterItemDetailSheet({
    required this.item,
    required this.canUpdate,
    required this.onEdit,
  });

  String _value(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? '-' : text;
  }

  String _nested(String relation, String field) {
    final value = item[relation];
    return value is Map ? _value(value[field]) : '-';
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F7A2E);
    final active = [
      'aktif',
      'active',
      '1',
      'true',
    ].contains(_value(item['status']).toLowerCase());
    final itemSites = (item['item_sites'] as List? ?? [])
        .whereType<Map>()
        .map((value) => value.cast<String, dynamic>())
        .toList();
    final detailValues = item['detail_values'] is Map
        ? (item['detail_values'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    return DraggableScrollableSheet(
      initialChildSize: .86,
      minChildSize: .55,
      maxChildSize: .96,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Color(0xFFF8FAF6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFFE5F2E4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.inventory_2_rounded, color: green),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _value(item['nama_item']),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _value(item['kode_item']),
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(
                        active ? 'AKTIF' : 'NONAKTIF',
                        active ? green : Colors.red.shade700,
                      ),
                      _badge(
                        _nested('category', 'category_name'),
                        Color(0xFFA66F00),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  _section('Informasi Item', Icons.info_outline_rounded, [
                    _row('Barcode', _value(item['barcode'])),
                    _row('Satuan', _nested('unit', 'nama_satuan')),
                    _row(
                      'Buyer Group',
                      _nested('purchasing_group', 'group_name'),
                    ),
                    _row('Kategori', _nested('category', 'category_name')),
                    if (!active)
                      _row('Tanggal Nonaktif', _value(item['inactive_date'])),
                    if (!active)
                      _row('Alasan Nonaktif', _value(item['inactive_reason'])),
                  ]),
                  if (detailValues.isNotEmpty) ...[
                    SizedBox(height: 12),
                    _section(
                      'Detail Berdasarkan Kategori',
                      Icons.tune_rounded,
                      detailValues.entries
                          .map(
                            (entry) => _row(
                              _detailLabel(entry.key),
                              _detailValue(entry.value),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  SizedBox(height: 12),
                  _section(
                    'Site dan Gudang',
                    Icons.warehouse_rounded,
                    itemSites.isEmpty
                        ? [Text('Belum ada site yang terhubung.')]
                        : itemSites.map(_site).toList(),
                  ),
                  SizedBox(height: 12),
                  _section('Pricelist', Icons.sell_outlined, [
                    _row(
                      'Jumlah pricelist',
                      '${(item['price_lists'] as List? ?? []).length} data',
                    ),
                  ]),
                ],
              ),
            ),
            if (canUpdate)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_rounded),
                      label: Text('Ubah Item'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _site(Map<String, dynamic> itemSite) {
    final site = itemSite['site'];
    final siteLabel = site is Map
        ? '${_value(site['site_code'])} - ${_value(site['site_name'])}'
        : _value(itemSite['site_id']);
    final relations = (itemSite['warehouses'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final warehouseLabels = relations
        .map((relation) {
          final warehouse = relation['warehouse'];
          final label = warehouse is Map
              ? '${_value(warehouse['warehouse_code'])} - ${_value(warehouse['warehouse_name'])}'
              : _value(relation['warehouse_id']);
          return relation['is_default'] == true || relation['is_default'] == 1
              ? '$label (Default)'
              : label;
        })
        .join(', ');
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(siteLabel, style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 3),
          Text(warehouseLabels.isEmpty ? 'Belum ada gudang' : warehouseLabels),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ThemeService.isDark ? Color(0xFF14271F) : Color(0xFFF8FAF6),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Color(0xFFE0E8DC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: Color(0xFF1F7A2E)),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            Divider(height: 22),
            ...children,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(label, style: TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  String _detailLabel(String key) =>
      {
        'origin_area': 'Area Asal',
        'destination_area': 'Area Tujuan',
        'vehicle_type': 'Tipe Kendaraan',
        'capacity_kg': 'Kapasitas (KG)',
        'tonase_kg': 'Tonase (KG)',
        'service_type': 'Jenis Layanan',
        'specification': 'Spesifikasi',
        'grade': 'Grade',
        'color': 'Warna',
        'size': 'Ukuran',
        'detail_note': 'Catatan Detail',
      }[key] ??
      key;

  String _detailValue(dynamic value) {
    if (value is Map) {
      return value.values
          .map((entry) => _value(entry))
          .where((entry) => entry != '-')
          .join(' / ');
    }
    return _value(value);
  }
}

class _MasterItemForm extends StatefulWidget {
  final Map<String, dynamic>? item;

  const _MasterItemForm({this.item});

  @override
  State<_MasterItemForm> createState() => _MasterItemFormState();
}

class _MasterItemFormState extends State<_MasterItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _inactiveDateController;
  late final TextEditingController _inactiveReasonController;
  final Map<String, TextEditingController> _detailControllers = {};
  final Map<String, Map<String, TextEditingController>> _locationControllers =
      {};
  final Set<String> _selectedSiteIds = {};
  final Map<String, Set<String>> _selectedWarehouseIds = {};
  final Map<String, String?> _defaultWarehouseIds = {};
  Map<String, dynamic>? _references;
  String? _categoryId;
  String? _unitId;
  String? _purchasingGroupId;
  String _status = 'aktif';
  bool _loadingReferences = true;
  String? _referencesError;

  bool get _isEdit => widget.item != null;

  String _initialValue(List<String> keys) {
    for (final key in keys) {
      final value = widget.item?[key]?.toString();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: _initialValue(['kode_item', 'item_code', 'code']),
    );
    _nameController = TextEditingController(
      text: _initialValue(['nama_item', 'item_name', 'name']),
    );
    _barcodeController = TextEditingController(
      text: _initialValue(['barcode']),
    );
    final rawInactiveDate = _initialValue(['inactive_date']);
    final parsedInactiveDate = DateTime.tryParse(rawInactiveDate);
    _inactiveDateController = TextEditingController(
      text: parsedInactiveDate == null
          ? rawInactiveDate
          : '${parsedInactiveDate.year.toString().padLeft(4, '0')}-${parsedInactiveDate.month.toString().padLeft(2, '0')}-${parsedInactiveDate.day.toString().padLeft(2, '0')}',
    );
    _inactiveReasonController = TextEditingController(
      text: _initialValue(['inactive_reason']),
    );
    _categoryId = _initialValue(['item_category_id']);
    _unitId = _initialValue(['satuan_id']);
    _purchasingGroupId = _initialValue(['purchasing_group_id']);
    _status = _initialValue(['status']).toLowerCase() == 'nonaktif'
        ? 'nonaktif'
        : 'aktif';
    final detailValues = widget.item?['detail_values'];
    if (detailValues is Map) {
      for (final entry in detailValues.entries) {
        if (entry.value is Map) {
          final location = (entry.value as Map).cast<String, dynamic>();
          _locationControllers[entry.key.toString()] = {
            for (final key in ['province', 'city', 'district'])
              key: TextEditingController(text: location[key]?.toString() ?? ''),
          };
        } else {
          _detailControllers[entry.key.toString()] = TextEditingController(
            text: entry.value?.toString() ?? '',
          );
        }
      }
    }
    final itemSites = widget.item?['item_sites'];
    if (itemSites is List) {
      for (final rawSite in itemSites.whereType<Map>()) {
        final site = rawSite.cast<String, dynamic>();
        final siteId = site['site_id']?.toString();
        if (siteId == null) continue;
        _selectedSiteIds.add(siteId);
        _defaultWarehouseIds[siteId] = site['default_warehouse_id']?.toString();
        final relations = site['warehouses'];
        _selectedWarehouseIds[siteId] = relations is List
            ? relations
                  .whereType<Map>()
                  .map((relation) => relation['warehouse_id']?.toString())
                  .whereType<String>()
                  .toSet()
            : <String>{};
      }
    }
    _loadReferences();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();
    _inactiveDateController.dispose();
    _inactiveReasonController.dispose();
    for (final controller in _detailControllers.values) {
      controller.dispose();
    }
    for (final group in _locationControllers.values) {
      for (final controller in group.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadReferences() async {
    try {
      final data = await MasterDataService.itemReferences(
        itemId: widget.item?['id']?.toString(),
      );
      if (!mounted) return;
      setState(() {
        _references = data;
        _loadingReferences = false;
      });
      final groups = _rows('purchasing_groups');
      if (_purchasingGroupId == null && groups.length == 1) {
        setState(() => _purchasingGroupId = groups.first['id']?.toString());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _referencesError = error.toString().replaceFirst('Exception: ', '');
        _loadingReferences = false;
      });
    }
  }

  List<Map<String, dynamic>> _rows(String key) {
    final rows = _references?[key];
    return rows is List
        ? rows
              .whereType<Map>()
              .map((row) => row.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? get _selectedCategory {
    for (final category in _rows('categories')) {
      if (category['id']?.toString() == _categoryId) return category;
    }
    return null;
  }

  List<String> get _enabledDetailFields =>
      (_selectedCategory?['enabled_fields'] as List? ?? [])
          .map((field) => field.toString())
          .toList();

  TextEditingController _detailController(String field) =>
      _detailControllers.putIfAbsent(field, () => TextEditingController());

  Map<String, TextEditingController> _locationController(String field) =>
      _locationControllers.putIfAbsent(
        field,
        () => {
          for (final key in ['province', 'city', 'district'])
            key: TextEditingController(),
        },
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih minimal satu site untuk item ini.')),
      );
      return;
    }
    for (final siteId in _selectedSiteIds) {
      if ((_selectedWarehouseIds[siteId] ?? {}).isEmpty ||
          _defaultWarehouseIds[siteId] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pilih warehouse dan default gudang untuk setiap site.',
            ),
          ),
        );
        return;
      }
    }
    final detailValues = <String, dynamic>{};
    for (final field in _enabledDetailFields) {
      if (field == 'origin_area' || field == 'destination_area') {
        final controllers = _locationController(field);
        detailValues[field] = {
          for (final key in ['province', 'city', 'district'])
            key: controllers[key]!.text.trim(),
        };
      } else {
        detailValues[field] = _detailController(field).text.trim();
      }
    }
    Navigator.pop(context, {
      'kode_item': _codeController.text.trim(),
      'nama_item': _nameController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'purchasing_group_id': _purchasingGroupId,
      'item_category_id': _categoryId,
      'satuan_id': _unitId,
      'status': _status,
      'inactive_date': _status == 'nonaktif'
          ? _inactiveDateController.text
          : null,
      'inactive_reason': _status == 'nonaktif'
          ? _inactiveReasonController.text.trim()
          : null,
      'detail_values': detailValues,
      'site_ids': _selectedSiteIds.toList(),
      'warehouse_ids': {
        for (final siteId in _selectedSiteIds)
          siteId: (_selectedWarehouseIds[siteId] ?? {}).toList(),
      },
      'default_warehouse_ids': {
        for (final siteId in _selectedSiteIds)
          siteId: _defaultWarehouseIds[siteId],
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingReferences) {
      return AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_referencesError != null) {
      return AlertDialog(
        title: Text('Referensi item gagal dimuat'),
        content: Text(_referencesError!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          FilledButton(
            onPressed: () => setState(() {
              _loadingReferences = true;
              _referencesError = null;
              _loadReferences();
            }),
            child: Text('Coba Lagi'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Item' : 'Tambah Item'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(labelText: 'Kode Item'),
                  validator: _required,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nama Item'),
                  validator: _required,
                ),
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(labelText: 'Barcode'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _dropdownValue(
                    _categoryId,
                    _rows('categories'),
                  ),
                  decoration: InputDecoration(labelText: 'Kategori Item'),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Tanpa kategori'),
                    ),
                    ..._rows('categories').map(
                      (row) => DropdownMenuItem(
                        value: row['id'].toString(),
                        child: Text(
                          '${row['category_code']} - ${row['category_name']}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _dropdownValue(_unitId, _rows('units')),
                  decoration: InputDecoration(labelText: 'Satuan'),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Tanpa satuan')),
                    ..._rows('units').map(
                      (row) => DropdownMenuItem(
                        value: row['id'].toString(),
                        child: Text(
                          '${row['kode_satuan']} - ${row['nama_satuan']}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _unitId = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _dropdownValue(
                    _purchasingGroupId,
                    _rows('purchasing_groups'),
                  ),
                  decoration: InputDecoration(labelText: 'Buyer Group'),
                  validator: (value) =>
                      value == null ? 'Buyer Group wajib dipilih' : null,
                  items: _rows('purchasing_groups')
                      .map(
                        (row) => DropdownMenuItem(
                          value: row['id'].toString(),
                          child: Text(
                            '${row['group_code']} - ${row['group_name']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _purchasingGroupId = value),
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
                if (_status == 'nonaktif') ...[
                  TextFormField(
                    controller: _inactiveDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Nonaktif',
                      suffixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    validator: _required,
                    onTap: _selectInactiveDate,
                  ),
                  TextFormField(
                    controller: _inactiveReasonController,
                    decoration: InputDecoration(labelText: 'Alasan Nonaktif'),
                    maxLines: 2,
                    validator: _required,
                  ),
                ],
                ..._buildDetailFields(),
                SizedBox(height: 16),
                Text(
                  'Site, Warehouse, dan Default Gudang',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                ..._buildSiteFields(),
                SizedBox(height: 8),
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

  String? _dropdownValue(String? value, List<Map<String, dynamic>> rows) =>
      rows.any((row) => row['id']?.toString() == value) ? value : null;

  Future<void> _selectInactiveDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_inactiveDateController.text) ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (date != null) {
      _inactiveDateController.text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  List<Widget> _buildDetailFields() {
    const labels = {
      'origin_area': 'Area Asal',
      'destination_area': 'Area Tujuan',
      'vehicle_type': 'Tipe Kendaraan',
      'capacity_kg': 'Kapasitas (KG)',
      'tonase_kg': 'Tonase (KG)',
      'service_type': 'Jenis Layanan',
      'specification': 'Spesifikasi',
      'grade': 'Grade',
      'color': 'Warna',
      'size': 'Ukuran',
      'detail_note': 'Catatan Detail',
    };
    return [
      for (final field in _enabledDetailFields)
        if (labels.containsKey(field)) ...[
          SizedBox(height: 8),
          if (field == 'origin_area' || field == 'destination_area')
            ..._buildLocationFields(field, labels[field]!)
          else
            TextFormField(
              controller: _detailController(field),
              decoration: InputDecoration(labelText: labels[field]),
              keyboardType: ['capacity_kg', 'tonase_kg'].contains(field)
                  ? TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              maxLines: field == 'detail_note' ? 2 : 1,
              validator: _required,
            ),
        ],
    ];
  }

  List<Widget> _buildLocationFields(String field, String label) {
    final controllers = _locationController(field);
    return [
      Text(label, style: TextStyle(fontWeight: FontWeight.w700)),
      for (final entry in [
        ('province', 'Provinsi'),
        ('city', 'Kabupaten/Kota'),
        ('district', 'Kecamatan'),
      ])
        TextFormField(
          controller: controllers[entry.$1],
          decoration: InputDecoration(labelText: entry.$2),
          validator: _required,
        ),
    ];
  }

  List<Widget> _buildSiteFields() {
    final sites = _rows('sites');
    if (sites.isEmpty) {
      return [Text('Belum ada site aktif untuk dipilih.')];
    }
    return sites.map((site) {
      final siteId = site['id'].toString();
      final warehouses = (site['warehouses'] as List? ?? [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
      final selected = _selectedSiteIds.contains(siteId);
      final selectedWarehouses = _selectedWarehouseIds[siteId] ?? <String>{};
      final defaultWarehouse = _defaultWarehouseIds[siteId];
      return Card(
        margin: EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${site['site_code']} - ${site['site_name']}'),
                value: selected,
                onChanged: (value) => setState(() {
                  if (value == true) {
                    _selectedSiteIds.add(siteId);
                    _selectedWarehouseIds.putIfAbsent(siteId, () => {});
                  } else {
                    _selectedSiteIds.remove(siteId);
                    _selectedWarehouseIds.remove(siteId);
                    _defaultWarehouseIds.remove(siteId);
                  }
                }),
              ),
              if (selected) ...[
                for (final warehouse in warehouses)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.only(left: 12),
                    title: Text(
                      '${warehouse['warehouse_code']} - ${warehouse['warehouse_name']}',
                    ),
                    value: selectedWarehouses.contains(
                      warehouse['id'].toString(),
                    ),
                    onChanged: (value) => setState(() {
                      final warehouseId = warehouse['id'].toString();
                      if (value == true) {
                        selectedWarehouses.add(warehouseId);
                      } else {
                        selectedWarehouses.remove(warehouseId);
                        if (_defaultWarehouseIds[siteId] == warehouseId) {
                          _defaultWarehouseIds[siteId] = null;
                        }
                      }
                    }),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: selectedWarehouses.contains(defaultWarehouse)
                      ? defaultWarehouse
                      : null,
                  decoration: InputDecoration(labelText: 'Default Gudang'),
                  items: warehouses
                      .where(
                        (row) =>
                            selectedWarehouses.contains(row['id'].toString()),
                      )
                      .map(
                        (row) => DropdownMenuItem(
                          value: row['id'].toString(),
                          child: Text(
                            '${row['warehouse_code']} - ${row['warehouse_name']}',
                          ),
                        ),
                      )
                      .toList(),
                  validator: (_) => null,
                  onChanged: (value) =>
                      setState(() => _defaultWarehouseIds[siteId] = value),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}
