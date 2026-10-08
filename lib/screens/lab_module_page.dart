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
      final rows = widget.parameters
          ? await LabModuleService.parameters(search: _search.text)
          : await LabModuleService.list(
              widget.resource!,
              search: _search.text,
              history: _history,
            );
      if (!widget.parameters) {
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
      'legal_number': 'Legal Number',
      'buyer_code': 'Kode PO',
      'penerimaan_code': 'No. DTM',
      'status_lab': 'Status Lab',
      'status_approval': 'Status Approval',
      'approval_at': 'Disetujui Pada',
      'approval_by_name': 'Disetujui Oleh',
      'ka_ks': 'Kadar Air KS',
      'ka_kg': 'Kadar Air KG',
      'wh': 'Whiteness',
      'tp': 'Total Patah',
      'md': 'Benda Asing',
      'hampa': 'Hampa',
      'susut': 'Susut',
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
                      ),
                    ),
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

  Future<void> _createIncoming() async {
    try {
      final refs = await LabModuleService.incomingReferences();
      if (!mounted) return;
      Map<String, dynamic>? selected = refs.isEmpty ? null : refs.first;
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
            title: const Text('Input Lab Incoming'),
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
                              '${r['kode_transaksi'] ?? '-'} - ${r['nama_supplier'] ?? '-'}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialog(() => selected = v),
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
      final reception = selected!['Penerimaan'];
      final payload = <String, dynamic>{
        'buyer_code': selected!['kode_transaksi'],
        'penerimaan_code': reception is Map
            ? reception['legal_number']
            : selected!['penerimaan_code'],
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

  Future<void> _createActual() async {
    try {
      final refs = await LabModuleService.actualReferences();
      if (!mounted) return;
      Map<String, dynamic>? selected = refs.isEmpty ? null : refs.first;
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
      final penerimaan = selected!['Penerimaan'];
      final bongkaran = selected!['Bongkaran'];
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
        : row['legal_number'];
    final secondary = widget.parameters
        ? 'Tanggal PO: ${row['tanggal_po'] ?? '-'}'
        : 'Buyer: ${row['buyer'] is Map ? row['buyer']['kode_transaksi'] ?? row['buyer_code'] : row['buyer_code'] ?? '-'}';
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
              if (approvalPage && !_history)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _action(row, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Tolak'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _action(row, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
