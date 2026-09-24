import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/menu_item_model.dart';
import 'supplier/supplier_list_page.dart';
import 'supplier/supplier_group_page.dart';
import 'master_data_page.dart';
import 'buyer_page.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  final TextEditingController _searchController = TextEditingController();
  MenuCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuGroupItem> get _filteredGroups {
    return MenuData.menuGroups.map((group) {
      // Tampilkan hanya modul yang sudah benar-benar tersambung ke API.
      final supportedItems = group.items
          .where((item) => const {'md_supplier', 'md_supplier_group', 'md_buyer', 'md_inventory', 'md_warehouse', 'md_surveyor', 'md_wilayah'}.contains(item.id))
          .toList();
      if (supportedItems.isEmpty) return null;
      return MenuGroupItem(
        id: group.id,
        title: group.title,
        subtitle: 'Master Supplier yang tersambung ke Laravel',
        icon: group.icon,
        color: group.color,
        lightColor: group.lightColor,
        category: group.category,
        items: supportedItems,
        isFeatured: group.isFeatured,
      );
    }).whereType<MenuGroupItem>().where((group) {
      final matchesCategory = _selectedCategory == null ||
          group.category == _selectedCategory;

      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase();
      final matchesGroup = group.title.toLowerCase().contains(query) ||
          group.subtitle.toLowerCase().contains(query);

      final matchesSubItem = group.items.any((item) =>
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query));

      return matchesGroup || matchesSubItem;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);

    final filtered = _filteredGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Katalog Modul Menu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Cari menu (Supplier, QC, Timbangan, dll)...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: green, width: 1.5),
                  ),
                ),
              ),
            ),

            // 2. CATEGORY CHIPS
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _categoryChip('Semua', null),
                  _categoryChip('Master Data', MenuCategory.masterData),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. LIST OF MODULES
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Menu "$_searchQuery" tidak ditemukan',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Coba kata kunci lain atau reset filter kategori.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final group = filtered[index];
                        return _buildGroupCard(context, group);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, MenuCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1F7A2E),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF183C32),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF1F7A2E)
                : const Color(0xFFE9EDE5),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, MenuGroupItem group) {
    // Filter sub items if search is active
    final visibleItems = _searchQuery.isEmpty
        ? group.items
        : group.items.where((item) {
            final q = _searchQuery.toLowerCase();
            return item.title.toLowerCase().contains(q) ||
                item.description.toLowerCase().contains(q);
          }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EDE5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _searchQuery.isNotEmpty,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(group.icon, color: group.color, size: 22),
          ),
          title: Text(
            group.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF183C32),
            ),
          ),
          subtitle: Text(
            '${group.items.length} sub-modul • ${group.subtitle}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7D8983),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1, color: Color(0xFFF0F3ED)),
            const SizedBox(height: 10),
            ...visibleItems.map(
              (item) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: group.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 18, color: group.color),
                ),
                title: Row(
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: (item.badgeColor ?? group.color)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: item.badgeColor ?? group.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  item.description,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.black38,
                ),
                onTap: () {
                  if (item.id == 'md_supplier' || item.route == '/master-data/supplier') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupplierListPage(),
                      ),
                    );
                  } else if (item.id == 'md_supplier_group') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupplierGroupPage(),
                      ),
                    );
                  } else if (item.id == 'md_buyer') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerPage()));
                  } else if (item.id == 'md_inventory' || item.id == 'md_warehouse' || item.id == 'md_surveyor' || item.id == 'md_wilayah') {
                    final config = {
                      'md_buyer': ('buyer', 'Master Buyer'),
                      'md_inventory': ('item', 'Master Item'),
                      'md_warehouse': ('warehouse', 'Master Gudang'),
                      'md_surveyor': ('surveyor', 'Master Surveyor'),
                      'md_wilayah': ('wilayah', 'Master Wilayah'),
                    }[item.id]!;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDataPage(type: config.$1, title: config.$2)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Membuka ${item.title}...'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: group.color,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
