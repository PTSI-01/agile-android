import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';

class WeighingPage extends StatefulWidget {
  final String stage;
  const WeighingPage({super.key, required this.stage});
  @override
  State<WeighingPage> createState() => _WeighingPageState();
}

class _WeighingPageState extends State<WeighingPage> {
  bool loading = true;
  bool history = false;
  DateTime? from;
  DateTime? to;
  String? error;
  List<Map<String, dynamic>> rows = [];

  List<Map<String, dynamic>> get visibleRows {
    if (!history || (from == null && to == null)) return rows;

    return rows.where((row) {
      final date = _rowDate(row);
      if (date == null) return false;
      final day = DateTime(date.year, date.month, date.day);
      if (from != null &&
          day.isBefore(DateTime(from!.year, from!.month, from!.day))) {
        return false;
      }
      if (to != null && day.isAfter(DateTime(to!.year, to!.month, to!.day))) {
        return false;
      }
      return true;
    }).toList();
  }

  DateTime? _rowDate(Map<String, dynamic> row) {
    for (final key in [
      'tanggal_transaksi',
      'tanggal_timbang',
      'tanggal_keluar',
      'tanggal',
      'created_at',
    ]) {
      final value = row[key]?.toString();
      if (value == null || value.length < 10) continue;
      final date = DateTime.tryParse(value.substring(0, 10));
      if (date != null) return date;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final t = await AuthService.getToken();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/v1/weighing/${widget.stage}/references',
      ).replace(queryParameters: {if (history) 'history': '1'});
      final r = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
      );
      final b = jsonDecode(r.body);
      if (r.statusCode >= 400)
        throw Exception(b['message'] ?? 'Gagal memuat data');
      rows = ((b['data'] ?? []) as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          loading = false;
          error = e.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  Future<void> pickDate(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (start ? from : to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (start)
        from = d;
      else
        to = d;
    });
  }

  Future<void> input(Map<String, dynamic> row) async {
    final c = TextEditingController();
    final isIn = widget.stage == 'masuk';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isIn ? 'Input Timbangan Masuk' : 'Input Timbangan Keluar'),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: isIn ? 'Tonase Awal' : 'Tonase Final AOL',
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
      final t = await AuthService.getToken();
      final p = <String, dynamic>{
        'buyer_code': row['kode_transaksi'],
        'penerimaan_code': row['Penerimaan'] is Map
            ? row['Penerimaan']['legal_number']
            : null,
        'tonase_final_aol': double.tryParse(c.text),
      };
      if (isIn)
        p['tonase_awal'] = p['tonase_final_aol'];
      else {
        p['tonase_akhir'] = p['tonase_final_aol'];
        p['tonase_aol'] = p['tonase_final_aol'];
      }
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/v1/weighing/${widget.stage}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: jsonEncode(p),
      );
      final b = jsonDecode(r.body);
      if (r.statusCode >= 400)
        throw Exception(b['message'] ?? 'Gagal menyimpan');
      load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOut = widget.stage == 'keluar';
    final displayedRows = visibleRows;
    return Scaffold(
      appBar: AppBar(
        title: Text(isOut ? 'Timbangan Keluar' : 'Timbangan Masuk'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          if (isOut)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Proses Timbang')),
                ButtonSegment(value: true, label: Text('Riwayat')),
              ],
              selected: {history},
              onSelectionChanged: (v) {
                setState(() => history = v.first);
                load();
              },
            ),
          if (isOut && history)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pickDate(true),
                    child: Text(
                      from == null
                          ? 'Dari tanggal'
                          : from!.toString().substring(0, 10),
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pickDate(false),
                    child: Text(
                      to == null
                          ? 'Sampai tanggal'
                          : to!.toString().substring(0, 10),
                    ),
                  ),
                ),
              ],
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(child: Text(error!, textAlign: TextAlign.center))
                : displayedRows.isEmpty
                ? Center(
                    child: Text(
                      history
                          ? 'Belum ada riwayat timbangan.'
                          : 'Belum ada PO untuk ditimbang.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedRows.length,
                    itemBuilder: (_, i) {
                      final r = displayedRows[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.local_shipping),
                          ),
                          title: Text(
                            r['kode_transaksi']?.toString() ??
                                r['legal_number']?.toString() ??
                                '-',
                          ),
                          subtitle: Text(
                            r['nama_supplier']?.toString() ??
                                r['buyer']?['nama_supplier']?.toString() ??
                                '-',
                          ),
                          trailing: history
                              ? Text('Final ${r['tonase_final_aol'] ?? '-'}')
                              : FilledButton(
                                  onPressed: () => input(r),
                                  child: const Text('Input'),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
