import 'package:flutter/material.dart';

import '../services/lab_module_service.dart';

class LabModulePage extends StatefulWidget {
  final String title;
  final String? resource;
  final bool parameters;
  const LabModulePage({
    super.key,
    required this.title,
    this.resource,
    this.parameters = false,
  });

  @override
  State<LabModulePage> createState() => _LabModulePageState();
}

class _LabModulePageState extends State<LabModulePage> {
  final _search = TextEditingController();
  bool _loading = true;
  bool _history = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inputPage = widget.title == 'Lab Incoming' || widget.title == 'Lab Aktual';
      final approvalPage = widget.title.startsWith('Approve ');
      final rows = widget.parameters
          ? await LabModuleService.parameters(search: _search.text)
          : await LabModuleService.list(
              widget.resource!,
              search: _search.text,
              history: _history,
              input: inputPage,
            );
      if (!widget.parameters && approvalPage) {
        rows.removeWhere((row) {
          final approval = row['status_approval']?.toString();
          final labStatus = row['status_lab']?.toString();
          return _history
              ? approval == null || approval.isEmpty
              : approval != null && approval.isNotEmpty || labStatus != '0';
        });
      }
      if (mounted)
        setState(() {
          _rows = rows;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
    }
  }

  void _detail(Map<String, dynamic> row) {
    const labels = {
      'kode_transaksi': 'Nomor PO',
      'legal_number': 'Legal Number',
      'nama_supplier': 'Supplier',
      'nama_item': 'Item',
      'nopol_truk': 'Nomor Polisi',
      'tonase_supplier': 'Tonase Supplier',
      'buyer_code': 'Kode PO',
      'penerimaan_code': 'No. DTM',
      'status_lab': 'Status Lab',
      'status_approval': 'Status Approval',
      'approval_at': 'Disetujui Pada',
      'approval_by_name': 'Disetujui Oleh',
      'ka_ks': 'Kadar Air KS',
      'ka_kg': 'Kadar Air KG',
      'berat_sampel_awal_ks': 'Berat Sampel Awal KS',
      'berat_sampel_awal_kg': 'Berat Sampel Awal KG',
      'berat_sampel_akhir_kg': 'Berat Sampel Akhir KG',
      'berat_sampel_pk': 'Berat Sampel Pecah Kulit',
      'berat_sampel_beras': 'Berat Sampel Beras',
      'wh': 'Whiteness',
      'tp': 'Total Patah',
      'md': 'Benda Asing',
      'broken_setelah_bongkar': 'Patah Setelah Bongkar',
      'hampa': 'Hampa',
      'susut': 'Susut',
      'std_hpp_incoming': 'HPP Standar Incoming',
      'plan_harga_gabah': 'Plan Harga Gabah',
      'plan_harga_beli_gabah': 'Rencana Harga Beli Gabah',
    };
    final entries = row.entries.where(
      (e) =>
          labels.containsKey(e.key) &&
          e.value != null &&
          e.value.toString().isNotEmpty &&
          e.value is! Map &&
          e.value is! List,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail ${widget.title}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 145,
                          child: Text(
                            labels[e.key]!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _display(e.key, e.value),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!widget.parameters &&
                    (widget.title == 'Lab Incoming' || widget.title == 'Lab Aktual') &&
                    !_history)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (widget.title == 'Lab Incoming') {
                            _createIncoming(row);
                          } else {
                            _createActual(row);
                          }
                        },
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Input Data Lab'),
                      ),
                    ),
                  ),
                if (widget.title.startsWith('Approve ') && !_history)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _action(row, false);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _action(row, true);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.parameters && row['details'] is List) ...[
                  const Divider(),
                  const Text(
                    'Rincian Tonase dan HPP',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  ...(row['details'] as List).map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'TR ${detail['min_tr'] ?? '-'} s/d ${detail['max_tr'] ?? 'Tak Terhingga'} | HPP Rp ${detail['harga_hpp'] ?? '-'}',
                      ),
                    ),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _display(String key, dynamic value) {
    if (key == 'status_lab')
      return value.toString() == '1' ? 'Approve' : 'Belum Approve';
    if (key == 'status_approval')
      return value.toString() == '1'
          ? 'Approve'
          : (value.toString() == '0' ? 'Ditolak' : 'Belum Approve');
    final numeric = double.tryParse(value.toString());
    if (numeric != null) {
      final isPrice =
          key.contains('harga') ||
          key.contains('hpp') ||
          key.contains('biaya') ||
          key.contains('total');
      if (isPrice) return 'Rp ${_thousands(numeric.toStringAsFixed(0))}';
      return numeric.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _thousands(String value) {
    final parts = value.split('.');
    final digits = parts[0];
    final sign = digits.startsWith('-') ? '-' : '';
    final raw = sign.isEmpty ? digits : digits.substring(1);
    final grouped = raw.replaceAllMapped(
      RegExp(r'(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$sign$grouped,${parts.length > 1 ? parts[1] : '00'}';
  }

  Future<void> _action(Map<String, dynamic> row, bool approve) async {
    final id = row['legal_number']?.toString();
    if (id == null || id.isEmpty || widget.parameters) return;
    try {
      await LabModuleService.action(
        widget.resource == 'lab-aktual' ? 'aktual' : 'incoming',
        id,
        approve: approve,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Lab berhasil di-approve.' : 'Lab berhasil ditolak.',
          ),
        ),
      );
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  Future<void> _createParameter([Map<String, dynamic>? existing]) async {
    final date = TextEditingController(
      text:
          existing?['tanggal_po']?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
    final atas = TextEditingController(
      text: existing?['harga_atas']?.toString() ?? '',
    );
    final bawah = TextEditingController(
      text: existing?['harga_bawah']?.toString() ?? '',
    );
    final existingDetails = existing?['details'] is List
        ? (existing!['details'] as List)
        : const [];
    final min = List.generate(
      3,
      (i) => TextEditingController(
        text: i < existingDetails.length && existingDetails[i] is Map
            ? existingDetails[i]['min_tr']?.toString() ?? ''
            : '',
      ),
    );
    final max = List.generate(
      3,
      (i) => TextEditingController(
        text: i < existingDetails.length && existingDetails[i] is Map
            ? existingDetails[i]['max_tr']?.toString() ?? ''
            : '',
      ),
    );
    final hpp = List.generate(
      3,
      (i) => TextEditingController(
        text: i < existingDetails.length && existingDetails[i] is Map
            ? existingDetails[i]['harga_hpp']?.toString() ?? ''
            : '',
      ),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [const Icon(Icons.tune, color: Color(0xFF1F5B42)), const SizedBox(width: 10), Expanded(child: Text(existing == null ? 'Tambah Parameter Lab' : 'Ubah Parameter Lab'))]),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                color: const Color(0xFFF1F6F1),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    const Align(alignment: Alignment.centerLeft, child: Text('Informasi Parameter', style: TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(height: 8),
                    TextField(controller: date, decoration: const InputDecoration(labelText: 'Tanggal PO', prefixIcon: Icon(Icons.calendar_today_outlined), filled: true, fillColor: Colors.white, border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: atas, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Atas', prefixText: 'Rp ', filled: true, fillColor: Colors.white, border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: bawah, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Bawah', prefixText: 'Rp ', filled: true, fillColor: Colors.white, border: OutlineInputBorder()))),
                    ]),
                  ]),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    'DATA PLAN HPP (3 TINGKAT)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              ...List.generate(
                3,
                  (i) => Card(color: Colors.white, elevation: 1, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 6), child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Plan HPP ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextField(
                      controller: hpp[i],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Harga Plan',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: Color(0xFFF8FBF8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: min[i],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Batas Bawah (≥)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: max[i],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Batas Atas (<)',
                              filled: true,
                              fillColor: Color(0xFFF8FBF8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i < 2) const Divider(),
                  ],
                )))),
              ],
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await LabModuleService.saveParameter({
        'tanggal_po': date.text,
        'harga_atas': double.tryParse(atas.text) ?? 0,
        'harga_bawah': double.tryParse(bawah.text) ?? 0,
        'details': List.generate(
          3,
          (i) => {
            'min_tr': double.tryParse(min[i].text) ?? 0,
            'max_tr': max[i].text.isEmpty ? null : double.tryParse(max[i].text),
            'harga_hpp': double.tryParse(hpp[i].text) ?? 0,
          },
        ),
      }, legalNumber: existing?['legal_number']?.toString());
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  Future<void> _deleteParameter(Map<String, dynamic> row) async {
    final number = row['legal_number']?.toString();
    if (number == null || number.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Parameter Lab?'),
        content: Text(number),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await LabModuleService.deleteParameter(number);
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  Future<void> _createIncoming([Map<String, dynamic>? initial]) async {
    try {
      final refs = await LabModuleService.incomingReferences();
      if (!mounted) return;
      final initialCode = initial?['kode_transaksi']?.toString();
      Map<String, dynamic>? selected = refs.isEmpty
          ? null
          : refs.firstWhere(
              (r) => r['kode_transaksi']?.toString() == initialCode,
              orElse: () => refs.first,
            );
      final fields = {
        for (final key in [
          'ka_ks',
          'ka_kg',
          'berat_sampel_awal_ks',
          'berat_sampel_awal_kg',
          'berat_sampel_akhir_kg',
          'berat_sampel_pk',
          'berat_sampel_beras',
          'wh',
          'tp',
          'md',
          'broken_setelah_bongkar',
        ])
          key: TextEditingController(),
      };
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setDialog) => AlertDialog(
            title: const Text('Input Data Lab Incoming'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Identitas PO', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F5B42))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'PO / Buyer'),
                    items: refs
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              '${r['kode_transaksi'] ?? '-'} - ${r['nama_supplier'] ?? '-'}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialog(() => selected = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Hasil Pemeriksaan Sampel', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F5B42))),
                  const SizedBox(height: 8),
                  ...fields.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: e.value,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: _labFieldLabel(e.key),
                          hintText: 'Masukkan ${_labFieldLabel(e.key).toLowerCase()}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Preview'),
              ),
            ],
          ),
        ),
      );
      if (ok != true || selected == null) return;
      var parameter = selected!['parameter_lab'] is List
          ? (selected!['parameter_lab'] as List).whereType<Map>().toList()
          : <Map>[];
      if (parameter.isEmpty) {
        final allParameters = await LabModuleService.parameters();
        final poDate = selected!['tanggal_transaksi']?.toString().substring(0, 10);
        for (final group in allParameters) {
          if (group['tanggal_po']?.toString().substring(0, 10) == poDate && group['details'] is List) {
            parameter = (group['details'] as List).whereType<Map>().map((detail) => {
              ...detail,
              'harga_atas': group['harga_atas'],
              'harga_bawah': group['harga_bawah'],
            }).toList();
            break;
          }
        }
      }
      if (parameter.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parameter Lab belum tersedia untuk tanggal PO ini.')));
        return;
      }
      if (fields.values.any((controller) => controller.text.trim().isEmpty)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi seluruh field pemeriksaan sebelum preview.')));
        return;
      }
      final tonase = double.tryParse(selected!['tonase_supplier']?.toString() ?? '');
      final matched = parameter.firstWhere((p) {
        final min = double.tryParse(p['min_tr']?.toString() ?? '') ?? 0;
        final max = double.tryParse(p['max_tr']?.toString() ?? '');
        return (tonase == null || tonase >= min) && (max == null || tonase == null || tonase <= max);
      }, orElse: () => parameter.first);
      final stdHpp = double.tryParse(matched['harga_hpp']?.toString() ?? '') ?? 0;
      final values = {for (final e in fields.entries) e.key: double.tryParse(e.value.text) ?? 0};
      final akhirKg = values['berat_sampel_akhir_kg'] ?? 0;
      final awalKg = values['berat_sampel_awal_kg'] ?? 0;
      final hampa = awalKg > 0 ? (awalKg - akhirKg) / (awalKg / 100) : 0;
      final susut = 100 - (akhirKg / 1.5);
      final adjustSusut = susut * 1.2;
      final persentaseKsKg = 100 - adjustSusut;
      final persentaseKgPk = akhirKg > 0 ? (values['berat_sampel_pk']! / (akhirKg / 100)) : 0;
      final adjustPk = persentaseKgPk * 0.952;
      final persentasePutih = akhirKg > 0 ? (values['berat_sampel_beras']! / (akhirKg / 100)) : 0;
      final adjustPutih = persentasePutih * 0.952;
      final planRend = (100 - adjustSusut) * (adjustPutih / 100);
      final planHargaBeli = (planRend / 100 * stdHpp) - 75;
      if (await _showIncomingPreview(selected!, fields, planHargaBeli) != true) return;
      final reception = selected!['Penerimaan'] ?? selected!['penerimaan'];
      final payload = <String, dynamic>{
        'buyer_code': selected!['kode_transaksi'],
        'penerimaan_code': reception is Map
            ? reception['legal_number']
            : (selected!['penerimaan_code'] ?? selected!['penerimaanCode']),
        'plan_harga_gabah': planHargaBeli,
      };
      for (final e in fields.entries) {
        payload[e.key] = double.tryParse(e.value.text);
      }
      await LabModuleService.saveIncoming(payload);
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  Future<bool?> _showIncomingPreview(
    Map<String, dynamic> selected,
    Map<String, TextEditingController> fields,
    double planPrice,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preview Lab Incoming'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PO: ${selected['kode_transaksi'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('Supplier: ${selected['nama_supplier'] ?? '-'}'),
              const Divider(),
              ...fields.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${_labFieldLabel(e.key)}: ${e.value.text}'),
                  )),
              const Divider(),
              Text('Plan Harga Beli Gabah: Rp ${_formatRupiah(planPrice)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F5B42))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Kembali')),
          FilledButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.save_outlined), label: const Text('Simpan')),
        ],
      ),
    );
  }

  String _formatRupiah(double value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  String _labFieldLabel(String key) {
    const labels = {
      'ka_ks': 'Kadar Air KS (%)',
      'ka_kg': 'Kadar Air KG (%)',
      'berat_sampel_awal_ks': 'Berat Sampel Awal KS (gram)',
      'berat_sampel_awal_kg': 'Berat Sampel Awal KG (gram)',
      'berat_sampel_akhir_kg': 'Berat Sampel Akhir KG (gram)',
      'berat_sampel_pk': 'Berat Sampel Pecah Kulit (gram)',
      'berat_sampel_beras': 'Berat Sampel Beras (gram)',
      'wh': 'Whiteness (%)',
      'tp': 'Total Patah (%)',
      'md': 'Benda Asing (%)',
      'broken_setelah_bongkar': 'Patah Setelah Bongkar (%)',
    };
    return labels[key] ?? key;
  }

  Future<void> _createActual([Map<String, dynamic>? initial]) async {
    try {
      final refs = await LabModuleService.actualReferences();
      if (!mounted) return;
      final initialCode = initial?['kode_transaksi']?.toString();
      Map<String, dynamic>? selected = refs.isEmpty
          ? null
          : refs.firstWhere(
              (r) => r['kode_transaksi']?.toString() == initialCode,
              orElse: () => refs.first,
            );
      final keys = [
        'ka_ks',
        'ka_kg',
        'berat_sampel_awal_ks',
        'berat_sampel_awal_kg',
        'berat_sampel_akhir_kg',
        'berat_sampel_pk',
        'berat_sampel_beras',
        'wh',
        'tp',
        'md',
        'broken_setelah_bongkar',
      ];
      final fields = {for (final key in keys) key: TextEditingController()};
      final tonase = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setDialog) => AlertDialog(
            title: const Text('Input Lab Aktual'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'PO / Buyer'),
                    items: refs
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              '${r['kode_transaksi'] ?? '-'} - ${r['nama_supplier'] ?? r['supplier']?['nama_supplier'] ?? '-'}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialog(() => selected = v),
                  ),
                  TextField(
                    controller: tonase,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tonase Final (AOL)',
                    ),
                  ),
                  ...fields.entries.map(
                    (e) => TextField(
                      controller: e.value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: e.key),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      );
      if (ok != true || selected == null) return;
      final penerimaan = selected!['Penerimaan'] ?? selected!['penerimaan'];
      final bongkaran = selected!['Bongkaran'] ?? selected!['bongkaran'];
      final payload = <String, dynamic>{
        'buyer_code': selected!['kode_transaksi'],
        'penerimaan_code': penerimaan is Map
            ? penerimaan['legal_number']
            : selected!['penerimaan_code'],
        'bongkaran_code': bongkaran is Map
            ? bongkaran['legal_number']
            : selected!['bongkaran_code'],
        'tonase_final_aol': double.tryParse(tonase.text),
      };
      for (final e in fields.entries)
        payload[e.key] = double.tryParse(e.value.text);
      await LabModuleService.saveActual(payload);
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        if (widget.parameters)
          IconButton(onPressed: _createParameter, icon: const Icon(Icons.add)),
        if (widget.title == 'Lab Incoming')
          IconButton(onPressed: _createIncoming, icon: const Icon(Icons.add)),
        if (widget.title == 'Lab Aktual')
          IconButton(onPressed: _createActual, icon: const Icon(Icons.add)),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Cari data...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _load,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (!widget.parameters)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(
                    widget.title == 'Lab Incoming' ||
                            widget.title == 'Lab Aktual'
                        ? 'PO Belum Dicek'
                        : 'Menunggu Approval',
                  ),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(
                    widget.title == 'Lab Incoming' ||
                            widget.title == 'Lab Aktual'
                        ? 'Riwayat Cek'
                        : 'Riwayat',
                  ),
                ),
              ],
              selected: {_history},
              onSelectionChanged: (v) {
                setState(() => _history = v.first);
                _load();
              },
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _rows.isEmpty
              ? const Center(child: Text('Belum ada data.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(_rows[i]),
                  ),
                ),
        ),
      ],
    ),
  );

  Widget _card(Map<String, dynamic> row) {
    final primary = widget.parameters
        ? row['legal_number']
        : (row['legal_number'] ?? row['kode_transaksi']);
    final secondary = widget.parameters
        ? 'Tanggal PO: ${row['tanggal_po'] ?? '-'}'
        : 'Supplier: ${row['nama_supplier'] ?? (row['supplier'] is Map ? row['supplier']['nama_supplier'] : row['buyer'] is Map ? row['buyer']['nama_supplier'] : '-')}';
    final approvalPage = widget.title.startsWith('Approve ');
    final inputPage =
        widget.title == 'Lab Incoming' || widget.title == 'Lab Aktual';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _detail(row),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE3EBD9),
                  child: Icon(
                    widget.parameters ? Icons.tune : Icons.science,
                    color: const Color(0xFF1F5B42),
                  ),
                ),
                title: Text(
                  primary?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(secondary),
                trailing: widget.parameters
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Atas ${row['harga_atas'] ?? '-'}\nBawah ${row['harga_bawah'] ?? '-'}',
                            textAlign: TextAlign.end,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _createParameter(row);
                              if (value == 'delete') _deleteParameter(row);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Ubah')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(
                        inputPage
                            ? (_history ? 'Sudah Dicek' : 'Belum Dicek')
                            : (row['status_approval']?.toString() == '1'
                                  ? 'Approved'
                                  : (row['status_approval']?.toString() == '0'
                                        ? 'Rejected'
                                        : 'Menunggu')),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
