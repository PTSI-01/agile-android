import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/purchase_target_service.dart';

const _green = Color(0xFF176B35);
const _lightGreen = Color(0xFFEAF4E8);
const _yellow = Color(0xFFF1B928);

class PurchaseTargetPage extends StatefulWidget {
  const PurchaseTargetPage({super.key});

  @override
  State<PurchaseTargetPage> createState() => _PurchaseTargetPageState();
}

class _PurchaseTargetPageState extends State<PurchaseTargetPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;
  String _status = 'all';

  bool _can(String action) =>
      _user?.role?.toLowerCase() == 'superadmin' ||
      _user?.permissions['master_target.$action'] == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        AuthService.refreshCurrentUser(),
        PurchaseTargetService.list(search: _search.text, status: _status),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as UserModel?;
        _rows = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openForm([Map<String, dynamic>? target]) async {
    Map<String, dynamic>? complete = target;
    if (target != null) {
      try {
        complete = await PurchaseTargetService.show(target['id'].toString());
      } catch (e) {
        if (!mounted) return;
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
        return;
      }
    }
    if (!mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseTargetFormPage(target: complete),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus target pembelian?'),
        content: Text(
          '${row['legal_number'] ?? 'Target ini'} beserta seluruh rincian buyer akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PurchaseTargetService.delete(row['id'].toString());
      if (!mounted) return;
      _message('Target pembelian berhasil dihapus.');
      await _load();
    } catch (e) {
      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Target Pembelian Buyer',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: _can('create')
          ? FloatingActionButton.extended(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Target'),
            )
          : null,
      body: Column(
        children: [
          _filters(),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E9E1))),
      ),
      child: Column(
        children: [
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Cari nomor target atau tahun...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        _load();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 19, color: _green),
              const SizedBox(width: 8),
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _status,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                  DropdownMenuItem(value: '1', child: Text('Aktif')),
                  DropdownMenuItem(value: '0', child: Text('Nonaktif')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _InfoState(
        icon: Icons.cloud_off_rounded,
        message: _error!,
        buttonLabel: 'Coba Lagi',
        onPressed: _load,
      );
    }
    if (_rows.isEmpty) {
      return _InfoState(
        icon: Icons.track_changes_rounded,
        message: 'Belum ada target pembelian buyer.',
        buttonLabel: _can('create') ? 'Tambah Target' : null,
        onPressed: _can('create') ? () => _openForm() : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _targetCard(_rows[index]),
      ),
    );
  }

  Widget _targetCard(Map<String, dynamic> row) {
    final active = _toInt(row['status']) == 1;
    final annual = _toDouble(row['tonase_target']);
    final allocated = _toDouble(row['allocated_target']);
    final remaining = _toDouble(row['remaining_target']);
    final details = (row['details'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0E8DC)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.track_changes_rounded, color: _green),
        ),
        title: Text(
          row['legal_number']?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Tahun ${row['tahun'] ?? '-'}  \u2022  ${_formatNumber(annual)} kg',
          ),
        ),
        trailing: _can('update') || _can('delete')
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _openForm(row);
                  if (value == 'delete') _delete(row);
                },
                itemBuilder: (_) => [
                  if (_can('update'))
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Ubah target'),
                    ),
                  if (_can('delete'))
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus target'),
                    ),
                ],
              )
            : const Icon(Icons.expand_more_rounded),
        children: [
          Row(
            children: [
              _statusBadge(active),
              const Spacer(),
              Text(
                '${details.length} rincian',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _progress(annual == 0 ? 0 : allocated / annual),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _metric('Terpakai', '${_formatNumber(allocated)} kg'),
              ),
              Expanded(
                child: _metric('Sisa', '${_formatNumber(remaining)} kg'),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const Divider(height: 26),
            ...details.map(_detailRow),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(Map<String, dynamic> detail) {
    final buyers = (detail['buyers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => e['full_name']?.toString() ?? '-')
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4CF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              detail['bulan']?.toString() ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF805D00),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${detail['bulan_label'] ?? '-'} \u2022 ${_formatNumber(_toDouble(detail['tonase_target']))} kg / buyer',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(buyers.isEmpty ? 'Buyer tidak tersedia' : buyers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );

  Widget _progress(double value) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: LinearProgressIndicator(
      minHeight: 8,
      value: value.clamp(0, 1),
      backgroundColor: const Color(0xFFE7ECE4),
      valueColor: const AlwaysStoppedAnimation(_yellow),
    ),
  );

  Widget _statusBadge(bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? _lightGreen : const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      active ? 'AKTIF' : 'NON AKTIF',
      style: TextStyle(
        color: active ? _green : Colors.black54,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class PurchaseTargetFormPage extends StatefulWidget {
  final Map<String, dynamic>? target;

  const PurchaseTargetFormPage({super.key, this.target});

  @override
  State<PurchaseTargetFormPage> createState() => _PurchaseTargetFormPageState();
}

class _PurchaseTargetFormPageState extends State<PurchaseTargetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _year;
  late final TextEditingController _annual;
  final List<_TargetLine> _lines = [];
  List<Map<String, dynamic>> _buyers = [];
  int _status = 1;
  bool _loadingBuyer = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.target != null;
  double get _annualValue => _number(_annual.text);
  double get _allocated => _lines.fold(
    0,
    (sum, line) => sum + _number(line.target.text) * line.buyerIds.length,
  );

  @override
  void initState() {
    super.initState();
    final target = widget.target;
    _year = TextEditingController(
      text: (target?['tahun'] ?? DateTime.now().year).toString(),
    );
    _annual = TextEditingController(
      text: target == null
          ? ''
          : _formatNumber(_toDouble(target['tonase_target'])),
    );
    _status = _toInt(target?['status'], fallback: 1);
    final details = (target?['details'] as List? ?? const []).whereType<Map>();
    for (final raw in details) {
      final detail = Map<String, dynamic>.from(raw);
      _lines.add(
        _TargetLine(
          month: detail['bulan']?.toString().padLeft(2, '0') ?? '01',
          target: _formatNumber(_toDouble(detail['tonase_target'])),
          buyerIds: (detail['buyer_ids'] as List? ?? const [])
              .map((id) => id.toString())
              .toSet(),
        ),
      );
    }
    if (_lines.isEmpty) _lines.add(_TargetLine(month: _currentMonth()));
    _loadBuyers();
  }

  @override
  void dispose() {
    _year.dispose();
    _annual.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBuyers() async {
    try {
      final rows = await PurchaseTargetService.buyers();
      if (!mounted) return;
      setState(() {
        _buyers = rows;
        _loadingBuyer = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBuyer = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _addLine() {
    setState(() => _lines.add(_TargetLine(month: _currentMonth())));
  }

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    final line = _lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  Future<void> _selectBuyers(_TargetLine line) async {
    if (_loadingBuyer) return;
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuyerPicker(
        buyers: _buyers,
        selected: Set<String>.from(line.buyerIds),
      ),
    );
    if (result != null && mounted) {
      setState(() => line.buyerIds = result);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lines.any((line) => line.buyerIds.isEmpty)) {
      setState(() => _error = 'Pilih minimal satu buyer pada setiap rincian.');
      return;
    }
    if (_allocated > _annualValue) {
      setState(() => _error = 'Total target buyer melebihi target tahunan.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PurchaseTargetService.save({
        'tahun': int.parse(_year.text),
        'tonase_target': _annualValue,
        'status': _status,
        'details': _lines
            .map(
              (line) => {
                'bulan': line.month,
                'tonase_target': _number(line.target.text),
                'buyer_ids': line.buyerIds.toList(),
              },
            )
            .toList(),
      }, id: widget.target?['id']?.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _green,
          content: Text(
            _editing
                ? 'Target pembelian berhasil diperbarui.'
                : 'Target pembelian berhasil ditambahkan.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _annualValue - _allocated;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _editing ? 'Ubah Target Pembelian' : 'Tambah Target Pembelian',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Color(0xFFE3E8DF))),
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Target'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _sectionTitle('Target Tahunan', Icons.calendar_month_rounded),
            const SizedBox(height: 10),
            _panel(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 4,
                          decoration: _input('Tahun *', Icons.event_rounded),
                          validator: (value) {
                            final year = int.tryParse(value ?? '');
                            return year == null || year < 2000 || year > 2100
                                ? 'Tahun tidak valid'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _status,
                          decoration: _input(
                            'Status *',
                            Icons.toggle_on_rounded,
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Aktif')),
                            DropdownMenuItem(value: 0, child: Text('Nonaktif')),
                          ],
                          onChanged: (value) =>
                              setState(() => _status = value ?? 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _annual,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: _input(
                      'Target Tahunan (kg) *',
                      Icons.track_changes_rounded,
                    ),
                    validator: (value) => _number(value ?? '') <= 0
                        ? 'Target tahunan wajib lebih dari 0'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Target Bulanan per Buyer', Icons.groups_rounded),
            const SizedBox(height: 10),
            ...List.generate(_lines.length, (index) => _lineCard(index)),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _addLine,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Tambah Rincian Bulan / Buyer'),
            ),
            const SizedBox(height: 16),
            _summary(remaining),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lineCard(int index) {
    final line = _lines[index];
    final selectedBuyers = _buyers
        .where((buyer) => line.buyerIds.contains(buyer['buyer_id']?.toString()))
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _yellow,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Rincian Target',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    tooltip: 'Hapus rincian',
                    onPressed: () => _removeLine(index),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: line.month,
              decoration: _input('Bulan *', Icons.calendar_view_month_rounded),
              items: _months.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => line.month = value ?? '01',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: line.target,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              onChanged: (_) => setState(() {}),
              decoration: _input(
                'Tonase Target per Buyer (kg) *',
                Icons.scale_rounded,
              ),
              validator: (value) => _number(value ?? '') <= 0
                  ? 'Tonase per buyer wajib lebih dari 0'
                  : null,
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: _loadingBuyer ? null : () => _selectBuyers(line),
              child: InputDecorator(
                decoration: _input('Buyer *', Icons.people_alt_rounded)
                    .copyWith(
                      errorText: line.buyerIds.isEmpty && _error != null
                          ? 'Pilih minimal satu buyer'
                          : null,
                    ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loadingBuyer
                            ? 'Memuat buyer...'
                            : selectedBuyers.isEmpty
                            ? 'Cari dan pilih buyer'
                            : '${selectedBuyers.length} buyer dipilih',
                        style: TextStyle(
                          color: selectedBuyers.isEmpty
                              ? Colors.black54
                              : Colors.black87,
                          fontWeight: selectedBuyers.isEmpty
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.search_rounded, color: _green),
                  ],
                ),
              ),
            ),
            if (selectedBuyers.isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedBuyers
                    .map(
                      (buyer) => Chip(
                        backgroundColor: _lightGreen,
                        side: BorderSide.none,
                        label: Text(
                          buyer['full_name']?.toString() ??
                              buyer['buyer_id'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: () => setState(
                          () => line.buyerIds.remove(
                            buyer['buyer_id']?.toString(),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (line.buyerIds.isNotEmpty && _number(line.target.text) > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Alokasi rincian: ${_formatNumber(_number(line.target.text) * line.buyerIds.length)} kg',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(double remaining) {
    final exceeded = remaining < 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: exceeded ? const Color(0xFFFFEBEE) : const Color(0xFF163F31),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          _summaryRow(
            'Target Tahunan',
            '${_formatNumber(_annualValue)} kg',
            exceeded,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Total Alokasi Buyer',
            '${_formatNumber(_allocated)} kg',
            exceeded,
          ),
          const Divider(color: Colors.white24, height: 20),
          _summaryRow(
            exceeded ? 'Melebihi Target' : 'Sisa Target',
            '${_formatNumber(remaining.abs())} kg',
            exceeded,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    bool darkText, {
    bool bold = false,
  }) {
    final color = darkText ? Colors.red.shade800 : Colors.white;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: color)),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(
    children: [
      Icon(icon, color: _green, size: 20),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    ],
  );

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFDEE7DA)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: _green),
    counterText: '',
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFCED8C9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: _green, width: 1.6),
    ),
  );
}

class _BuyerPicker extends StatefulWidget {
  final List<Map<String, dynamic>> buyers;
  final Set<String> selected;

  const _BuyerPicker({required this.buyers, required this.selected});

  @override
  State<_BuyerPicker> createState() => _BuyerPickerState();
}

class _BuyerPickerState extends State<_BuyerPicker> {
  final _search = TextEditingController();
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selected);
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final rows = widget.buyers.where((buyer) {
      final value = '${buyer['buyer_id'] ?? ''} ${buyer['full_name'] ?? ''}'
          .toLowerCase();
      return value.contains(query);
    }).toList();
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .94,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih Buyer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected.length} dipilih',
                    style: const TextStyle(color: _green),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari kode atau nama buyer...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('Buyer tidak ditemukan.'))
                  : ListView.builder(
                      controller: controller,
                      itemCount: rows.length,
                      itemBuilder: (_, index) {
                        final buyer = rows[index];
                        final id = buyer['buyer_id']?.toString() ?? '';
                        return CheckboxListTile(
                          value: _selected.contains(id),
                          activeColor: _green,
                          title: Text(
                            buyer['full_name']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('Gunakan Buyer Terpilih'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetLine {
  String month;
  Set<String> buyerIds;
  final TextEditingController target;

  _TargetLine({required this.month, String target = '', Set<String>? buyerIds})
    : target = TextEditingController(text: target),
      buyerIds = buyerIds ?? <String>{};

  void dispose() => target.dispose();
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = _formatNumber(double.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _InfoState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _InfoState({
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: _green.withValues(alpha: .55)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
          ],
        ],
      ),
    ),
  );
}

const _months = <String, String>{
  '01': 'Januari',
  '02': 'Februari',
  '03': 'Maret',
  '04': 'April',
  '05': 'Mei',
  '06': 'Juni',
  '07': 'Juli',
  '08': 'Agustus',
  '09': 'September',
  '10': 'Oktober',
  '11': 'November',
  '12': 'Desember',
};

String _currentMonth() => DateTime.now().month.toString().padLeft(2, '0');

double _number(String value) =>
    double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

double _toDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

int _toInt(dynamic value, {int fallback = 0}) =>
    int.tryParse(value?.toString() ?? '') ?? fallback;

String _formatNumber(double value) {
  final digits = value.round().toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
