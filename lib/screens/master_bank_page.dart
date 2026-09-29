import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/master_data_service.dart';
import 'master_bank_detail_page.dart';

class MasterBankPage extends StatefulWidget {
  const MasterBankPage({super.key});
  @override
  State<MasterBankPage> createState() => _MasterBankPageState();
}

class _MasterBankPageState extends State<MasterBankPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  UserModel? _user;
  bool _loading = true;
  String? _error;

  bool _can(String action) =>
      _user?.role?.toLowerCase() == 'superadmin' ||
      _user?.permissions['master_bank.$action'] == true;

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
      _user = await AuthService.refreshCurrentUser();
      final rows = await MasterDataService.banks(search: _search.text);
      if (mounted) {
        setState(() {
          _items = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? bank]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MasterBankFormDialog(bank: bank),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bank == null
                ? 'Master bank berhasil ditambahkan.'
                : 'Master bank berhasil diperbarui.',
          ),
        ),
      );
      await _load();
    }
  }

  Future<void> _delete(Map<String, dynamic> bank) async {
    try {
      await MasterDataService.deleteBank(bank['id'].toString());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Master Bank',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: _can('create')
        ? FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Bank'),
          )
        : null,
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Cari kode atau nama bank...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  _search.clear();
                  _load();
                },
                icon: const Icon(Icons.clear),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final bank = _items[i];
                      final active = bank['status'] == 'active';
                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MasterBankDetailPage(
                                bankId: bank['id'].toString(),
                              ),
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: active
                                ? const Color(0xFFE5F2E4)
                                : const Color(0xFFE8E8E8),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: active
                                  ? const Color(0xFF1B5E20)
                                  : Colors.black54,
                            ),
                          ),
                          title: Text(
                            '${bank['bank_code'] ?? '-'} • ${bank['bank_name'] ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${active ? 'Aktif' : 'Nonaktif'} • ${bank['bank_accounts_count'] ?? 0} rekening',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _edit(bank);
                              if (v == 'delete') _delete(bank);
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
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}

class _MasterBankFormDialog extends StatefulWidget {
  final Map<String, dynamic>? bank;

  const _MasterBankFormDialog({this.bank});

  @override
  State<_MasterBankFormDialog> createState() => _MasterBankFormDialogState();
}

class _MasterBankFormDialogState extends State<_MasterBankFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late String _status;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.bank != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.bank?['bank_code']?.toString() ?? '',
    );
    _nameController = TextEditingController(
      text: widget.bank?['bank_name']?.toString() ?? '',
    );
    _status = widget.bank?['status']?.toString() == 'inactive'
        ? 'inactive'
        : 'active';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await MasterDataService.saveBank({
        'bank_code': _codeController.text.trim().toUpperCase(),
        'bank_name': _nameController.text.trim(),
        'status': _status,
      }, id: widget.bank?['id']?.toString());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F7A2E);
    const ink = Color(0xFF183C32);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_rounded, color: green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Master Bank' : 'Tambah Master Bank',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lengkapi data bank untuk supplier',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7D8983)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0B5B0)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB3261E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _codeController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode Bank *',
                    hintText: 'Contoh: BBRI',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kode bank wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bank *',
                    hintText: 'Contoh: Bank BRI',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama bank wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Nonaktif'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value ?? 'active'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}
