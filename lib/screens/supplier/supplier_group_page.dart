import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/supplier_model.dart';
import '../../services/supplier_group_service.dart';

class SupplierGroupPage extends StatefulWidget {
  const SupplierGroupPage({super.key});

  @override
  State<SupplierGroupPage> createState() => _SupplierGroupPageState();
}

class _SupplierGroupPageState extends State<SupplierGroupPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<SupplierGroupModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await SupplierGroupService.list(search: _searchController.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.items;
      _error = result.success ? null : result.message;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openForm([SupplierGroupModel? item]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _SupplierGroupForm(item: item),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(SupplierGroupModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus supplier group?'),
        content: Text('Group "${item.name}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD14942)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await SupplierGroupService.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? (result['success'] == true ? 'Berhasil dihapus' : 'Gagal menghapus'))),
    );
    if (result['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Group', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Group'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kode atau nama group...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(onPressed: () { _searchController.clear(); _load(); }, icon: const Icon(Icons.clear_rounded)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE9EDE5))),
              ),
            ),
          ),
          Expanded(child: _buildBody(green, ink)),
        ],
      ),
    );
  }

  Widget _buildBody(Color green, Color ink) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba Lagi')),
      ]));
    }
    if (_items.isEmpty) return const Center(child: Text('Belum ada supplier group'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final item = _items[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: green.withValues(alpha: 0.12), child: Text('${index + 1}', style: TextStyle(color: green, fontWeight: FontWeight.bold))),
              title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
              subtitle: Text('${item.code} • ${item.isActive ? 'Aktif' : 'Nonaktif'}'),
              onTap: () => _openForm(item),
              trailing: PopupMenuButton<String>(
                onSelected: (value) { if (value == 'edit') _openForm(item); if (value == 'delete') _delete(item); },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SupplierGroupForm extends StatefulWidget {
  final SupplierGroupModel? item;
  const _SupplierGroupForm({this.item});

  @override
  State<_SupplierGroupForm> createState() => _SupplierGroupFormState();
}

class _SupplierGroupFormState extends State<_SupplierGroupForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.item?.code ?? '');
    _name = TextEditingController(text: widget.item?.name ?? '');
    _active = widget.item?.isActive ?? true;
  }

  @override
  void dispose() { _code.dispose(); _name.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {'group_code': _code.text.trim(), 'group_name': _name.text.trim(), 'status': _active ? 1 : 0};
    final result = widget.item == null
        ? await SupplierGroupService.create(data)
        : await SupplierGroupService.update(widget.item!.id, data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Gagal menyimpan data')));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Tambah Supplier Group' : 'Edit Supplier Group'),
    content: Form(
      key: _formKey,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Kode group'), validator: (value) => value == null || value.trim().isEmpty ? 'Kode wajib diisi' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nama group'), validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi' : null),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Status aktif'), value: _active, onChanged: (value) => setState(() => _active = value)),
      ]),
    ),
    actions: [
      TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
      FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan')),
    ],
  );
}
