import 'package:flutter/material.dart';

import '../models/item_category_model.dart';
import '../services/item_category_service.dart';

class ItemCategoryDetailPage extends StatefulWidget {
  final ItemCategoryModel category;

  const ItemCategoryDetailPage({super.key, required this.category});

  @override
  State<ItemCategoryDetailPage> createState() => _ItemCategoryDetailPageState();
}

class _ItemCategoryDetailPageState extends State<ItemCategoryDetailPage> {
  static const _ink = Color(0xFF183C32);
  static const _green = Color(0xFF1F7A2E);
  static const _gold = Color(0xFFE0A800);

  final _searchController = TextEditingController();
  Map<String, dynamic>? _category;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ItemCategoryService.detail(widget.category.id);
    if (!mounted) return;
    if (result['success'] != true || result['data'] is! Map) {
      setState(() {
        _loading = false;
        _error =
            result['message']?.toString() ??
            'Gagal memuat detail kategori item.';
      });
      return;
    }

    final category = Map<String, dynamic>.from(result['data'] as Map);
    final rawItems = category['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    setState(() {
      _category = category;
      _items = items;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) {
      final code = (item['kode_item'] ?? item['code'] ?? '').toString();
      final name = (item['nama_item'] ?? item['name'] ?? '').toString();
      final barcode = (item['barcode'] ?? '').toString();
      final text = '$code $name $barcode'.toLowerCase();
      return text.contains(query);
    }).toList();
  }

  String _nestedName(
    Map<String, dynamic> item,
    List<String> keys,
    List<String> nameKeys,
  ) {
    for (final key in keys) {
      final nested = item[key];
      if (nested is Map) {
        for (final nameKey in nameKeys) {
          final value = nested[nameKey];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
      } else if (nested != null && nested.toString().trim().isNotEmpty) {
        return nested.toString().trim();
      }
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final name = (_category?['category_name'] ?? widget.category.name)
        .toString();
    final code = (_category?['category_code'] ?? widget.category.code)
        .toString();
    final status =
        (_category?['status'] ??
                (widget.category.isActive ? 'aktif' : 'nonaktif'))
            .toString();
    final isActive = [
      'aktif',
      'active',
      '1',
      'true',
    ].contains(status.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Kategori Item',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF173F32), Color(0xFF286246)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.category_rounded,
                                color: Color(0xFFFFD75E),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$code \u2022 ${isActive ? 'Aktif' : 'Nonaktif'}',
                                    style: const TextStyle(
                                      color: Color(0xFFD5E3DC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_items.length} item',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari kode atau nama item...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE1E8DF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_filteredItems.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('Belum ada item dalam kategori ini.'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverList.separated(
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final statusStr = (item['status'] ?? 'aktif')
                              .toString()
                              .toLowerCase();
                          final itemActive = [
                            'aktif',
                            'active',
                            '1',
                            'true',
                          ].contains(statusStr);
                          final unitName = _nestedName(
                            item,
                            const ['unit', 'satuan', 'master_unit'],
                            const ['nama_satuan', 'kode_satuan', 'name'],
                          );
                          final warehouseName = _nestedName(
                            item,
                            const [
                              'warehouse',
                              'gudang',
                              'default_warehouse',
                              'master_warehouse',
                            ],
                            const ['warehouse_name', 'warehouse_code', 'name'],
                          );

                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: itemActive
                                    ? const Color(0xFFE5F2E7)
                                    : const Color(0xFFF0F1EF),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: itemActive ? _green : Colors.black45,
                                ),
                              ),
                              title: Text(
                                '${item['nama_item'] ?? item['name'] ?? '-'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${item['kode_item'] ?? '-'}\nSatuan: $unitName \u2022 Gudang: $warehouseName',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              isThreeLine: true,
                            ),
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
