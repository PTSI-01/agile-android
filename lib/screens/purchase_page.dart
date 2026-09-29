import 'package:flutter/material.dart';
import '../services/purchase_service.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  static const ink = Color(0xFF183C32);
  static const green = Color(0xFF1F7A2E);
  static const muted = Color(0xFF7D8983);
  static const gold = Color(0xFFA66F00);

  String _fmt(num value, {bool decimal = false}) {
    final raw = value.toStringAsFixed(decimal ? 2 : 0).split('.');
    var s = raw[0];
    final sign = s.startsWith('-') ? '-' : '';
    if (sign.isNotEmpty) s = s.substring(1);
    final out = <String>[];
    while (s.length > 3) {
      out.insert(0, s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    out.insert(0, s);
    return '$sign${out.join('.')}${decimal ? ',${raw[1]}' : ''}';
  }

  String _formatIndonesianDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final dayName = days[d.weekday % 7];
      final monthName = months[d.month];
      return '$dayName, ${d.day} $monthName ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  List<Map<String, dynamic>> rows = [],
      suppliers = [],
      items = [],
      sites = [],
      provinces = [],
      priceLists = [];
  bool loading = true;
  String search = '';

  // Filter States
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 3));
  DateTime toDate = DateTime.now();
  String selectedStatusFilter = 'Semua';
  String selectedSupplierFilter = 'Semua';
  String datePresetLabel = '3 Hari Terakhir';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      rows = await PurchaseService.list(search: search);
      final r = await PurchaseService.references();
      suppliers = (r['suppliers'] ?? []).cast<Map<String, dynamic>>();
      items = (r['items'] ?? []).cast<Map<String, dynamic>>();
      sites = (r['sites'] ?? []).cast<Map<String, dynamic>>();
      provinces = (r['provinces'] ?? []).cast<Map<String, dynamic>>();
      priceLists = (r['price_lists'] ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, dynamic>> get _filteredRows {
    return rows.where((r) {
      // 1. Search filter
      if (search.isNotEmpty) {
        final q = search.toLowerCase();
        final text =
            '${r['kode_transaksi']} ${r['nama_supplier']} ${r['supplier_id']} ${r['nopol_truk']}'
                .toLowerCase();
        if (!text.contains(q)) return false;
      }

      // 2. Status filter
      if (selectedStatusFilter != 'Semua') {
        final status = '${r['status'] ?? r['status_po'] ?? ''}'.toLowerCase();
        if (!status.contains(selectedStatusFilter.toLowerCase())) return false;
      }

      // 3. Supplier filter
      if (selectedSupplierFilter != 'Semua') {
        final suppId = '${r['supplier_id'] ?? ''}';
        final suppName = '${r['nama_supplier'] ?? ''}';
        if (suppId != selectedSupplierFilter && !suppName.contains(selectedSupplierFilter)) {
          return false;
        }
      }

      // 4. Date filter (Default: 3 days back to today)
      final dateStr = '${r['tanggal_transaksi'] ?? r['created_at'] ?? ''}';
      if (dateStr.isNotEmpty) {
        try {
          final d = DateTime.parse(dateStr.substring(0, 10));
          final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
          final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
          if (d.isBefore(start) || d.isAfter(end)) return false;
        } catch (_) {}
      }

      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedRows {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in _filteredRows) {
      var rawDate = '${r['tanggal_transaksi'] ?? r['created_at'] ?? ''}';
      if (rawDate.length >= 10) {
        rawDate = rawDate.substring(0, 10);
      } else {
        rawDate = 'Lainnya';
      }
      map.putIfAbsent(rawDate, () => []).add(r);
    }
    return map;
  }

  void _showDateFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Tanggal Transaksi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.today_rounded, color: green),
              title: const Text('Hari Ini'),
              trailing: datePresetLabel == 'Hari Ini' ? const Icon(Icons.check, color: green) : null,
              onTap: () {
                setState(() {
                  fromDate = DateTime.now();
                  toDate = DateTime.now();
                  datePresetLabel = 'Hari Ini';
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range_rounded, color: green),
              title: const Text('3 Hari Terakhir (Default)'),
              trailing:
                  datePresetLabel == '3 Hari Terakhir' ? const Icon(Icons.check, color: green) : null,
              onTap: () {
                setState(() {
                  fromDate = DateTime.now().subtract(const Duration(days: 3));
                  toDate = DateTime.now();
                  datePresetLabel = '3 Hari Terakhir';
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded, color: green),
              title: const Text('7 Hari Terakhir'),
              trailing:
                  datePresetLabel == '7 Hari Terakhir' ? const Icon(Icons.check, color: green) : null,
              onTap: () {
                setState(() {
                  fromDate = DateTime.now().subtract(const Duration(days: 7));
                  toDate = DateTime.now();
                  datePresetLabel = '7 Hari Terakhir';
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined, color: green),
              title: const Text('Bulan Ini (30 Hari)'),
              trailing:
                  datePresetLabel == '30 Hari Terakhir' ? const Icon(Icons.check, color: green) : null,
              onTap: () {
                setState(() {
                  fromDate = DateTime.now().subtract(const Duration(days: 30));
                  toDate = DateTime.now();
                  datePresetLabel = '30 Hari Terakhir';
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_rounded, color: green),
              title: const Text('Pilih Rentang Tanggal Custom...'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: DateTimeRange(start: fromDate, end: toDate),
                );
                if (picked != null) {
                  setState(() {
                    fromDate = picked.start;
                    toDate = picked.end;
                    datePresetLabel =
                        '${picked.start.day}/${picked.start.month} - ${picked.end.day}/${picked.end.month}';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilterSheet() {
    final statuses = ['Semua', 'Open', 'Approved', 'Closed', 'Draft', 'Batal'];
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Status PO',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink),
            ),
            const SizedBox(height: 12),
            ...statuses.map(
              (s) => ListTile(
                title: Text(s),
                trailing: selectedStatusFilter == s ? const Icon(Icons.check, color: green) : null,
                onTap: () {
                  setState(() => selectedStatusFilter = s);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupplierFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, refresh) {
            final q = controller.text.trim().toLowerCase();
            final filteredSuppliers = suppliers.where((s) {
              final text = '${s['vendor_id']} ${s['nama_vendor']}'.toLowerCase();
              return text.contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Supplier',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    onChanged: (_) => refresh(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari supplier...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: ListView(
                      children: [
                        ListTile(
                          title: const Text('Semua Supplier'),
                          trailing: selectedSupplierFilter == 'Semua'
                              ? const Icon(Icons.check, color: green)
                              : null,
                          onTap: () {
                            setState(() => selectedSupplierFilter = 'Semua');
                            Navigator.pop(ctx);
                          },
                        ),
                        ...filteredSuppliers.map((s) {
                          final id = '${s['vendor_id'] ?? s['id']}';
                          final name = '${s['nama_vendor'] ?? '-'}';
                          final isSelected = selectedSupplierFilter == id;
                          return ListTile(
                            title: Text('$id - $name'),
                            trailing: isSelected ? const Icon(Icons.check, color: green) : null,
                            onTap: () {
                              setState(() => selectedSupplierFilter = id);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE5EFDF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? green : const Color(0xFFD0D7CB),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? ink : const Color(0xFF33423A),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? ink : muted,
            ),
          ],
        ),
      ),
    );
  }
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus PO'),
        content: Text('Apakah Anda yakin ingin menghapus PO ${row['kode_transaksi'] ?? id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD14942)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PurchaseService.remove(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PO berhasil dihapus')),
          );
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Future<void> _showDetail(Map<String, dynamic> row) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final tonase = double.tryParse('${row['tonase_supplier'] ?? 0}') ?? 0;
        final harga = double.tryParse('${row['harga_supplier'] ?? 0}') ?? 0;
        final total = double.tryParse('${row['harga_beli_gabah'] ?? 0}') ?? 0;
        final kategori = '${row['kategori_transaksi']}' == '1' ? 'Harga Dibawah' : 'Titip';

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'PO: ${row['kode_transaksi'] ?? '-'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _detailRow('Kode PO', '${row['kode_transaksi'] ?? '-'}'),
              _detailRow('Supplier', '${row['nama_supplier'] ?? row['supplier_id'] ?? '-'}'),
              _detailRow('Kategori', kategori),
              _detailRow('Site / Lokasi', '${row['site_name'] ?? row['site_code'] ?? row['site_id'] ?? '-'}'),
              _detailRow('Tonase Supplier', '${_fmt(tonase, decimal: true)} Ton'),
              _detailRow('Harga Supplier', 'Rp ${_fmt(harga, decimal: true)}'),
              _detailRow('Nopol Truk', '${row['nopol_truk'] ?? '-'}'),
              _detailRow('Pengiriman', '${row['jenis_pengiriman'] ?? '-'}'),
              _detailRow('Total Harga Beli', 'Rp ${_fmt(total, decimal: true)}', isBold: true),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD14942),
                        side: const BorderSide(color: Color(0xFFD14942)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _delete(row);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: green),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _form(row);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit / Ubah'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBold ? green : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _chooseSupplier(String current) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          final q = controller.text.trim().toLowerCase();
          final list = suppliers.where((x) {
            final text = '${x['vendor_id'] ?? ''} ${x['nama_vendor'] ?? ''}'.toLowerCase();
            return text.contains(q);
          }).toList();
          return AlertDialog(
            title: const Text('Pilih Supplier'),
            content: SizedBox(
              width: 400,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => refresh(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari kode atau nama supplier',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(child: Text('Supplier tidak ditemukan'))
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final x = list[i];
                              final id = '${x['vendor_id'] ?? x['id'] ?? ''}';
                              final label =
                                  '${x['vendor_id'] ?? x['id'] ?? ''} - ${x['nama_vendor'] ?? ''}';
                              return ListTile(
                                title: Text(label),
                                trailing: id == current ? const Icon(Icons.check) : null,
                                onTap: () => Navigator.pop(ctx, id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _form([Map<String, dynamic>? row]) async {
    String extractStr(Map<String, dynamic>? source, String key, [List<String> altKeys = const []]) {
      if (source == null) return '';
      if (source[key] != null && source[key].toString().isNotEmpty && source[key].toString() != 'null') {
        return source[key].toString();
      }
      for (final alt in altKeys) {
        if (source[alt] != null && source[alt].toString().isNotEmpty && source[alt].toString() != 'null') {
          return source[alt].toString();
        }
      }
      return '';
    }

    String getItemCanonicalValue(Map<String, dynamic> x) {
      if (x['item_id'] != null && x['item_id'].toString().isNotEmpty && x['item_id'].toString() != 'null') {
        return x['item_id'].toString();
      }
      if (x['item'] is Map) {
        final m = x['item'] as Map<String, dynamic>;
        if (m['item_id'] != null && m['item_id'].toString().isNotEmpty && m['item_id'].toString() != 'null') {
          return m['item_id'].toString();
        }
        if (m['id'] != null && m['id'].toString().isNotEmpty && m['id'].toString() != 'null') {
          return m['id'].toString();
        }
      }
      if (x['id'] != null && x['id'].toString().isNotEmpty && x['id'].toString() != 'null') {
        return x['id'].toString();
      }
      return '';
    }

    Set<String> getItemIdentifiers(Map<String, dynamic> x) {
      final set = <String>{};
      void add(dynamic v) {
        if (v != null && v.toString().isNotEmpty && v.toString() != 'null') {
          set.add(v.toString().trim());
        }
      }
      add(x['item_id']);
      add(x['id_item']);
      add(x['master_item_id']);
      add(x['item_site_id']);
      add(x['id']);
      add(x['kode_item']);
      add(x['item_code']);
      add(x['nama_item']);
      add(x['item_name']);
      if (x['item'] is Map) {
        final m = x['item'] as Map<String, dynamic>;
        add(m['item_id']);
        add(m['id']);
        add(m['id_item']);
        add(m['master_item_id']);
        add(m['kode_item']);
        add(m['item_code']);
        add(m['nama_item']);
      }
      return set;
    }

    String getItemCode(Map<String, dynamic> x) {
      if (x['item'] is Map) {
        final nested = x['item'] as Map<String, dynamic>;
        if (nested['kode_item'] != null) return nested['kode_item'].toString();
      }
      if (x['kode_item'] != null) return x['kode_item'].toString();
      return '';
    }

    String getItemName(Map<String, dynamic> x) {
      if (x['item'] is Map) {
        final nested = x['item'] as Map<String, dynamic>;
        if (nested['nama_item'] != null) return nested['nama_item'].toString();
      }
      if (x['nama_item'] != null) return x['nama_item'].toString();
      return '';
    }

    Map<String, dynamic>? firstDetail;
    if (row != null) {
      final detailListKeys = [
        'details',
        'purchase_order_details',
        'purchaseOrderDetails',
        'buyer_details',
        'buyerDetails',
        'po_details',
        'items',
      ];
      for (final key in detailListKeys) {
        if (row[key] is List && (row[key] as List).isNotEmpty) {
          final list = row[key] as List;
          if (list.first is Map) {
            firstDetail = list.first as Map<String, dynamic>;
            break;
          }
        }
      }
    }

    final poItemIds = <String>{};
    void addPoId(dynamic v) {
      if (v != null && v.toString().isNotEmpty && v.toString() != 'null') {
        poItemIds.add(v.toString().trim());
      }
    }

    void addPoIdFromMap(Map<String, dynamic>? map) {
      if (map == null) return;
      addPoId(map['item_id']);
      addPoId(map['id_item']);
      addPoId(map['master_item_id']);
      addPoId(map['item_site_id']);
      addPoId(map['kode_item']);
      addPoId(map['item_code']);
      addPoId(map['nama_item']);
      if (map['item'] is Map) {
        final m = map['item'] as Map<String, dynamic>;
        addPoId(m['item_id']);
        addPoId(m['id']);
        addPoId(m['id_item']);
        addPoId(m['master_item_id']);
        addPoId(m['kode_item']);
        addPoId(m['nama_item']);
      } else {
        addPoId(map['item']);
      }
    }

    if (row != null) {
      addPoIdFromMap(row);

      final detailListKeys = [
        'details',
        'purchase_order_details',
        'purchaseOrderDetails',
        'buyer_details',
        'buyerDetails',
        'po_details',
        'items',
      ];
      for (final key in detailListKeys) {
        if (row[key] is List) {
          for (final item in row[key] as List) {
            if (item is Map<String, dynamic>) {
              addPoIdFromMap(item);
            }
          }
        }
      }

      final detailMapKeys = [
        'detail',
        'buyer_detail',
        'buyerDetail',
        'purchase_order_detail',
      ];
      for (final key in detailMapKeys) {
        if (row[key] is Map<String, dynamic>) {
          addPoIdFromMap(row[key] as Map<String, dynamic>);
        }
      }
    }

    String selectedSupplier = extractStr(row, 'supplier_id', ['vendor_id', 'id_supplier']);
    if (selectedSupplier.isEmpty && row?['supplier'] != null && row!['supplier'] is Map) {
      selectedSupplier = extractStr(row['supplier'], 'vendor_id', ['id', 'supplier_id']);
    }

    String selectedCategory = extractStr(row, 'kategori_transaksi', ['kategori']);
    String selectedSite = extractStr(row, 'site_id', ['id_site']);

    String tonaseStr = '';
    String hargaStr = '';

    if (selectedCategory == '1') {
      if (firstDetail != null) {
        tonaseStr = extractStr(firstDetail, 'tonase_supplier', ['tonase']);
        hargaStr = extractStr(firstDetail, 'harga_supplier', ['harga']);
      }
      if (tonaseStr.isEmpty) tonaseStr = extractStr(row, 'tonase_supplier', ['tonase']);
      if (hargaStr.isEmpty) hargaStr = extractStr(row, 'harga_supplier', ['harga']);
    } else if (selectedCategory == '2') {
      tonaseStr = extractStr(row, 'tonase_supplier', ['tonase']);
      hargaStr = '';
    } else {
      tonaseStr = extractStr(row, 'tonase_supplier', ['tonase']);
      if (tonaseStr.isEmpty && firstDetail != null) {
        tonaseStr = extractStr(firstDetail, 'tonase_supplier', ['tonase']);
      }
      hargaStr = extractStr(row, 'harga_supplier', ['harga']);
      if (hargaStr.isEmpty && firstDetail != null) {
        hargaStr = extractStr(firstDetail, 'harga_supplier', ['harga']);
      }
    }

    int step = 1;
    List<Map<String, dynamic>> availableItems = List<Map<String, dynamic>>.from(items);

    if (selectedSite.isNotEmpty) {
      try {
        final r = await PurchaseService.siteReferences(selectedSite);
        final list = (r['items'] ?? []).cast<Map<String, dynamic>>();
        if (list.isNotEmpty) availableItems = list;
      } catch (_) {}
    }

    String selectedItem = '';
    Map<String, dynamic>? matchedItemObject;

    if (poItemIds.isNotEmpty) {
      for (final x in availableItems) {
        final optionIds = getItemIdentifiers(x);
        if (poItemIds.any((p) => optionIds.contains(p))) {
          matchedItemObject = x;
          break;
        }
      }
      if (matchedItemObject == null) {
        for (final x in items) {
          final optionIds = getItemIdentifiers(x);
          if (poItemIds.any((p) => optionIds.contains(p))) {
            matchedItemObject = x;
            availableItems.add(x);
            break;
          }
        }
      }
      if (matchedItemObject != null) {
        selectedItem = getItemCanonicalValue(matchedItemObject);
      }
    }

    final t = TextEditingController(text: tonaseStr);
    final price = TextEditingController(text: hargaStr);
    final n = TextEditingController(text: extractStr(row, 'nopol_truk', ['nopol']));

    String selectedProvince = extractStr(row, 'provinsi_id', ['provinsi_code', 'provinsi']);
    String selectedCity = extractStr(row, 'kabupaten_id', ['kabupaten_code', 'kabupaten', 'kota_id']);
    String selectedDistrict = extractStr(row, 'kecamatan_id', ['kecamatan_code', 'kecamatan']);
    String selectedVillage = extractStr(row, 'desa_id', ['desa_code', 'desa', 'kelurahan_id']);

    String selectedShipping = extractStr(row, 'jenis_pengiriman', ['pengiriman']);
    if (selectedShipping.isEmpty) selectedShipping = 'SEWA';

    String selectedPriceList = extractStr(row, 'item_sewa_id', ['price_list_id']);

    List<Map<String, dynamic>> cities = [], districts = [], villages = [];
    final scroll = ScrollController();
    final kuli = TextEditingController(text: extractStr(row, 'biaya_kuli', ['kuli']));
    final intern = TextEditingController(text: extractStr(row, 'biaya_truk_intern', ['truk_intern']));
    final sewaPrice = TextEditingController(text: extractStr(row, 'harga_sewa_truk', ['harga_sewa']));
    if (sewaPrice.text.isEmpty) sewaPrice.text = '0';

    if (selectedProvince.isNotEmpty) {
      try {
        cities = await PurchaseService.wilayah('kabupaten', selectedProvince);
        if (selectedCity.isNotEmpty) {
          districts = await PurchaseService.wilayah('kecamatan', selectedCity);
          if (selectedDistrict.isNotEmpty) {
            villages = await PurchaseService.wilayah('desa', selectedDistrict);
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          Map<String, dynamic>? supplier;
          for (final x in suppliers) {
            if ('${x['vendor_id'] ?? x['id']}' == selectedSupplier) {
              supplier = x;
              break;
            }
          }
          final supplierLabel = supplier == null
              ? 'Pilih supplier'
              : '${supplier['vendor_id'] ?? supplier['id']} - ${supplier['nama_vendor'] ?? ''}';

          final seenValues = <String>{};
          final itemOptions = <DropdownMenuItem<String>>[];
          for (final x in availableItems) {
            final val = getItemCanonicalValue(x);
            if (val.isNotEmpty && !seenValues.contains(val)) {
              seenValues.add(val);
              final code = getItemCode(x);
              final name = getItemName(x);
              final label = code.isNotEmpty && name.isNotEmpty
                  ? '$code - $name'
                  : (name.isNotEmpty ? name : (code.isNotEmpty ? code : val));
              itemOptions.add(DropdownMenuItem<String>(
                value: val,
                child: Text(label, overflow: TextOverflow.ellipsis),
              ));
            }
          }

          final siteOptions = sites
              .map((x) => DropdownMenuItem<String>(
                    value: '${x['id']}',
                    child: Text('${x['site_code'] ?? ''} - ${x['site_name'] ?? ''}'),
                  ))
              .toList();
          final siteLabel = sites
              .where((x) => '${x['id']}' == selectedSite)
              .map((x) => '${x['site_code'] ?? ''} - ${x['site_name'] ?? ''}')
              .firstWhere((_) => true, orElse: () => selectedSite);

          String regionLabel(List<Map<String, dynamic>> list, String code) => list
              .where((x) => '${x['code']}' == code)
              .map((x) => '${x['name']}')
              .firstWhere((_) => true, orElse: () => code);

          final tonaseValue = double.tryParse(t.text.replaceAll(',', '.')) ?? 0,
              hargaValue = double.tryParse(price.text.replaceAll(',', '.')) ?? 0,
              sewaValue = double.tryParse(sewaPrice.text.replaceAll(',', '.')) ?? 0,
              kuliValue = double.tryParse(kuli.text.replaceAll(',', '.')) ?? 0,
              internValue = double.tryParse(intern.text.replaceAll(',', '.')) ?? 0;
          final incTransport = tonaseValue > 0
              ? (((tonaseValue * hargaValue) + sewaValue + kuliValue) / tonaseValue)
                  .roundToDouble()
              : 0;
          final totalGabah = (incTransport * tonaseValue) + internValue;

          final stepHeader = Row(
            children: [
              for (final item in const [
                (1, 'Data Supplier'),
                (2, 'Wilayah'),
                (3, 'Logistik & Harga')
              ])
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: step == item.$1 ? green : const Color(0xFFE0E6DF),
                        child: Text('${item.$1}',
                            style: TextStyle(
                                color: step == item.$1 ? Colors.white : Colors.black)),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(item.$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9)),
                      )
                    ],
                  ),
                )
            ],
          );

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Text(row == null ? 'Tambah PO' : 'Edit PO (${row['kode_transaksi'] ?? ''})'),
            content: SizedBox(
              width: double.infinity,
              height: 520,
              child: Column(
                children: [
                  stepHeader,
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scroll,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('cat_$selectedCategory'),
                            initialValue: ['1', '2'].contains(selectedCategory) ? selectedCategory : null,
                            decoration: const InputDecoration(
                              labelText: 'Kategori pembelian *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '1', child: Text('Harga Dibawah')),
                              DropdownMenuItem(value: '2', child: Text('Titip'))
                            ],
                            onChanged: (v) => refresh(() {
                              selectedCategory = v ?? '';
                            }),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            key: ValueKey('site_${selectedSite}_${siteOptions.length}'),
                            initialValue: siteOptions.any((x) => x.value == selectedSite) ? selectedSite : null,
                            decoration: const InputDecoration(
                              labelText: 'Lokasi site *',
                              border: OutlineInputBorder(),
                            ),
                            items: siteOptions,
                            onChanged: (v) async {
                              if (v == null) return;
                              try {
                                final r = await PurchaseService.siteReferences(v);
                                final list = (r['items'] ?? []).cast<Map<String, dynamic>>();
                                refresh(() {
                                  selectedSite = v;
                                  availableItems = list;
                                  selectedItem = '';
                                });
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx)
                                      .showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              final v = await _chooseSupplier(selectedSupplier);
                              if (v != null) {
                                refresh(() {
                                  selectedSupplier = v;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Supplier *',
                                suffixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(supplierLabel),
                            ),
                          ),
                          if (selectedCategory.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              key: ValueKey('item_${selectedItem}_${itemOptions.length}'),
                              initialValue: itemOptions.any((x) => x.value == selectedItem) ? selectedItem : null,
                              decoration: const InputDecoration(
                                labelText: 'Item *',
                                border: OutlineInputBorder(),
                              ),
                              items: itemOptions,
                              onChanged: (v) => refresh(() {
                                selectedItem = v ?? '';
                              }),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: t,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tonase supplier *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (selectedCategory == '1') ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: price,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Harga supplier *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            TextField(
                              controller: n,
                              decoration: const InputDecoration(
                                labelText: 'Nopol truk *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          if (step >= 2) ...[
                            const Divider(height: 24),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Wilayah Pengambilan',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('prov_${selectedProvince}_${provinces.length}'),
                              initialValue: provinces.any((x) => '${x['code']}' == selectedProvince) ? selectedProvince : null,
                              decoration: const InputDecoration(
                                labelText: 'Provinsi *',
                                border: OutlineInputBorder(),
                              ),
                              items: provinces
                                  .map((x) => DropdownMenuItem(
                                        value: '${x['code']}',
                                        child: Text('${x['name']}'),
                                      ))
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                try {
                                  final data = await PurchaseService.wilayah('kabupaten', v);
                                  refresh(() {
                                    selectedProvince = v;
                                    selectedCity = '';
                                    selectedDistrict = '';
                                    selectedVillage = '';
                                    cities = data;
                                    districts = [];
                                    villages = [];
                                  });
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(SnackBar(content: Text('$e')));
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('city_${selectedCity}_${cities.length}'),
                              initialValue: cities.any((x) => '${x['code']}' == selectedCity) ? selectedCity : null,
                              decoration: const InputDecoration(
                                labelText: 'Kabupaten/Kota *',
                                border: OutlineInputBorder(),
                              ),
                              items: cities
                                  .map((x) => DropdownMenuItem(
                                        value: '${x['code']}',
                                        child: Text('${x['name']}'),
                                      ))
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                try {
                                  final data = await PurchaseService.wilayah('kecamatan', v);
                                  refresh(() {
                                    selectedCity = v;
                                    selectedDistrict = '';
                                    selectedVillage = '';
                                    districts = data;
                                    villages = [];
                                  });
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(SnackBar(content: Text('$e')));
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('dist_${selectedDistrict}_${districts.length}'),
                              initialValue: districts.any((x) => '${x['code']}' == selectedDistrict) ? selectedDistrict : null,
                              decoration: const InputDecoration(
                                labelText: 'Kecamatan *',
                                border: OutlineInputBorder(),
                              ),
                              items: districts
                                  .map((x) => DropdownMenuItem(
                                        value: '${x['code']}',
                                        child: Text('${x['name']}'),
                                      ))
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                try {
                                  final data = await PurchaseService.wilayah('desa', v);
                                  refresh(() {
                                    selectedDistrict = v;
                                    selectedVillage = '';
                                    villages = data;
                                  });
                                  if (data.isEmpty && ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                        content: Text('Desa untuk kecamatan ini tidak ditemukan')));
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(SnackBar(content: Text('$e')));
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('vill_${selectedVillage}_${villages.length}'),
                              initialValue: villages.any((x) => '${x['code']}' == selectedVillage) ? selectedVillage : null,
                              decoration: const InputDecoration(
                                labelText: 'Desa/Kelurahan *',
                                border: OutlineInputBorder(),
                              ),
                              items: villages
                                  .map((x) => DropdownMenuItem(
                                        value: '${x['code']}',
                                        child: Text('${x['name']}'),
                                      ))
                                  .toList(),
                              onChanged: (v) => refresh(() {
                                selectedVillage = v ?? '';
                              }),
                            ),
                          ],
                          if (step >= 3) ...[
                            const Divider(height: 24),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Logistik & Harga',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('ship_$selectedShipping'),
                              initialValue: ['SEWA', 'MILIK SENDIRI'].contains(selectedShipping) ? selectedShipping : 'SEWA',
                              decoration: const InputDecoration(
                                labelText: 'Jenis pengiriman *',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'SEWA', child: Text('Sewa Truk')),
                                DropdownMenuItem(value: 'MILIK SENDIRI', child: Text('Milik Sendiri'))
                              ],
                              onChanged: (v) => refresh(() {
                                selectedShipping = v ?? 'SEWA';
                              }),
                            ),
                            if (selectedShipping == 'SEWA') ...[
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                key: ValueKey('price_${selectedPriceList}_${priceLists.length}'),
                                initialValue:
                                    priceLists.any((x) => '${x['id']}' == selectedPriceList) ? selectedPriceList : null,
                                decoration: const InputDecoration(
                                  labelText: 'Item sewa *',
                                  border: OutlineInputBorder(),
                                ),
                                items: priceLists.map((x) {
                                  final item = x['item'] ?? x['ItemSite']?['item'];
                                  return DropdownMenuItem(
                                    value: '${x['id']}',
                                    child: Text(
                                        '${item?['nama_item'] ?? x['price_list_name'] ?? 'Item sewa'}'),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final p = priceLists.where((x) => '${x['id']}' == v).toList();
                                  refresh(() {
                                    selectedPriceList = v;
                                    sewaPrice.text = p.isNotEmpty
                                        ? '${p.first['price'] ?? p.first['harga'] ?? 0}'
                                        : '0';
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextField(
                              controller: sewaPrice,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga sewa truk (otomatis, bisa diubah)',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: kuli,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Biaya kuli',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: intern,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Biaya truk intern',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: green),
                onPressed: () async {
                  if (selectedCategory.isEmpty ||
                      selectedSupplier.isEmpty ||
                      selectedSite.isEmpty ||
                      selectedItem.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Lengkapi kategori, site, supplier, dan item')),
                    );
                    return;
                  }
                  if (step == 1) {
                    refresh(() {
                      step = 2;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) => scroll.animateTo(
                        scroll.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut));
                    return;
                  }
                  if (step == 2) {
                    if (selectedProvince.isEmpty ||
                        selectedCity.isEmpty ||
                        selectedDistrict.isEmpty ||
                        selectedVillage.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Lengkapi wilayah pengambilan terlebih dahulu')),
                      );
                      return;
                    }
                    refresh(() {
                      step = 3;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) => scroll.animateTo(
                        scroll.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut));
                    return;
                  }

                  final tonase = double.tryParse(t.text.replaceAll(',', '.')) ?? 0;
                  final harga = double.tryParse(price.text.replaceAll(',', '.')) ?? 0;

                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (previewCtx) => AlertDialog(
                      title: Text(row == null ? 'Preview PO' : 'Preview Edit PO'),
                      content: SizedBox(
                        width: (MediaQuery.sizeOf(previewCtx).width - 64).clamp(260.0, 360.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kategori: ${selectedCategory == '1' ? 'Harga Dibawah' : 'Titip'}'),
                              Text('Supplier: $supplierLabel'),
                              Text('Site: $siteLabel'),
                              Text('Tonase: ${_fmt(tonaseValue, decimal: true)} Ton'),
                              Text(
                                  'Wilayah: ${regionLabel(provinces, selectedProvince)} / ${regionLabel(cities, selectedCity)} / ${regionLabel(districts, selectedDistrict)} / ${regionLabel(villages, selectedVillage)}'),
                              Text('Pengiriman: ${selectedShipping == 'SEWA' ? 'Sewa Truk' : 'Milik Sendiri'}'),
                              if (selectedShipping == 'SEWA') ...[
                                Text('Harga sewa: Rp ${_fmt(sewaValue, decimal: true)}'),
                              ],
                              Text('Biaya kuli: Rp ${_fmt(kuliValue)}'),
                              Text('Biaya truk intern: Rp ${_fmt(internValue)}'),
                              Text('Harga inc transport: Rp ${_fmt(incTransport)}'),
                              Text('Total harga beli gabah: Rp ${_fmt(totalGabah)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(previewCtx, false),
                          child: const Text('Kembali'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: green),
                          onPressed: () => Navigator.pop(previewCtx, true),
                          child: const Text('Simpan'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {
                    await PurchaseService.save(
                      {
                        'supplier_id': selectedSupplier,
                        'tanggal_transaksi': DateTime.now().toIso8601String().substring(0, 10),
                        'site_id': selectedSite,
                        'kategori_transaksi': selectedCategory,
                        'item_id': selectedCategory == '2' ? selectedItem : null,
                        'tonase_supplier': tonase,
                        'harga_supplier': selectedCategory == '2' ? null : harga,
                        'nopol_truk': n.text,
                        'provinsi_id': selectedProvince,
                        'kabupaten_id': selectedCity,
                        'kecamatan_id': selectedDistrict,
                        'desa_id': selectedVillage,
                        'jenis_pengiriman': selectedShipping,
                        'item_sewa_id': selectedShipping == 'SEWA' && selectedPriceList.isNotEmpty
                            ? selectedPriceList
                            : null,
                        'harga_sewa_truk': sewaValue,
                        'harga_inc_transport': incTransport,
                        'harga_beli_gabah': totalGabah,
                        'biaya_kuli': kuliValue,
                        'biaya_truk_intern': internValue,
                        'details': selectedCategory == '1'
                            ? [
                                {'item_id': selectedItem, 'tonase_supplier': tonase, 'harga_supplier': harga}
                              ]
                            : []
                      },
                      id: row?['id']?.toString(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                child: Text(step == 1 ? 'Selanjutnya' : step == 2 ? 'Selanjutnya' : 'Preview'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true) _load();
  }

  Widget _poCard(Map<String, dynamic> r) {
    final rawTonase = double.tryParse('${r['tonase_supplier'] ?? 0}') ?? 0;
    final tonaseKg = rawTonase > 500 ? rawTonase : rawTonase * 1000;
    final hargaPerKg = double.tryParse('${r['harga_supplier'] ?? 0}') ?? 0;
    final totalHarga = double.tryParse('${r['harga_beli_gabah'] ?? 0}') ?? 0;
    final isTitip = '${r['kategori_transaksi']}' == '2';
    final supplierName = '${r['nama_supplier'] ?? r['supplier_id'] ?? '-'}';
    final kodePo = '${r['kode_transaksi'] ?? '-'}';

    final tonaseAndHargaText = (!isTitip && hargaPerKg > 0)
        ? '${_fmt(tonaseKg)} Kg • @Rp ${_fmt(hargaPerKg)}/Kg'
        : '${_fmt(tonaseKg)} Kg';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _showDetail(r),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isTitip ? const Color(0xFFFFF3C4) : const Color(0xFFE5F2E7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isTitip ? Icons.bookmark_added_rounded : Icons.shopping_bag_rounded,
                  color: isTitip ? gold : green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kodePo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supplierName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tonaseAndHargaText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF33423A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isTitip ? const Color(0xFFFFF3C4) : const Color(0xFFE5F2E7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isTitip ? 'Titip' : 'Harga Dibawah',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isTitip ? gold : green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (totalHarga > 0)
                    Text(
                      'Rp ${_fmt(totalHarga)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: muted),
                    onSelected: (value) {
                      if (value == 'detail') _showDetail(r);
                      if (value == 'edit') _form(r);
                      if (value == 'delete') _delete(r);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Lihat Detail'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedRows;
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      appBar: AppBar(
        title: const Text(
          'Riwayat Pembelian / PO',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 1. TOP FILTER BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            color: const Color(0xFFF7F9F5),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: muted),
                    hintText: 'Cari kode PO atau supplier...',
                    hintStyle: const TextStyle(fontSize: 13, color: muted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
                    ),
                  ),
                  onChanged: (v) {
                    setState(() => search = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _filterChip(
                        label: datePresetLabel == '3 Hari Terakhir' ? 'Tanggal' : datePresetLabel,
                        isActive: datePresetLabel != '3 Hari Terakhir',
                        onTap: _showDateFilterSheet,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _filterChip(
                        label: selectedStatusFilter == 'Semua' ? 'Status' : selectedStatusFilter,
                        isActive: selectedStatusFilter != 'Semua',
                        onTap: _showStatusFilterSheet,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _filterChip(
                        label: selectedSupplierFilter == 'Semua' ? 'Supplier' : selectedSupplierFilter,
                        isActive: selectedSupplierFilter != 'Semua',
                        onTap: _showSupplierFilterSheet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TRANSACTION LIST GROUPED BY DATE
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: green))
                : sortedDates.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada transaksi PO ditemukan.',
                          style: TextStyle(color: muted),
                        ),
                      )
                    : RefreshIndicator(
                        color: green,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            final dateKey = sortedDates[index];
                            final itemsForDate = grouped[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // DATE HEADER
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    _formatIndonesianDate(dateKey),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: ink,
                                    ),
                                  ),
                                ),

                                // ITEMS FOR THIS DATE
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      top: BorderSide(color: Color(0xFFECEFE8)),
                                      bottom: BorderSide(color: Color(0xFFECEFE8)),
                                    ),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: itemsForDate.length,
                                    separatorBuilder: (context, itemIdx) => const Divider(
                                      height: 1,
                                      indent: 72,
                                      color: Color(0xFFF0F3ED),
                                    ),
                                    itemBuilder: (context, itemIdx) {
                                      return _poCard(itemsForDate[itemIdx]);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: green,
        foregroundColor: Colors.white,
        onPressed: () => _form(),
        label: const Text('Tambah PO', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}
