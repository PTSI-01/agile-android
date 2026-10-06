import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/bongkaran_service.dart';

class BongkaranPage extends StatefulWidget {
  const BongkaranPage({super.key});

  @override
  State<BongkaranPage> createState() => _BongkaranPageState();
}

class _BongkaranPageState extends State<BongkaranPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _ready = [];
  List<Map<String, dynamic>> _history = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;
  int _tab = 0;

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
    _searchController.dispose();
    super.dispose();
  }

  bool _can(String action) =>
      _user?.role?.toLowerCase() == 'superadmin' ||
      _user?.permissions['bongkaran.$action'] == true;

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').contains(
        'SQLSTATE',
      )
      ? 'Data Bongkaran belum dapat dimuat karena API server belum diperbarui.'
      : error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  String _value(Map<String, dynamic> row, String key, [String fallback = '-']) {
    final value = row[key]?.toString().trim();
    return value == null || value.isEmpty || value == 'null' ? fallback : value;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await BongkaranService.list(
        search: _searchController.text,
      );
      Map<String, dynamic>? references;
      Object? referenceError;
      try {
        references = await BongkaranService.references();
      } catch (error) {
        referenceError = error;
      }
      if (!mounted) return;
      setState(() {
        _ready = (references?['ready_receptions'] as List? ?? [])
            .whereType<Map>()
            .map((row) => row.cast<String, dynamic>())
            .toList();
        _history = history;
        _error = referenceError == null ? null : _message(referenceError);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleReady {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _ready;
    return _ready.where((reception) {
      final buyer = _map(reception['buyer']);
      final searchable = [
        reception['legal_number'],
        reception['buyer_code'],
        reception['nopol'],
        buyer['nama_supplier'],
        buyer['nama_sourching'],
        buyer['nama_item'],
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Future<void> _openForm({
    Map<String, dynamic>? reception,
    Map<String, dynamic>? bongkaran,
  }) async {
    try {
      final references = await BongkaranService.references(
        bongkaranId: bongkaran?['id']?.toString(),
      );
      if (!mounted) return;
      final payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _BongkaranForm(
          reception: reception,
          bongkaran: bongkaran,
          references: references,
        ),
      );
      if (payload == null || !mounted) return;
      await BongkaranService.save(payload, id: bongkaran?['id']?.toString());
      if (!mounted) return;
      _notice(
        bongkaran == null
            ? 'Data bongkaran berhasil disimpan.'
            : 'Data bongkaran berhasil diperbarui.',
      );
      await _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> bongkaran) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan data bongkaran?'),
        content: Text(
          'Penerimaan akan dikembalikan ke status siap bongkar. Bongkaran yang sudah dipakai proses Lab tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFD14942)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await BongkaranService.delete(bongkaran['id'].toString());
      if (!mounted) return;
      _notice('Bongkaran dibatalkan; penerimaan siap diproses kembali.');
      await _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Color(0xFFD14942) : Color(0xFF1F7A2E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manajemen Bongkaran',
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  _stat('Siap Bongkar', '${_ready.length}', green),
                  SizedBox(width: 10),
                  _stat('Riwayat', '${_history.length}', Color(0xFF1E88E5)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari kode, supplier, item, atau nopol...',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text('Siap Dibongkar')),
                  ButtonSegment(value: 1, label: Text('Riwayat')),
                ],
                selected: {_tab},
                onSelectionChanged: (selection) =>
                    setState(() => _tab = selection.first),
              ),
            ),
            SizedBox(height: 8),
            Expanded(child: _buildBody(ink, green)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE9EDE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF7D8983))),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildBody(Color ink, Color green) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null && _tab == 0) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 12),
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
    final rows = _tab == 0 ? _visibleReady : _history;
    if (rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: 150),
            Icon(
              _tab == 0 ? Icons.local_shipping_outlined : Icons.history_rounded,
              size: 52,
              color: Color(0xFF9AA49F),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                _tab == 0
                    ? 'Belum ada penerimaan siap bongkar'
                    : 'Belum ada riwayat bongkaran',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: green,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: rows.length,
        separatorBuilder: (_, _) => SizedBox(height: 10),
        itemBuilder: (_, index) => _tab == 0
            ? _readyCard(rows[index], ink, green)
            : _historyCard(rows[index], ink, green),
      ),
    );
  }

  Widget _readyCard(Map<String, dynamic> reception, Color ink, Color green) {
    final buyer = _map(reception['buyer']);
    final details = buyer['buyer_detail'] as List? ?? [];
    final itemName = details.isNotEmpty
        ? details
              .whereType<Map>()
              .map((detail) => detail['nama_item'])
              .whereType<String>()
              .join(', ')
        : _value(buyer, 'nama_item');
    return _card(
      ink: ink,
      icon: Icons.local_shipping_rounded,
      title: _value(reception, 'legal_number'),
      status: 'Siap Bongkar',
      statusColor: green,
      children: [
        _info('Buyer', _value(reception, 'buyer_code')),
        _info('Supplier', _value(buyer, 'nama_supplier')),
        _info('Item', itemName),
        _info('Nopol', _value(reception, 'nopol')),
      ],
      actions: [
        if (_can('create'))
          FilledButton.icon(
            onPressed: () => _openForm(reception: reception),
            icon: Icon(Icons.playlist_add_check_rounded),
            label: Text('Input Bongkaran'),
          ),
      ],
    );
  }

  Widget _historyCard(Map<String, dynamic> row, Color ink, Color green) {
    final buyer = _map(row['buyer']);
    final site = _map(row['lokasi_site']);
    final warehouse = _map(row['lokasi_gudang']);
    final bin = _map(row['lokasi_bin']);
    final surveyor = _map(row['surveyor']);
    final active = row['status_bongkar'].toString() == '1';
    return _card(
      ink: ink,
      icon: Icons.assignment_turned_in_rounded,
      title: _value(row, 'legal_number'),
      status: active ? 'Selesai' : 'Proses',
      statusColor: active ? green : Color(0xFFA66F00),
      onTap: _can('update') ? () => _openForm(bongkaran: row) : null,
      children: [
        _info('Buyer', _value(row, 'buyer_code')),
        _info('No DTM', _value(row, 'no_dtm')),
        _info('Supplier', _value(buyer, 'nama_supplier')),
        _info('Surveyor', _value(surveyor, 'nama_surveyor')),
        _info(
          'Lokasi',
          '${_value(site, 'site_name')} / ${_value(warehouse, 'warehouse_name')} / ${_value(bin, 'bin_name')}',
        ),
        _info(
          'Z dibawa / ditolak',
          '${_value(row, 'z_dibawa')} / ${_value(row, 'z_ditolak')}',
        ),
      ],
      actions: [
        if (_can('update'))
          OutlinedButton.icon(
            onPressed: () => _openForm(bongkaran: row),
            icon: Icon(Icons.edit_outlined),
            label: Text('Edit'),
          ),
        if (_can('delete'))
          OutlinedButton.icon(
            onPressed: () => _delete(row),
            style: OutlinedButton.styleFrom(foregroundColor: Color(0xFFD14942)),
            icon: Icon(Icons.delete_outline_rounded),
            label: Text('Batalkan'),
          ),
      ],
    );
  }

  Widget _card({
    required Color ink,
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
    required List<Widget> children,
    required List<Widget> actions,
    VoidCallback? onTap,
  }) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color(0xFFE9EDE5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFE3EBD9),
                  child: Icon(icon, color: ink),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                _statusChip(status, statusColor),
              ],
            ),
            SizedBox(height: 12),
            ...children,
            if (actions.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _info(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Color(0xFF7D8983)),
          ),
        ),
        Text(': ', style: TextStyle(fontSize: 11, color: Color(0xFF7D8983))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _statusChip(String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

class _BongkaranForm extends StatefulWidget {
  final Map<String, dynamic>? reception;
  final Map<String, dynamic>? bongkaran;
  final Map<String, dynamic> references;

  const _BongkaranForm({
    required this.references,
    this.reception,
    this.bongkaran,
  });

  @override
  State<_BongkaranForm> createState() => _BongkaranFormState();
}

class _BongkaranFormState extends State<_BongkaranForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dtmController;
  late final TextEditingController _carriedController;
  late final TextEditingController _rejectedController;
  late final TextEditingController _noteController;
  late String? _surveyorId;
  late String? _siteId;
  late String? _warehouseId;
  late String? _binId;
  late String? _unloadTime;

  bool get _isEdit => widget.bongkaran != null;

  List<Map<String, dynamic>> _list(String key) =>
      (widget.references[key] as List? ?? [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    final row = widget.bongkaran ?? <String, dynamic>{};
    _dtmController = TextEditingController(
      text: row['no_dtm']?.toString() ?? '',
    );
    _carriedController = TextEditingController(
      text: row['z_dibawa']?.toString() ?? '',
    );
    _rejectedController = TextEditingController(
      text: row['z_ditolak']?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: row['keterangan_bongkar']?.toString() ?? '',
    );
    _surveyorId = row['surveyor']?.toString();
    _siteId = row['lokasi_bongkar_site']?.toString();
    _warehouseId = row['lokasi_bongkar_gudang']?.toString();
    _binId = row['lokasi_bongkar_bin']?.toString();
    _unloadTime = row['waktu_bongkar']?.toString();
    final surveyors = _list('surveyors');
    if (_surveyorId == null && surveyors.isNotEmpty) {
      _surveyorId = surveyors.first['id']?.toString();
    }
  }

  @override
  void dispose() {
    _dtmController.dispose();
    _carriedController.dispose();
    _rejectedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> rows, String? id) {
    for (final row in rows) {
      if (row['id']?.toString() == id) return row;
    }
    return null;
  }

  List<Map<String, dynamic>> get _sites => _list('sites');

  List<Map<String, dynamic>> get _warehouses =>
      (_find(_sites, _siteId)?['warehouses'] as List? ?? [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();

  List<Map<String, dynamic>> get _bins =>
      (_find(_warehouses, _warehouseId)?['bins'] as List? ?? [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed == null || parsed < 0 ? 'Masukkan angka 0 atau lebih' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final reception = widget.reception ?? _map(widget.bongkaran?['penerimaan']);
    final payload = <String, dynamic>{
      'no_dtm': _dtmController.text.trim(),
      'surveyor': _surveyorId,
      'lokasi_bongkar_site': _siteId,
      'lokasi_bongkar_gudang': _warehouseId,
      'lokasi_bongkar_bin': _binId,
      'waktu_bongkar': _unloadTime,
      'z_dibawa': _carriedController.text.trim().replaceAll(',', '.'),
      'z_ditolak': _rejectedController.text.trim().replaceAll(',', '.'),
      'keterangan_bongkar': _noteController.text.trim(),
    };
    if (!_isEdit) {
      payload['penerimaan_code'] = reception['legal_number'];
      payload['buyer_code'] = reception['buyer_code'];
    }
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final reception = widget.reception ?? _map(widget.bongkaran?['penerimaan']);
    final buyer = widget.reception != null
        ? _map(widget.reception!['buyer'])
        : _map(widget.bongkaran?['buyer']);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      title: Text(_isEdit ? 'Edit Data Bongkaran' : 'Input Data Bongkaran'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summary(reception, buyer),
                _sectionTitle('Dokumen Bongkaran', Icons.assignment_outlined),
                TextFormField(
                  controller: _dtmController,
                  decoration: _decoration('No. DTM', Icons.confirmation_number_outlined),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _validValue(_surveyorId, _list('surveyors')),
                  decoration: _decoration('Surveyor', Icons.person_search_outlined),
                  validator: (value) => value == null ? 'Pilih surveyor' : null,
                  items: _list('surveyors')
                      .map(
                        (row) => DropdownMenuItem(
                          value: row['id'].toString(),
                          child: Text(row['nama_surveyor']?.toString() ?? '-'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _surveyorId = value),
                ),
                const SizedBox(height: 18),
                _sectionTitle('Lokasi Bongkar', Icons.location_on_outlined),
                DropdownButtonFormField<String>(
                  initialValue: _validValue(_siteId, _sites),
                  decoration: _decoration('Lokasi Site', Icons.business_outlined),
                  validator: (value) => value == null ? 'Pilih site' : null,
                  items: _sites
                      .map(
                        (row) => DropdownMenuItem(
                          value: row['id'].toString(),
                          child: Text(
                            '${row['site_code']} - ${row['site_name']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _siteId = value;
                    _warehouseId = null;
                    _binId = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _validValue(_warehouseId, _warehouses),
                  decoration: _decoration('Lokasi Gudang', Icons.warehouse_outlined),
                  validator: (value) => value == null ? 'Pilih gudang' : null,
                  items: _warehouses
                      .map(
                        (row) => DropdownMenuItem(
                          value: row['id'].toString(),
                          child: Text(
                            '${row['warehouse_code']} - ${row['warehouse_name']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _warehouseId = value;
                    _binId = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _validValue(_binId, _bins),
                  decoration: _decoration('Lokasi Bin', Icons.inventory_2_outlined),
                  validator: (value) => value == null ? 'Pilih bin' : null,
                  items: _bins
                      .map(
                        (row) => DropdownMenuItem(
                          value: row['id'].toString(),
                          child: Text(
                            '${row['bin_code']} - ${row['bin_name']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _binId = value),
                ),
                const SizedBox(height: 18),
                _sectionTitle('Waktu dan Hasil Bongkar', Icons.scale_outlined),
                DropdownButtonFormField<String>(
                  initialValue: _unloadTime,
                   decoration: _decoration('Waktu Bongkar', Icons.schedule_outlined),
                  validator: (value) =>
                      value == null ? 'Pilih waktu bongkar' : null,
                  items:
                      (_list('unload_times').isNotEmpty
                              ? _list('unload_times')
                                    .map((row) => row['value'].toString())
                                    .toList()
                              : ['1A', '2A', '3A', '1B', '2B', '3B'])
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _unloadTime = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _carriedController,
                  decoration: _decoration('Z yang Dibawa', Icons.arrow_downward_rounded, suffix: 'Kg'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _validateNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rejectedController,
                  decoration: _decoration('Z yang Ditolak', Icons.remove_circle_outline, suffix: 'Kg'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _validateNumber,
                ),
                const SizedBox(height: 18),
                _sectionTitle('Catatan', Icons.notes_outlined),
                TextFormField(
                  controller: _noteController,
                  decoration: _decoration('Keterangan (opsional)', Icons.notes_outlined),
                  maxLines: 3,
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
          child: Text(_isEdit ? 'Simpan' : 'Simpan Bongkaran'),
        ),
      ],
    );
  }

  String? _validValue(String? value, List<Map<String, dynamic>> rows) =>
      rows.any((row) => row['id']?.toString() == value) ? value : null;

  InputDecoration _decoration(String label, IconData icon, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixText: suffix,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFFD8E2D7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFFD8E2D7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1F7A2E), width: 1.5),
        ),
      );

  Widget _sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF1F7A2E)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    ),
  );

  Widget _summary(Map<String, dynamic> reception, Map<String, dynamic> buyer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF4F8F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFE1E9DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penerimaan ${reception['legal_number'] ?? '-'}',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Buyer ${reception['buyer_code'] ?? '-'} \u2022 ${buyer['nama_supplier'] ?? '-'}',
            style: TextStyle(fontSize: 12),
          ),
          Text(
            'Nopol ${reception['nopol'] ?? '-'} \u2022 Item ${buyer['nama_item'] ?? '-'}',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
