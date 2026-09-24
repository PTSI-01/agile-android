import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/menu_item_model.dart';
import 'supplier/supplier_list_page.dart';
import 'supplier/supplier_group_page.dart';
import 'master_data_page.dart';
import 'buyer_page.dart';
import 'purchase_page.dart';

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
      // Superadmin melihat seluruh katalog modul; hak akses aksi tetap dijaga backend.
      final supportedItems = group.items;
      if (supportedItems.isEmpty) return null;
      return MenuGroupItem(
        id: group.id,
        title: group.title,
        subtitle: group.subtitle,
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
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: filtered.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .86),
                      itemBuilder: (context, index) => _buildCompactGroupCard(context, filtered[index]),
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

  Widget _buildCompactGroupCard(BuildContext context, MenuGroupItem group) {
    final accent = group.id == 'master_data'
        ? const Color(0xFFA66F00)
        : group.id == 'pembelian'
            ? const Color(0xFF1F7A2E)
            : const Color(0xFF183C32);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: group.id == 'master_data' ? const Color(0xFFFFF8DE) : group.id == 'pembelian' ? const Color(0xFFE8F5E9) : const Color(0xFFF1F4F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: accent.withValues(alpha: .25))),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showModalBottomSheet(
          context: context,
          showDragHandle: true,
          backgroundColor: Colors.white,
          builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
          Text(group.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF183C32))),
            const SizedBox(height: 10),
            ...group.items.map((item) => ListTile(
              leading: Icon(item.icon, color: group.color),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () { Navigator.pop(context); if (item.id == 'pb_transaksi' || item.route == '/pembelian/transaksi') Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasePage())); },
            )),
          ])),
        ),
        child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), child: Icon(group.icon, color: accent, size: 21)),
          const Spacer(),
          Text(group.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF183C32))),
          const SizedBox(height: 3),
          Text('${group.items.length} menu', style: const TextStyle(fontSize: 10, color: Color(0xFF7D8983))),
          const SizedBox(height: 4),
          Align(alignment: Alignment.bottomRight, child: Icon(Icons.arrow_forward_rounded, size: 16, color: accent)),
        ])),
      ),
    );
  }
}
