import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';

class PriceListItemPage extends StatefulWidget {
  const PriceListItemPage({super.key});

  @override
  State<PriceListItemPage> createState() => _PriceListItemPageState();
}

class _PriceListItemPageState extends State<PriceListItemPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _rows = [];
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

  bool _can(String action) =>
      _user?.role?.toLowerCase() == 'superadmin' ||
      _user?.permissions['price_list_item.$action'] == true;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await MasterDataService.listPriceLists(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  String _relatedLabel(dynamic value, String codeField, String nameField) {
    if (value is! Map) return '-';
    final row = value.cast<String, dynamic>();
    return '${row[codeField] ?? '-'} - ${row[nameField] ?? '-'}';
  }

  String _priceLabel(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    final digits = amount.toStringAsFixed(0);
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $grouped';
  }

  Future<void> _openForm([Map<String, dynamic>? priceList]) async {
    try {
      final references = await MasterDataService.priceListReferences(
        priceListId: priceList?['id']?.toString(),
      );
      if (!mounted) return;
      final payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _PriceListForm(
          priceList: priceList,
          items: (references['items'] as List? ?? [])
              .whereType<Map>()
              .map((row) => row.cast<String, dynamic>())
              .toList(),
          suppliers: (references['suppliers'] as List? ?? [])
              .whereType<Map>()
              .map((row) => row.cast<String, dynamic>())
              .toList(),
        ),
      );
      if (payload == null || !mounted) return;

      if (payload['status'] == 'aktif') {
        final hasExisting = await MasterDataService.hasActivePriceList(
          itemId: payload['item_id'].toString(),
          supplierId: payload['supplier_id'].toString(),
          ignoreId: priceList?['id']?.toString(),
        );
        if (!mounted) return;
        if (hasExisting) {
          final replace = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Konfirmasi Pricelist Baru'),
              content: const Text(
                'Sudah ada pricelist aktif untuk item dan supplier ini. Sistem akan menonaktifkan harga lama dan mengaktifkan yang baru. Lanjutkan?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ya, lanjutkan'),
                ),
              ],
            ),
          );
          if (replace != true || !mounted) return;
        }
      }

      await MasterDataService.savePriceList(
        payload,
        id: priceList?['id']?.toString(),
      );
      if (!mounted) return;
      _notice(
        priceList == null
            ? 'Pricelist item berhasil ditambahkan.'
            : 'Pricelist item berhasil diperbarui.',
      );
      await _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> priceList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pricelist item?'),
        content: Text(
          '${_relatedLabel(priceList['item'], 'kode_item', 'nama_item')} untuk ${_relatedLabel(priceList['supplier'], 'vendor_id', 'nama_vendor')} akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD14942),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await MasterDataService.deletePriceList(priceList['id'].toString());
      if (!mounted) return;
      _notice('Pricelist item berhasil dihapus.');
      await _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFD14942)
            : const Color(0xFF1F7A2E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    final activeCount = _rows.where((row) => row['status'] == 'aktif').length;
    final inactiveCount = _rows.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Price List Item',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: ink),
          ),
        ],
      ),
      floatingActionButton: _can('create')
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Price List',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  _stat('Total', '${_rows.length}', const Color(0xFF1E88E5)),
                  const SizedBox(width: 10),
                  _stat('Aktif', '$activeCount', green),
                  const SizedBox(width: 10),
                  _stat('Nonaktif', '$inactiveCount', const Color(0xFFD84315)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _searchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari item, kategori, atau supplier...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            _load();
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList(ink, green)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EDE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7D8983),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

  Widget _buildList(Color ink, Color green) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1F7A2E)),
      );
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
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 150),
            Icon(
              Icons.price_change_outlined,
              size: 52,
              color: Color(0xFF9AA49F),
            ),
            SizedBox(height: 12),
            Center(child: Text('Belum ada price list item')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: green,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final row = _rows[index];
          final item = row['item'] as Map?;
          final supplier = row['supplier'] as Map?;
          final active = row['status'] == 'aktif';
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _can('update') ? () => _openForm(row) : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EDE5)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE3EBD9),
                      child: Icon(Icons.price_change_rounded, color: ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item?['nama_item']?.toString() ??
                                      'Item tidak tersedia',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _statusChip(active, green),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item?['kode_item'] ?? '-'}  •  ${supplier?['vendor_id'] ?? '-'} - ${supplier?['nama_vendor'] ?? '-'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7D8983),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text(
                                _priceLabel(row['price']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1F7A2E),
                                ),
                              ),
                              Text(
                                'Sampai ${row['active_until'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF7D8983),
                                ),
                              ),
                            ],
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

  Widget _statusChip(bool active, Color green) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: (active ? green : const Color(0xFFD84315)).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      active ? 'Aktif' : 'Nonaktif',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: active ? green : const Color(0xFFD84315),
      ),
    ),
  );
}

class _PriceListForm extends StatefulWidget {
  final Map<String, dynamic>? priceList;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> suppliers;

  const _PriceListForm({
    required this.items,
    required this.suppliers,
    this.priceList,
  });

  @override
  State<_PriceListForm> createState() => _PriceListFormState();
}

class _PriceListFormState extends State<_PriceListForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _activeUntilController;
  late String? _itemId;
  late String? _supplierId;
  late String _status;

  bool get _isEdit => widget.priceList != null;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.priceList?['price']?.toString() ?? '',
    );
    final rawDate = widget.priceList?['active_until']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(rawDate);
    _activeUntilController = TextEditingController(
      text: parsedDate == null
          ? rawDate
          : '${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}',
    );
    _itemId = widget.priceList?['item_id']?.toString();
    _supplierId = widget.priceList?['supplier_id']?.toString();
    _status = widget.priceList?['status']?.toString() == 'nonaktif'
        ? 'nonaktif'
        : 'aktif';
  }

  @override
  void dispose() {
    _priceController.dispose();
    _activeUntilController.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Harga wajib diisi';
    final amount = double.tryParse(value.trim().replaceAll(',', '.'));
    if (amount == null || amount < 0) {
      return 'Harga harus bernilai 0 atau lebih';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'item_id': _itemId,
      'supplier_id': _supplierId,
      'price': _priceController.text.trim().replaceAll(',', '.'),
      'active_until': _activeUntilController.text.trim(),
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Price List Item' : 'Tambah Price List Item'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _validId(_itemId, widget.items),
                  decoration: const InputDecoration(labelText: 'Item'),
                  validator: (value) =>
                      value == null ? 'Item wajib dipilih' : null,
                  items: widget.items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item['id'].toString(),
                          child: Text(
                            '${item['kode_item']} - ${item['nama_item']}${item['category'] is Map ? ' / ${item['category']['category_name']}' : ''}${item['unit'] is Map ? ' (${item['unit']['kode_satuan']})' : ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _itemId = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _validId(_supplierId, widget.suppliers),
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  validator: (value) =>
                      value == null ? 'Supplier wajib dipilih' : null,
                  items: widget.suppliers
                      .map(
                        (supplier) => DropdownMenuItem(
                          value: supplier['id'].toString(),
                          child: Text(
                            '${supplier['vendor_id']} - ${supplier['nama_vendor']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _supplierId = value),
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validatePrice,
                ),
                TextFormField(
                  controller: _activeUntilController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Aktif Sampai',
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  validator: _required,
                  onTap: _selectDate,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }

  String? _validId(String? id, List<Map<String, dynamic>> rows) =>
      rows.any((row) => row['id']?.toString() == id) ? id : null;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_activeUntilController.text) ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 15),
    );
    if (date == null) return;
    _activeUntilController.text =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
