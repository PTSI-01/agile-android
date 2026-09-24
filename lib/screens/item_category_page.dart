import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item_category_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/item_category_service.dart';

class ItemCategoryPage extends StatefulWidget {
  const ItemCategoryPage({super.key});

  @override
  State<ItemCategoryPage> createState() => _ItemCategoryPageState();
}

class _ItemCategoryPageState extends State<ItemCategoryPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ItemCategoryModel> _items = [];
  bool _loading = true;
  String? _error;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _load();
    AuthService.getCurrentUser().then((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  bool _can(String action) =>
      _user?.permissions['item_category.${action.toLowerCase()}'] ??
      (_user?.role == 'superadmin');

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
    final result = await ItemCategoryService.list(search: _searchController.text);
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

  Future<void> _openForm([ItemCategoryModel? item]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ItemCategoryForm(item: item),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(ItemCategoryModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kategori item?'),
        content: Text('Kategori "${item.name}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD14942),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ItemCategoryService.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (result['success'] == true
                  ? 'Berhasil dihapus'
                  : 'Gagal menghapus'),
        ),
      ),
    );
    if (result['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const accent = Color(0xFFA66F00);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kategori Item',
          style: TextStyle(fontWeight: FontWeight.w800, color: ink),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: _can('update')
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Kategori'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kode atau nama kategori...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(accent, ink)),
        ],
      ),
    );
  }

  Widget _buildBody(Color accent, Color ink) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Belum ada kategori item'));
    }
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
              leading: CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                item.name,
                style: TextStyle(fontWeight: FontWeight.w700, color: ink),
              ),
              subtitle: Text('${item.code} • ${item.isActive ? 'Aktif' : 'Nonaktif'}'),
              onTap: _can('update') ? () => _openForm(item) : null,
              trailing: (_can('update') || _can('delete'))
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(item);
                        if (value == 'delete') _delete(item);
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
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _ItemCategoryForm extends StatefulWidget {
  final ItemCategoryModel? item;
  const _ItemCategoryForm({this.item});

  @override
  State<_ItemCategoryForm> createState() => _ItemCategoryFormState();
}

class _ItemCategoryFormState extends State<_ItemCategoryForm> {
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
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'category_code': _code.text.trim(),
      'category_name': _name.text.trim(),
      'status': _active ? 1 : 0,
    };
    final result = widget.item == null
        ? await ItemCategoryService.create(data)
        : await ItemCategoryService.update(widget.item!.id, data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Gagal menyimpan data'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          widget.item == null ? 'Tambah Kategori Item' : 'Edit Kategori Item',
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Kode kategori'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Kode wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama kategori'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama wajib diisi'
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Status aktif'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      );
}
