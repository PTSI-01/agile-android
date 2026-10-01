import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';
import 'supplier/supplier_list_page.dart';
import 'supplier/supplier_group_page.dart';
import 'buyer_page.dart';
import 'buyer_group_page.dart';
import 'master_bank_page.dart';
import 'master_data_page.dart';
import 'master_item_page.dart';
import 'master_unit_page.dart';
import 'unit_conversion_page.dart';
import 'price_list_item_page.dart';
import 'item_category_page.dart';
import 'purchase_page.dart';
import 'purchase_target_page.dart';
import 'province_page.dart';
import 'city_page.dart';
import 'district_page.dart';
import 'village_page.dart';

class ModulesPage extends StatefulWidget {
  final DashboardData? dashboard;
  const ModulesPage({super.key, this.dashboard});
  @override
  State<ModulesPage> createState() => ModulesPageState();
}

class ModulesPageState extends State<ModulesPage> {
  static const _masterWilayahIconUrl =
      'https://img.icons8.com/3d-fluency/94/map-marker.png';
  static const _supplierGroupIconUrl =
      'https://img.icons8.com/3d-fluency/94/group-task.png';
  static const _supplierIconUrl =
      'https://img.icons8.com/3d-fluency/94/supplier.png';
  static const _masterSupplierIconUrl =
      'https://img.icons8.com/3d-fluency/94/conference-call--v1.png';
  static const _masterBankIconUrl =
      'https://img.icons8.com/3d-fluency/94/bank-cards.png';
  static const _buyerIconUrl =
      'https://img.icons8.com/3d-fluency/94/salary-male.png';
  static const _buyerGroupIconUrl =
      'https://img.icons8.com/3d-fluency/94/user-group-man-woman--v4.png';
  static const _masterBuyerIconUrl =
      'https://img.icons8.com/3d-fluency/94/cash-in-hand.png';
  static const _purchaseTargetIconUrl =
      'https://img.icons8.com/3d-fluency/94/purposeful-man.png';
  static const _masterDataIconUrl =
      'https://img.icons8.com/3d-fluency/94/data-configuration.png';
  static const _masterSurveyorIconUrl =
      'https://img.icons8.com/3d-fluency/94/inspection.png';
  static const _surveyorIconUrl =
      'https://img.icons8.com/3d-fluency/94/apply.png';
  static const _masterItemIconUrl =
      'https://img.icons8.com/3d-fluency/94/open-box.png';
  static const _itemCategoryIconUrl =
      'https://img.icons8.com/3d-fluency/94/pallet.png';
  static const _itemPriceListIconUrl =
      'https://img.icons8.com/3d-fluency/94/bonds.png';
  static const _unitIconUrl =
      'https://img.icons8.com/3d-fluency/94/tape-measure.png';
  static const _unitConversionIconUrl =
      'https://img.icons8.com/3d-fluency/94/construction-carpenter-ruler.png';
  static const _warehouseIconUrl =
      'https://img.icons8.com/3d-fluency/94/hangar.png';
  static const _siteIconUrl =
      'https://img.icons8.com/3d-fluency/94/track-order.png';
  static const _binIconUrl = 'https://img.icons8.com/3d-fluency/94/package.png';
  static const _provinceIconUrl =
      'https://img.icons8.com/3d-fluency/94/order-delivered.png';
  static const _cityIconUrl =
      'https://img.icons8.com/3d-fluency/94/previous--location.png';
  static const _districtIconUrl =
      'https://img.icons8.com/3d-fluency/94/next-location.png';
  static const _villageIconUrl =
      'https://img.icons8.com/3d-fluency/94/place-marker.png';
  static const _purchaseIconUrl =
      'https://img.icons8.com/3d-fluency/94/bill.png';
  static const _legalNumberIconUrl =
      'https://img.icons8.com/3d-fluency/94/legal-document.png';

  final search = TextEditingController();
  final _pageController = PageController();
  final parents = <DashboardMenuModel>[];
  String query = '';
  int _currentPage = 0;

  static const _itemsPerPage = 24;

  bool handleBack() {
    if (parents.isNotEmpty) {
      setState(() {
        parents.removeLast();
        query = '';
        search.clear();
        _currentPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      return true;
    }
    return false;
  }

  void openRootModule(DashboardMenuModel module) {
    setState(() {
      parents
        ..clear()
        ..addAll(module.children.isEmpty ? const [] : [module]);
      query = '';
      search.clear();
      _currentPage = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    if (module.children.isEmpty) _open(module);
  }

  List<DashboardMenuModel> get items {
    final s = parents.isEmpty
        ? (widget.dashboard?.menus ?? const <DashboardMenuModel>[])
        : parents.last.children;
    if (query.isEmpty) return s;
    final q = query.toLowerCase();
    return s
        .where(
          (x) =>
              x.title.toLowerCase().contains(q) ||
              x.code.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    search.dispose();
    _pageController.dispose();
    super.dispose();
  }

  IconData _icon(DashboardMenuModel x) {
    final v = '${x.icon} ${x.title}'.toLowerCase();
    if (v.contains('supplier')) return Icons.people_alt_rounded;
    if (v.contains('buyer')) return Icons.badge_rounded;
    if (v.contains('pembelian')) return Icons.shopping_bag_rounded;
    if (v.contains('penerimaan')) return Icons.scale_rounded;
    if (v.contains('qc') || v.contains('lab')) return Icons.science_rounded;
    if (v.contains('finance')) return Icons.payments_rounded;
    if (v.contains('laporan')) return Icons.analytics_rounded;
    if (v.contains('user')) return Icons.manage_accounts_rounded;
    return Icons.dashboard_customize_rounded;
  }

  bool _isMasterWilayah(DashboardMenuModel x) {
    final value = '${x.code} ${x.title} ${x.url ?? ''}'.toLowerCase();
    return value.contains('master wilayah') ||
        value.contains('master_wilayah') ||
        value.contains('master-data/wilayah');
  }

  String? _networkIconUrl(DashboardMenuModel x) {
    final value = '${x.code} ${x.title} ${x.url ?? ''}'.toLowerCase();
    final identity = '${x.code} ${x.title}'.toLowerCase();
    if (_isMasterWilayah(x)) return _masterWilayahIconUrl;
    if (value.contains('legal number') ||
        value.contains('legal_number') ||
        value.contains('legal-number')) {
      return _legalNumberIconUrl;
    }
    if (value.contains('supplier group') ||
        value.contains('supplier_group') ||
        value.contains('supplier-group')) {
      return _supplierGroupIconUrl;
    }
    if (value.contains('master supplier') ||
        value.contains('master_supplier') ||
        value.contains('master-data/supplier')) {
      return _masterSupplierIconUrl;
    }
    if (value.contains('master bank') ||
        value.contains('master_bank') ||
        value.contains('master-bank') ||
        value.contains('master-data/bank')) {
      return _masterBankIconUrl;
    }
    if (value.contains('supplier')) return _supplierIconUrl;
    if (value.contains('buyer group') ||
        value.contains('buyer_group') ||
        value.contains('buyer-group') ||
        value.contains('purchasing group') ||
        value.contains('purchasing_group') ||
        value.contains('purchasing-group')) {
      return _buyerGroupIconUrl;
    }
    if (value.contains('master buyer') ||
        value.contains('master_buyer') ||
        value.contains('master-buyer') ||
        value.contains('master-data/buyer')) {
      return _masterBuyerIconUrl;
    }
    if (value.contains('target pembelian') ||
        value.contains('target_pembelian') ||
        value.contains('target-pembelian') ||
        value.contains('target po') ||
        value.contains('target_po') ||
        value.contains('target-po')) {
      return _purchaseTargetIconUrl;
    }
    if (value.contains('master surveyor') ||
        value.contains('master_surveyor') ||
        value.contains('master-surveyor') ||
        value.contains('master-data/surveyor')) {
      return _masterSurveyorIconUrl;
    }
    if (value.contains('surveyor')) return _surveyorIconUrl;
    if (value.contains('konversi satuan') ||
        value.contains('konversi_satuan') ||
        value.contains('konversi-satuan') ||
        value.contains('unit conversion') ||
        value.contains('unit_conversion') ||
        value.contains('unit-conversion')) {
      return _unitConversionIconUrl;
    }
    if (value.contains('pricelist item') ||
        value.contains('price list item') ||
        value.contains('item pricelist') ||
        value.contains('item price list') ||
        value.contains('item-price') ||
        value.contains('price-list')) {
      return _itemPriceListIconUrl;
    }
    if (value.contains('kategori item') ||
        value.contains('kategori_item') ||
        value.contains('kategori-item') ||
        value.contains('item category') ||
        value.contains('item_category') ||
        value.contains('item-category')) {
      return _itemCategoryIconUrl;
    }
    if (value.contains('master item') ||
        value.contains('master_item') ||
        value.contains('master-item') ||
        value.contains('master-data/item')) {
      return _masterItemIconUrl;
    }
    if (value.contains('satuan') ||
        value.contains('master unit') ||
        value.contains('master_unit') ||
        value.contains('master-unit')) {
      return _unitIconUrl;
    }
    if (value.contains('master bin') ||
        value.contains('master_bin') ||
        value.contains('master-bin') ||
        RegExp(r'(^|[\s/_-])bin($|[\s/_-])').hasMatch(value)) {
      return _binIconUrl;
    }
    if (value.contains('master site') ||
        value.contains('master_site') ||
        value.contains('master-site') ||
        RegExp(r'(^|[\s/_-])site($|[\s/_-])').hasMatch(value)) {
      return _siteIconUrl;
    }
    if (value.contains('master gudang') ||
        value.contains('master_gudang') ||
        value.contains('master-gudang') ||
        value.contains('gudang') ||
        value.contains('warehouse')) {
      return _warehouseIconUrl;
    }
    if (value.contains('provinsi') || value.contains('province')) {
      return _provinceIconUrl;
    }
    if (value.contains('kabupaten') ||
        value.contains('kota') ||
        RegExp(r'(^|[\s/_-])city($|[\s/_-])').hasMatch(value)) {
      return _cityIconUrl;
    }
    if (value.contains('kecamatan') || value.contains('district')) {
      return _districtIconUrl;
    }
    if (value.contains('kelurahan') ||
        value.contains('desa') ||
        value.contains('village')) {
      return _villageIconUrl;
    }
    if (identity.trim() == 'pembelian' ||
        identity.contains('folder_pembelian') ||
        identity.contains('menu_pembelian') ||
        value.contains('/pembelian/transaksi')) {
      return _purchaseIconUrl;
    }
    if (identity.trim() == 'master data' ||
        identity.contains('folder_master_data') ||
        identity.contains('folder master data')) {
      return _masterDataIconUrl;
    }
    if (value.contains('buyer')) return _buyerIconUrl;
    return null;
  }

  Widget _menuIcon(DashboardMenuModel x, Color color) {
    final iconUrl = _networkIconUrl(x);
    if (iconUrl == null) return Icon(_icon(x), color: color, size: 19);

    return Padding(
      padding: EdgeInsets.all(_isMasterWilayah(x) ? 3 : 2),
      child: CachedNetworkImage(
        imageUrl: iconUrl,
        fit: BoxFit.contain,
        memCacheWidth: 94,
        memCacheHeight: 94,
        fadeInDuration: const Duration(milliseconds: 180),
        errorWidget: (_, _, _) => Icon(_icon(x), color: color, size: 21),
      ),
    );
  }

  Color _color(DashboardMenuModel x) {
    final v = x.title.toLowerCase();
    if (v.contains('pembelian') || v.contains('penerimaan')) {
      return const Color(0xff1f7a2e);
    }
    if (v.contains('master') || v.contains('target')) {
      return const Color(0xffa66f00);
    }
    if (v.contains('finance') || v.contains('user')) {
      return const Color(0xff183c32);
    }
    return const Color(0xff2e7d32);
  }

  void _open(DashboardMenuModel x) {
    if (x.children.isNotEmpty) {
      setState(() {
        parents.add(x);
        query = '';
        search.clear();
        _currentPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      return;
    }
    final u = x.url ?? '';
    final identity = '${x.code} ${x.title} $u'.toLowerCase();
    Widget? p;
    if (u.contains('supplier-group')) {
      p = const SupplierGroupPage();
    } else if (u.contains('supplier')) {
      p = const SupplierListPage();
    } else if (identity.contains('master-target') ||
        identity.contains('target pembelian') ||
        identity.contains('target_pembelian') ||
        identity.contains('target-pembelian') ||
        identity.contains('target po')) {
      p = const PurchaseTargetPage();
    } else if (u.contains('master-buyer')) {
      p = const BuyerPage();
    } else if (u.contains('buyer-group') || u.contains('purchasing-group')) {
      p = const BuyerGroupPage();
    } else if (u.contains('master-bank')) {
      p = const MasterBankPage();
    } else if (u == '/pembelian/transaksi' || u == '/buyer') {
      p = const PurchasePage();
    } else if (identity.contains('master-item-category') ||
        identity.contains('item category') ||
        identity.contains('item_category') ||
        identity.contains('item-category') ||
        identity.contains('kategori item')) {
      p = const ItemCategoryPage();
    } else if (u == '/master-item' ||
        u == '/master-data/item' ||
        x.code.toUpperCase() == 'MASTER_ITEM') {
      p = const MasterItemPage();
    } else if (u == '/master-unit' ||
        u == '/master-data/unit' ||
        x.code.toUpperCase() == 'MASTER_UNIT') {
      p = const MasterUnitPage();
    } else if (u == '/master-unit-conversion' ||
        identity.contains('master_unit_conversion') ||
        identity.contains('konversi satuan') ||
        identity.contains('unit-conversion')) {
      p = const UnitConversionPage();
    } else if (u == '/pricelist-item' ||
        identity.contains('price list item') ||
        identity.contains('pricelist item') ||
        identity.contains('price-list')) {
      p = const PriceListItemPage();
    } else if (u.contains('warehouse')) {
      p = const MasterDataPage(type: 'warehouse', title: 'Master Gudang');
    } else if (u.contains('surveyor')) {
      p = const MasterDataPage(type: 'surveyor', title: 'Master Surveyor');
    } else if (u.contains('wilayah')) {
      p = const ProvincePage();
    } else if (u.contains('provinsi')) {
      p = const ProvincePage();
    } else if (u.contains('kota') ||
        u.contains('kabupaten') ||
        u.contains('city')) {
      p = const CityPage();
    } else if (u.contains('kecamatan') || u.contains('district')) {
      p = const DistrictPage();
    } else if (u.contains('kelurahan') ||
        u.contains('desa') ||
        u.contains('village')) {
      p = const VillagePage();
    }

    if (p != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => p!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${x.title} belum tersedia di Android')),
      );
    }
  }

  void _updateSearch(String value, [StateSetter? updateSheet]) {
    setState(() {
      query = value.trim();
      _currentPage = 0;
    });
    updateSheet?.call(() {});
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  Future<void> _showSearch() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
              ),
              child: Material(
                color: const Color(0xFFF8FBF5),
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD6CC),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: search,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) => _updateSearch(value, updateSheet),
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF1F7A2E),
                          ),
                          suffixIcon: search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    search.clear();
                                    _updateSearch('', updateSheet);
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCE8DB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: Color(0xFF1F7A2E),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          parents.isEmpty ? 'Modul' : parents.last.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: parents.isEmpty
            ? null
            : IconButton(
                onPressed: () => setState(() => parents.removeLast()),
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'modules-search',
        onPressed: _showSearch,
        elevation: 5,
        highlightElevation: 2,
        backgroundColor: const Color(0xFF183C32),
        foregroundColor: const Color(0xFFF7C843),
        shape: const StadiumBorder(),
        icon: Icon(query.isEmpty ? Icons.search_rounded : Icons.filter_alt),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            query.isEmpty ? 'Cari menu' : query,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 88),
                child: Text(
                  'Menu belum tersedia atau belum memiliki hak akses.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _modulePages(),
    );
  }

  Widget _modulePages() {
    final visibleItems = items;
    final pageCount = (visibleItems.length / _itemsPerPage).ceil();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, page) {
              final start = page * _itemsPerPage;
              final end = (start + _itemsPerPage).clamp(0, visibleItems.length);
              final pageItems = visibleItems.sublist(start, end);

              return LayoutBuilder(
                builder: (context, constraints) {
                  const verticalPadding = 12.0;
                  const spacing = 5.0;
                  final extent =
                      ((constraints.maxHeight -
                                  (verticalPadding * 2) -
                                  (spacing * 5)) /
                              6)
                          .clamp(68.0, 94.0);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      10,
                      verticalPadding,
                      10,
                      verticalPadding,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pageItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: extent,
                    ),
                    itemBuilder: (_, index) => _moduleCard(pageItems[index]),
                  );
                },
              );
            },
          ),
        ),
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (index) {
                final active = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: active ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF1F7A2E)
                        : const Color(0xFFCCD6CC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 68),
      ],
    );
  }

  Widget _plainModuleTile(DashboardMenuModel x, Color color) {
    final hasNetworkIcon = _networkIconUrl(x) != null;
    return InkWell(
      onTap: () => _open(x),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasNetworkIcon)
              SizedBox(width: 43, height: 43, child: _menuIcon(x, color))
            else
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.14),
                      color.withValues(alpha: 0.28),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _menuIcon(x, color),
              ),
            const SizedBox(height: 3),
            Text(
              x.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: Color(0xFF183C32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(DashboardMenuModel x) {
    final c = _color(x);
    return _plainModuleTile(x, c);
  }
}
