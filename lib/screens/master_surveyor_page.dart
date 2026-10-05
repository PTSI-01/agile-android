import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';

class MasterSurveyorPage extends StatefulWidget {
  const MasterSurveyorPage({super.key});

  @override
  State<MasterSurveyorPage> createState() => _MasterSurveyorPageState();
}

class _MasterSurveyorPageState extends State<MasterSurveyorPage> {
  static const _green = Color(0xFF1F7A2E);
  static const _ink = Color(0xFF183C32);
  static const _gold = Color(0xFFE7AA19);

  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _rows = [];
  UserModel? _user;
  String _status = 'semua';
  String? _error;
  bool _loading = true;

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
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  bool _can(String action) =>
      _user?.role?.toLowerCase() == 'superadmin' ||
      _user?.permissions['master_surveyor.${action.toLowerCase()}'] == true;

  bool _active(Map<String, dynamic> row) => {
    'active',
    'aktif',
    '1',
  }.contains(row['status']?.toString().toLowerCase());

  int _usersCount(Map<String, dynamic> row) {
    final count = row['users_count'];
    if (count != null) return int.tryParse(count.toString()) ?? 0;
    return (row['users'] as List?)?.length ?? 0;
  }

  List<Map<String, dynamic>> get _visibleRows {
    if (_status == 'semua') return _rows;
    final active = _status == 'aktif';
    return _rows.where((row) => _active(row) == active).toList();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await MasterDataService.listSurveyors(search: _search.text);
      if (mounted) setState(() => _rows = rows);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 400), _load);
    setState(() {});
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Color(0xFFB3261E) : _green,
      ),
    );
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    var detail = row;
    if (row != null) {
      try {
        detail = await MasterDataService.getSurveyor(row['id'].toString());
      } catch (_) {
        // Data daftar tetap dapat digunakan jika detail belum tersedia.
      }
    }
    if (!mounted) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SurveyorFormSheet(record: detail),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus surveyor?'),
        content: Text(
          '${row['legal_number']} - ${row['nama_surveyor']} akan dihapus. Surveyor yang sudah dipakai transaksi tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await MasterDataService.deleteSurveyor(row['id'].toString());
      if (!mounted) return;
      _notice('Master surveyor berhasil dihapus.');
      _load();
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> initial) async {
    var row = initial;
    try {
      row = await MasterDataService.getSurveyor(initial['id'].toString());
    } catch (_) {
      // Tetap tampilkan data daftar sebagai cadangan.
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SurveyorDetailSheet(
        record: row,
        canUpdate: _can('update'),
        canDelete: _can('delete'),
        onEdit: () {
          Navigator.pop(sheetContext);
          _openForm(row);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _delete(row);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _rows.where(_active).length;
    final accounts = _rows.fold<int>(
      0,
      (total, row) => total + _usersCount(row),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Master Surveyor',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _can('create')
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add_rounded),
              label: Text('Tambah Surveyor'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari ID, nama, email, atau telepon...',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          _load();
                        },
                        icon: Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFD9E3D7)),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    value: '${_rows.length}',
                    label: 'Surveyor',
                    icon: Icons.fact_check_rounded,
                    color: _green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    value: '$active',
                    label: 'Aktif',
                    icon: Icons.check_circle_rounded,
                    color: _gold,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    value: '$accounts',
                    label: 'Akun',
                    icon: Icons.manage_accounts_rounded,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final option in [
                  ('semua', 'Semua'),
                  ('aktif', 'Aktif'),
                  ('nonaktif', 'Nonaktif'),
                ]) ...[
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: _status == option.$1,
                    onSelected: (_) => setState(() => _status = option.$1),
                    selectedColor: Color(0xFFDCEED7),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _status == option.$1 ? _green : _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 42, color: _green),
              SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 14),
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
    final rows = _visibleRows;
    if (rows.isEmpty) {
      return Center(child: Text('Data surveyor tidak ditemukan.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(18, 2, 18, 96),
        itemCount: rows.length,
        separatorBuilder: (_, _) => SizedBox(height: 10),
        itemBuilder: (_, index) {
          final row = rows[index];
          final active = _active(row);
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDetail(row),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F3E4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.fact_check_rounded,
                        color: _green,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['nama_surveyor']?.toString() ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            row['legal_number']?.toString() ?? '-',
                            style: TextStyle(
                              color: Color(0xFFA66F00),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '${row['phone_surveyor'] ?? '-'}  \u2022  ${_usersCount(row)} akun',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF66756D),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(active ? 'Aktif' : 'Nonaktif'),
                      backgroundColor: active
                          ? Color(0xFFE2F2DD)
                          : Color(0xFFFFE4DF),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: active ? _green : Color(0xFFB3261E),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey),
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

class _SurveyorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? record;

  const _SurveyorFormSheet({this.record});

  @override
  State<_SurveyorFormSheet> createState() => _SurveyorFormSheetState();
}

class _SurveyorFormSheetState extends State<_SurveyorFormSheet> {
  static const _green = Color(0xFF1F7A2E);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _legalNumber;
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _inactiveReason;
  late DateTime _activeDate;
  late String _status;
  final Set<int> _userIds = {};
  List<Map<String, dynamic>> _users = [];
  String? _referenceError;
  bool _loadingUsers = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _legalNumber = TextEditingController(
      text: record?['legal_number']?.toString() ?? '',
    );
    _name = TextEditingController(
      text: record?['nama_surveyor']?.toString() ?? '',
    );
    _email = TextEditingController(
      text: record?['email_surveyor']?.toString() ?? '',
    );
    _phone = TextEditingController(
      text: record?['phone_surveyor']?.toString() ?? '',
    );
    _inactiveReason = TextEditingController(
      text: record?['inactive_reason']?.toString() ?? '',
    );
    _status =
        {
          'inactive',
          'nonaktif',
          '0',
        }.contains(record?['status']?.toString().toLowerCase())
        ? 'inactive'
        : 'active';
    _activeDate =
        DateTime.tryParse(record?['active_date']?.toString() ?? '') ??
        DateTime.now();
    for (final user in (record?['users'] as List? ?? [])) {
      if (user is Map && user['id'] != null) {
        final id = int.tryParse(user['id'].toString());
        if (id != null) _userIds.add(id);
      }
    }
    _loadUsers();
  }

  @override
  void dispose() {
    _legalNumber.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _inactiveReason.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _referenceError = null;
    });
    try {
      final users = await MasterDataService.surveyorUserReferences();
      if (mounted) setState(() => _users = users);
    } catch (error) {
      if (mounted) {
        setState(() {
          _referenceError = error.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _activeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _activeDate = date);
  }

  Future<void> _pickUsers() async {
    if (_loadingUsers || _referenceError != null) return;
    final selected = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserPickerSheet(
        users: _users,
        selectedIds: _userIds,
        currentSurveyorId: widget.record?['id']?.toString(),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _userIds
          ..clear()
          ..addAll(selected);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await MasterDataService.saveSurveyor({
        'legal_number': _legalNumber.text.trim().toUpperCase(),
        'nama_surveyor': _name.text.trim(),
        'user_ids': _userIds.toList(),
        'email_surveyor': _email.text.trim().isEmpty
            ? null
            : _email.text.trim(),
        'phone_surveyor': _phone.text.trim().isEmpty
            ? null
            : _phone.text.trim(),
        'status': _status,
        'active_date': _date(_activeDate),
        'inactive_reason': _status == 'inactive'
            ? _inactiveReason.text.trim()
            : null,
      }, id: widget.record?['id']?.toString());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFFB3261E),
          content: Text(
            error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFCAD5C9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    widget.record == null ? 'Tambah Surveyor' : 'Ubah Surveyor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Lengkapi identitas, user account, dan status surveyor.',
                    style: TextStyle(color: Color(0xFF66756D)),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _legalNumber,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Surveyor ID *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Surveyor ID wajib diisi'
                        : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nama lengkap *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama lengkap wajib diisi'
                        : null,
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: _pickUsers,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'User Account',
                        prefixIcon: Icon(Icons.manage_accounts_rounded),
                        suffixIcon: _loadingUsers
                            ? Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Icon(Icons.search_rounded),
                      ),
                      child: Text(
                        _userIds.isEmpty
                            ? 'Cari dan pilih user account'
                            : '${_userIds.length} user account dipilih',
                        style: TextStyle(
                          color: _userIds.isEmpty
                              ? Color(0xFF66756D)
                              : Color(0xFF183C32),
                          fontWeight: _userIds.isEmpty
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_referenceError != null) ...[
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _referenceError!,
                            style: TextStyle(
                              color: Color(0xFFB3261E),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadUsers,
                          child: Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Surveyor',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())
                          ? null
                          : 'Format email tidak valid';
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'No HP/WA Surveyor',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: 'Status *',
                      prefixIcon: Icon(Icons.toggle_on_rounded),
                    ),
                    items: [
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Nonaktif'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'active'),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Aktif Per Tanggal *',
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                        suffixIcon: Icon(Icons.edit_calendar_rounded),
                      ),
                      child: Text(
                        _date(_activeDate),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_status == 'inactive') ...[
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _inactiveReason,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Alasan Nonaktif *',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      validator: (value) =>
                          _status == 'inactive' &&
                              (value == null || value.trim().isEmpty)
                          ? 'Alasan nonaktif wajib diisi'
                          : null,
                    ),
                  ],
                  SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context, false),
                          child: Text('Batal'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _saving
                              ? SizedBox.square(
                                  dimension: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.save_rounded),
                          label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final Set<int> selectedIds;
  final String? currentSurveyorId;

  const _UserPickerSheet({
    required this.users,
    required this.selectedIds,
    required this.currentSurveyorId,
  });

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  late final Set<int> _selected = {...widget.selectedIds};
  String _query = '';

  Map<String, dynamic>? _otherAssignment(Map<String, dynamic> user) {
    for (final assignment in (user['surveyor_accounts'] as List? ?? [])) {
      if (assignment is Map &&
          assignment['id']?.toString() != widget.currentSurveyorId) {
        return assignment.cast<String, dynamic>();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase().trim();
    final users = query.isEmpty
        ? widget.users
        : widget.users.where((user) {
            final value =
                '${user['id'] ?? ''} ${user['name'] ?? ''} ${user['email'] ?? ''}'
                    .toLowerCase();
            return value.contains(query);
          }).toList();
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .5,
      maxChildSize: .94,
      expand: false,
      builder: (_, controller) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFCAD5C9),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pilih User Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: Text('Selesai (${_selected.length})'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau email (contains)...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? Center(child: Text('User account tidak ditemukan.'))
                  : ListView.separated(
                      controller: controller,
                      padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => Divider(height: 1),
                      itemBuilder: (_, index) {
                        final user = users[index];
                        final id = int.tryParse(user['id'].toString());
                        final other = _otherAssignment(user);
                        final disabled = other != null;
                        final selected = id != null && _selected.contains(id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: disabled || id == null
                              ? null
                              : (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selected.add(id);
                                    } else {
                                      _selected.remove(id);
                                    }
                                  });
                                },
                          secondary: CircleAvatar(
                            backgroundColor: Color(0xFFE8F3E4),
                            child: Text(
                              (user['name']?.toString().trim().isNotEmpty ==
                                          true
                                      ? user['name'].toString().trim()[0]
                                      : 'U')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Color(0xFF1F7A2E),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name']?.toString() ?? '-',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            disabled
                                ? '${user['email'] ?? '-'}\nTerhubung ke ${other['legal_number'] ?? other['nama_surveyor'] ?? 'surveyor lain'}'
                                : '${user['email'] ?? '-'}  \u2022  ${user['role'] ?? '-'}',
                          ),
                          isThreeLine: disabled,
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurveyorDetailSheet extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SurveyorDetailSheet({
    required this.record,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = {
      'active',
      'aktif',
      '1',
    }.contains(record['status']?.toString().toLowerCase());
    final users = (record['users'] as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .5,
      maxChildSize: .95,
      expand: false,
      builder: (_, controller) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFCAD5C9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F1DF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF1F7A2E),
                    size: 31,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['nama_surveyor']?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        record['legal_number']?.toString() ?? '-',
                        style: TextStyle(
                          color: Color(0xFFA66F00),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(active ? 'Aktif' : 'Nonaktif'),
                  backgroundColor: active
                      ? Color(0xFFE2F2DD)
                      : Color(0xFFFFE4DF),
                  side: BorderSide.none,
                ),
              ],
            ),
            SizedBox(height: 20),
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: record['email_surveyor']?.toString() ?? '-',
            ),
            SizedBox(height: 8),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'No HP/WA',
              value: record['phone_surveyor']?.toString() ?? '-',
            ),
            SizedBox(height: 8),
            _InfoTile(
              icon: Icons.calendar_month_rounded,
              label: 'Periode status',
              value:
                  'Aktif: ${record['active_date'] ?? '-'}${active ? '' : '  \u2022  Nonaktif: ${record['inactive_date'] ?? '-'}'}',
            ),
            if (!active &&
                record['inactive_reason']?.toString().trim().isNotEmpty ==
                    true) ...[
              SizedBox(height: 8),
              _InfoTile(
                icon: Icons.notes_rounded,
                label: 'Alasan nonaktif',
                value: record['inactive_reason'].toString(),
              ),
            ],
            SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'USER ACCOUNT SURVEYOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                      color: Color(0xFF66756D),
                    ),
                  ),
                ),
                Text(
                  '${users.length} akun',
                  style: TextStyle(
                    color: Color(0xFF1F7A2E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (users.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Belum ada user account yang terhubung.'),
              )
            else
              for (final user in users)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFE8F3E4),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF1F7A2E),
                    ),
                  ),
                  title: Text(
                    user['name']?.toString() ?? '-',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${user['email'] ?? '-'}  \u2022  ${user['role'] ?? '-'}',
                  ),
                ),
            if (canUpdate || canDelete) ...[
              SizedBox(height: 22),
              Row(
                children: [
                  if (canDelete)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFFB3261E),
                        ),
                        icon: Icon(Icons.delete_outline_rounded),
                        label: Text('Hapus'),
                      ),
                    ),
                  if (canDelete && canUpdate) SizedBox(width: 12),
                  if (canUpdate)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Color(0xFF1F7A2E),
                        ),
                        icon: Icon(Icons.edit_rounded),
                        label: Text('Ubah'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFFE3EAE0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF1F7A2E), size: 21),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Color(0xFF66756D)),
                ),
                Text(value, style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFFE6ECE3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Color(0xFF66756D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
