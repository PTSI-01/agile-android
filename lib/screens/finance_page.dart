import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  UserModel? _user;

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
      _user?.permissions['finance.$action'] == true;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await FinanceService.list(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  String _value(Map<String, dynamic> row, String key, [String fallback = '-']) {
    final value = row[key]?.toString().trim();
    return (value == null || value.isEmpty || value == 'null')
        ? fallback
        : value;
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Finance',
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
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Color(0xFFE9EDE5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Data',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7D8983),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_rows.length}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari legal number, buyer, atau supplier...',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
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
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
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
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: _filteredRows.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10),
                        itemBuilder: (_, index) => _card(_filteredRows[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _rows;
    return _rows.where((row) {
      final buyer = row['buyer'];
      final searchTarget = [
        row['legal_number'],
        row['buyer_code'],
        row['penerimaan_code'],
        buyer is Map ? buyer['nama_supplier'] : null,
        buyer is Map ? buyer['nama_sourching'] : null,
      ].join(' ').toLowerCase();
      return searchTarget.contains(query);
    }).toList();
  }

  Widget _card(Map<String, dynamic> row) {
    final buyer = row['buyer'] is Map
        ? row['buyer'] as Map<String, dynamic>
        : <String, dynamic>{};
    final supply = buyer['nama_supplier'] ?? '-';
    final status = row['status_finance']?.toString() ?? '0';
    final statusColor = status == '1' ? Color(0xFF1F7A2E) : Color(0xFFA66F00);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
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
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _value(row, 'legal_number'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status == '1' ? 'Approved' : 'Proses',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _info('Buyer', _value(row, 'buyer_code')),
            _info('Supplier', supply),
            _info('Potongan PPH', _value(row, 'potong_pph')),
            _info('Total Harga', _value(row, 'total_harga')),
            _info('Net L/R', _value(row, 'net_laba_rugi')),
            if (_can('update'))
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.check_circle_rounded),
                    label: Text('Approval'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
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
}
