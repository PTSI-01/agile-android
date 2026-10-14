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
      'tanggal_timbang_keluar',
      'tanggal_timbang_masuk',
      'tanggal_timbang',
      'tanggal_keluar',
      'tanggal_masuk',
      'created_at',
      'updated_at',
      'tanggal_transaksi',
      'tanggal_po',
      'tanggal_penerimaan',
      'tanggal',
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
      final r = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $t',
            },
          )
          .timeout(const Duration(seconds: 20));
      final b = _decodeResponse(r, 'Gagal memuat data timbangan');
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
    final firstDate = !start && from != null ? from! : DateTime(2020);
    final lastDate = start && to != null ? to! : DateTime(2100);
    var initialDate = (start ? from : to) ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    final d = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
    final supplier = _rowValue(row, 'nama_supplier', 'supplier');
    final item = _rowValue(row, 'nama_item', 'item');
    final site = _rowValue(row, 'site_name', 'site');
    final nopol = _rowValue(row, 'nopol_truk', 'nopol');
    final tonaseSupplier = row['tonase_supplier'] ?? row['tonase'];
    final reception = row['Penerimaan'] ?? row['penerimaan'];
    final penerimaanCode = reception is Map
        ? reception['legal_number']
        : row['penerimaan_code'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isIn ? 'Input Timbangan Masuk' : 'Input Timbangan Keluar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Periksa data transaksi',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _detailRow('Nomor PO', row['kode_transaksi']),
              _detailRow('Supplier', supplier),
              _detailRow('Item', item),
              _detailRow('Nomor Polisi', nopol),
              _detailRow('Tonase Supplier', tonaseSupplier),
              _detailRow('Site', site),
              _detailRow('Nomor Penerimaan', penerimaanCode),
              const Divider(height: 24),
              TextField(
                controller: c,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isIn ? 'Tonase Awal' : 'Tonase Final AOL',
                  hintText: 'Masukkan dalam ton',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) {
      c.dispose();
      return;
    }
    try {
      final tonase = double.tryParse(c.text.replaceAll(',', '.'));
      if (tonase == null || tonase <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tonase harus diisi lebih dari 0.')),
          );
        }
        c.dispose();
        return;
      }
      if (mounted) setState(() => loading = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menyimpan data timbangan...')),
        );
      }
      final t = await AuthService.getToken();
      final p = <String, dynamic>{
        'buyer_code': row['kode_transaksi'],
        'penerimaan_code': penerimaanCode,
        'tonase_final_aol': tonase,
      };
      if (isIn)
        p['tonase_awal'] = p['tonase_final_aol'];
      else {
        p['tonase_akhir'] = p['tonase_final_aol'];
        p['tonase_aol'] = p['tonase_final_aol'];
      }
      final r = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/v1/weighing/${widget.stage}'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $t',
            },
            body: jsonEncode(p),
          )
          .timeout(const Duration(seconds: 20));
      final b = _decodeResponse(r, 'Gagal menyimpan data timbangan');
      if (r.statusCode >= 400)
        throw Exception(b['message'] ?? 'Gagal menyimpan');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              b['message']?.toString() ?? 'Data timbangan berhasil disimpan.',
            ),
          ),
        );
      }
      await load();
    } catch (e) {
      if (mounted) setState(() => loading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      c.dispose();
    }
  }

  String _rowValue(
    Map<String, dynamic> row,
    String directKey,
    String relationKey,
  ) {
    final direct = row[directKey];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    final relation = row[relationKey];
    if (relation is Map) {
      for (final key in [directKey, 'name', 'nama', 'full_name']) {
        final value = relation[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return '-';
  }

  Widget _detailRow(String label, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty
        ? '-'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response,
    String fallback,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      throw Exception(
        '$fallback (HTTP ${response.statusCode}). Server tidak mengembalikan JSON.',
      );
    }
    throw Exception('$fallback (HTTP ${response.statusCode}).');
  }

  @override
  Widget build(BuildContext context) {
    final isOut = widget.stage == 'keluar';
    final displayedRows = visibleRows;
    return Scaffold(
      appBar: AppBar(
        title: Text(isOut ? 'Timbangan Keluar' : 'Timbangan Masuk'),
        actions: [
          if (history && (from != null || to != null))
            IconButton(
              tooltip: 'Hapus filter tanggal',
              onPressed: () => setState(() {
                from = null;
                to = null;
              }),
              icon: const Icon(Icons.filter_alt_off),
            ),
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
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
                          ? from != null || to != null
                                ? 'Tidak ada riwayat pada rentang tanggal yang dipilih.'
                                : 'Belum ada riwayat timbangan.'
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
