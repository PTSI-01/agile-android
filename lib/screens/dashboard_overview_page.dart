import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/menu_item_model.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';
import 'buyer_page.dart';
import 'master_data_page.dart';
import 'inventory_location_pages.dart';
import 'supplier/supplier_list_page.dart';
import 'purchase_page.dart';
import 'master_surveyor_page.dart';
import '../services/notification_service.dart';

class DashboardOverviewPage extends StatelessWidget {
  final UserModel? user;
  final DashboardData? dashboard;
  final VoidCallback? onOpenModules;
  final ValueChanged<DashboardMenuModel>? onOpenModule;
  final VoidCallback? onOpenProfile;

  const DashboardOverviewPage({
    super.key,
    this.user,
    this.dashboard,
    this.onOpenModules,
    this.onOpenModule,
    this.onOpenProfile,
  });

  bool _hasMenuAccess(List<DashboardMenuModel> menus, SubMenuItem shortcut) {
    final target = _normalizeRoute(shortcut.route);
    final aliases = _shortcutAliases(shortcut);
    return menus.any((menu) {
      final menuRoute = menu.url == null ? '' : _normalizeRoute(menu.url!);
      final menuCode = menu.code.toLowerCase().trim();
      final menuTitle = menu.title.toLowerCase().trim();
      return menuRoute == target ||
          aliases.contains(menuCode) ||
          aliases.any(menuTitle.contains) ||
          _hasMenuAccess(menu.children, shortcut);
    });
  }

  Set<String> _shortcutAliases(SubMenuItem shortcut) {
    switch (shortcut.id) {
      case 'sc_pembelian':
        return {'sc_pembelian', 'pb_transaksi', 'pembelian', 'purchase'};
      case 'sc_timbangan':
        return {
          'sc_timbangan',
          'pn_timbangan_masuk',
          'timbangan masuk',
          'timbangan masuk (bruto)',
        };
      case 'sc_qc':
        return {'sc_qc', 'qc_incoming', 'qc lab incoming', 'input qc lab'};
      case 'sc_approval':
        return {
          'sc_approval',
          'fn_approval',
          'finance approval',
          'approval transaksi finance',
        };
      case 'sc_supplier':
        return {'sc_supplier', 'md_supplier', 'master supplier', 'supplier'};
      case 'sc_buyer':
        return {'sc_buyer', 'md_buyer', 'master buyer', 'data buyer', 'buyer'};
      case 'sc_item':
        return {'sc_item', 'md_inventory', 'master item', 'data item', 'item'};
      case 'sc_surveyor':
        return {
          'sc_surveyor',
          'md_surveyor',
          'master surveyor',
          'data surveyor',
          'surveyor',
        };
      case 'sc_gudang':
        return {
          'sc_gudang',
          'md_warehouse',
          'master gudang',
          'data gudang',
          'warehouse',
          'gudang',
        };
      case 'sc_laporan':
        return {
          'sc_laporan',
          'lp_pembelian',
          'laporan pembelian',
          'laporan pengadaan',
        };
      default:
        return {shortcut.id, shortcut.title.toLowerCase()};
    }
  }

  String _normalizeRoute(String route) {
    final withoutQuery = route.split(RegExp(r'[?#]')).first;
    final normalized = withoutQuery.replaceFirst(RegExp(r'/$'), '');
    return normalized.isEmpty ? '/' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final supportedShortcuts = dashboard == null
        ? <SubMenuItem>[]
        : MenuData.quickShortcuts
              .where((shortcut) => _hasMenuAccess(dashboard!.menus, shortcut))
              .toList();
    final quickShortcuts = supportedShortcuts.take(7).toList();
    const muted = Color(0xFF7D8983);

    final displayName = user?.name.split(' ').first ?? 'Pengguna';
    final roleName = user?.role ?? 'Sourcing Team';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // 1. TOP BAR
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo_agile.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFD8EFAC),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AGILE JAYA ABADI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'E-Procurement System',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white60 : muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  tooltip: 'Notifikasi',
                  onPressed: () => _showNotifications(context),
                  icon: FutureBuilder<List<Map<String, dynamic>>>(
                    future: NotificationService.list(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      final icon = Icon(
                        Icons.notifications_none_rounded,
                        color: theme.colorScheme.onSurface,
                      );
                      return count > 0
                          ? Badge(
                              label: Text('$count'),
                              child: icon,
                            )
                          : icon;
                    },
                  ),
                ),
                SizedBox(width: 6),
                InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFFE7ECDD),
                    child: Text(
                      user?.initials ?? 'AR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 22),

            // 2. HERO GREETING CARD
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14382E), Color(0xFF235A49)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF14382E).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFD8EFAC).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Color(0xFFD8EFAC),
                            ),
                            SizedBox(width: 5),
                            Text(
                              roleName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD8EFAC),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Musim Panen 2026',
                        style: TextStyle(
                          color: Color(0xFFB5CBC0),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Halo, $displayName! \u{1F44B}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pantau seluruh proses pengadaan gabah, timbangan, uji QC lab, hingga pembayaran finance secara real-time.',
                    style: TextStyle(
                      color: Color(0xFFD5E3DC),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // 3. QUICK ACCESS
            Text(
              'Akses Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                mainAxisExtent: 96,
              ),
              itemCount: quickShortcuts.length + 1,
              itemBuilder: (context, index) {
                if (index == quickShortcuts.length) {
                  return _allModulesButton(context);
                }
                return _shortcutButton(context, quickShortcuts[index]);
              },
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FutureBuilder<List<Map<String, dynamic>>>(
        future: NotificationService.list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 220,
              child: Center(child: Text(snapshot.error.toString())),
            );
          }
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          return SafeArea(
            child: SizedBox(
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Text(
                      'Notifikasi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (items.isEmpty)
                    const Expanded(
                      child: Center(child: Text('Tidak ada notifikasi baru.')),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = items[index];
                          final isBongkaran = item['type'] == 'bongkaran';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isBongkaran
                                  ? const Color(0xFFFFE4C7)
                                  : const Color(0xFFE5EFDF),
                              child: Icon(
                                isBongkaran
                                    ? Icons.local_shipping_rounded
                                    : Icons.receipt_long_rounded,
                                color: const Color(0xFF1F7A2E),
                              ),
                            ),
                            title: Text(item['title']?.toString() ?? '-'),
                            subtitle: Text(
                              [
                                if (item['status_label'] != null)
                                  item['status_label'].toString(),
                                item['message']?.toString() ?? '-',
                              ].join(' · '),
                            ),
                             onTap: () {
                               Navigator.pop(sheetContext);
                               if (!isBongkaran) {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (_) => PurchasePage(
                                       initialPurchaseId: item['id']?.toString(),
                                     ),
                                   ),
                                 );
                               }
                             },
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

  Widget _shortcutIcon(SubMenuItem sc, Color accent) {
    final isPurchase =
        sc.id == 'sc_pembelian' ||
        sc.id == 'pb_transaksi' ||
        sc.route == '/pembelian/transaksi';
    final isWeighing =
        sc.id == 'sc_timbangan' ||
        sc.id == 'pn_timbangan_masuk' ||
        sc.route == '/penerimaan/timbangan-masuk';
    final isSupplier =
        sc.id == 'sc_supplier' || sc.route == '/master-data/supplier';
    final isBuyer = sc.id == 'sc_buyer' || sc.route == '/master-data/buyer';
    final isItem = sc.id == 'sc_item' || sc.route == '/master-data/item';
    final isSurveyor =
        sc.id == 'sc_surveyor' || sc.route == '/master-data/surveyor';
    final isWarehouse =
        sc.id == 'sc_gudang' || sc.route == '/master-data/warehouse';
    final networkIcon = isPurchase
        ? 'https://img.icons8.com/3d-fluency/94/bill.png'
        : isWeighing
        ? 'https://img.icons8.com/3d-fluency/94/truck.png'
        : isSupplier
        ? 'https://img.icons8.com/3d-fluency/94/supplier.png'
        : isBuyer
        ? 'https://img.icons8.com/3d-fluency/94/salary-male.png'
        : isItem
        ? 'https://img.icons8.com/3d-fluency/94/open-box.png'
        : isSurveyor
        ? 'https://img.icons8.com/3d-fluency/94/writer-male.png'
        : isWarehouse
        ? 'https://img.icons8.com/3d-fluency/94/hangar.png'
        : null;
    if (networkIcon != null) {
      return SizedBox(
        width: 46,
        height: 46,
        child: CachedNetworkImage(
          imageUrl: networkIcon,
          fit: BoxFit.contain,
          memCacheWidth: 94,
          memCacheHeight: 94,
          fadeInDuration: Duration(milliseconds: 180),
          errorWidget: (_, _, _) => Icon(sc.icon, color: accent, size: 30),
        ),
      );
    }

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Positioned(
            left: 3,
            top: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color.lerp(accent, Colors.black, 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(Colors.white, accent, 0.18)!, accent],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(sc.icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _shortcutButton(BuildContext context, SubMenuItem sc) {
    final accent = sc.badgeColor ?? Color(0xFF1F7A2E);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (sc.id == 'sc_supplier' || sc.route == '/master-data/supplier') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SupplierListPage()),
            );
          } else if (sc.id == 'sc_buyer' || sc.route == '/master-data/buyer') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BuyerPage()),
            );
          } else if (sc.id == 'sc_item' || sc.route == '/master-data/item') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MasterDataPage(type: 'item', title: 'Master Item'),
              ),
            );
          } else if (sc.id == 'sc_surveyor' ||
              sc.route == '/master-data/surveyor') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MasterSurveyorPage()),
            );
          } else if (sc.id == 'sc_gudang' ||
              sc.route == '/master-data/warehouse') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MasterWarehousePage()),
            );
          } else if (sc.id == 'pb_transaksi' ||
              sc.route == '/pembelian/transaksi') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PurchasePage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Akses Cepat: ${sc.title}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF1F7A2E),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _shortcutIcon(sc, accent),
              SizedBox(height: 5),
              Text(
                sc.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              if (sc.badge != null) ...[
                SizedBox(height: 2),
                Text(
                  sc.badge!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _allModulesButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showAllModules(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFE7EEDD),
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 25,
                  ),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Semua',
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAllModules(BuildContext context) async {
    final modules = dashboard?.menus ?? <DashboardMenuModel>[];
    final pageController = PageController();
    var currentPage = 0;
    final pageCount = modules.isEmpty ? 1 : (modules.length / 24).ceil();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return FractionallySizedBox(
              heightFactor: 0.84,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFC6D2C7),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 15, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Modul E-Procurement',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Color(0xFFE1E9E1)),
                    Expanded(
                      child: modules.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada modul yang dapat diakses.',
                              ),
                            )
                          : PageView.builder(
                              controller: pageController,
                              itemCount: pageCount,
                              onPageChanged: (page) =>
                                  updateSheet(() => currentPage = page),
                              itemBuilder: (context, page) {
                                final start = page * 24;
                                final end = (start + 24).clamp(
                                  0,
                                  modules.length,
                                );
                                final pageModules = modules.sublist(start, end);
                                return GridView.builder(
                                  padding: EdgeInsets.fromLTRB(12, 14, 12, 10),
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: pageModules.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 5,
                                        mainAxisSpacing: 5,
                                        mainAxisExtent: 83,
                                      ),
                                  itemBuilder: (context, index) =>
                                      _moduleSheetItem(
                                        sheetContext,
                                        pageModules[index],
                                      ),
                                );
                              },
                            ),
                    ),
                    if (pageCount > 1)
                      Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pageCount, (index) {
                            final active = index == currentPage;
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: active ? 20 : 6,
                              height: 6,
                              margin: EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: active
                                    ? Color(0xFF1F7A2E)
                                    : Color(0xFFCAD5CA),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    pageController.dispose();
  }

  Widget _moduleSheetItem(
    BuildContext sheetContext,
    DashboardMenuModel module,
  ) {
    final value = '${module.code} ${module.title}'.toLowerCase();
    final iconUrl = value.contains('master data')
        ? 'https://img.icons8.com/3d-fluency/94/data-configuration.png'
        : value.contains('change log') ||
              value.contains('changelog') ||
              value.contains('change_log')
        ? 'https://img.icons8.com/3d-fluency/94/edit-property.png'
        : (value.contains('report') || value.contains('laporan')) &&
              (value.contains('master data') ||
                  value.contains('master_data') ||
                  value.contains('master-data'))
        ? 'https://img.icons8.com/3d-fluency/94/data-configuration.png'
        : (value.contains('report') || value.contains('laporan')) &&
              (value.contains('pembelian') || value.contains('purchase'))
        ? 'https://img.icons8.com/3d-fluency/94/bill.png'
        : (value.contains('report') || value.contains('laporan')) &&
              (value.contains('penerimaan') || value.contains('reception'))
        ? 'https://img.icons8.com/3d-fluency/94/delivery.png'
        : value.contains('laporan pembelian') ||
              value.contains('report purchase')
        ? 'https://img.icons8.com/3d-fluency/94/bill.png'
        : value.contains('laporan penerimaan') ||
              value.contains('report reception')
        ? 'https://img.icons8.com/3d-fluency/94/delivery.png'
        : value.contains('laporan kualitas') ||
              value.contains('laporan qc') ||
              value.contains('report qc')
        ? 'https://img.icons8.com/3d-fluency/94/microscope.png'
        : value.contains('laba rugi') || value.contains('profit loss')
        ? 'https://img.icons8.com/3d-fluency/94/money-yours.png'
        : value.contains('kinerja buyer') || value.contains('report buyer')
        ? 'https://img.icons8.com/3d-fluency/94/salary-male.png'
        : value.contains('histori semua transaksi') ||
              value.contains('history all transaction')
        ? 'https://img.icons8.com/3d-fluency/94/edit-property.png'
        : value.trim() == 'report' ||
              value.trim() == 'laporan' ||
              value.contains('folder_laporan') ||
              value.contains('menu_report')
        ? 'https://img.icons8.com/3d-fluency/94/chart.png'
        : value.contains('bongkaran')
        ? 'https://img.icons8.com/3d-fluency/94/forklift.png'
        : value.contains('lab incoming') || value.contains('lab_incoming')
        ? 'https://img.icons8.com/3d-fluency/94/water.png'
        : value.contains('lab aktual') || value.contains('lab_aktual')
        ? 'https://img.icons8.com/3d-fluency/94/gas.png'
        : value.contains('parameter lab') || value.contains('parameter_lab')
        ? 'https://img.icons8.com/3d-fluency/94/gear--v2.png'
        : value.contains('beras') &&
              (value.contains('lab') || value.contains('qc'))
        ? 'https://img.icons8.com/3d-fluency/94/flour-of-rye.png'
        : value.contains('gabah')
        ? 'https://img.icons8.com/3d-fluency/94/wheat.png'
        : value.contains('menu lab') || value.trim() == 'lab'
        ? 'https://img.icons8.com/3d-fluency/94/microscope.png'
        : value.contains('verifikasi final data') ||
              value.contains('verifikasi_final_data')
        ? 'https://img.icons8.com/3d-fluency/94/approval.png'
        : value.contains('verifikasi data') ||
              value.contains('verifikasi_data')
        ? 'https://img.icons8.com/3d-fluency/94/verified-account.png'
        : value.contains('timbangan masuk') ||
              value.contains('timbangan keluar') ||
              value.contains('timbangan_masuk') ||
              value.contains('timbangan_keluar')
        ? 'https://img.icons8.com/3d-fluency/94/truck.png'
        : value.trim() == 'penerimaan' || value.contains('folder_penerimaan')
        ? 'https://img.icons8.com/3d-fluency/94/delivery.png'
        : value.trim() == 'finance' ||
              value.contains('folder_finance') ||
              value.contains('menu finance')
        ? 'https://img.icons8.com/3d-fluency/94/money-yours.png'
        : value.contains('pembelian')
        ? 'https://img.icons8.com/3d-fluency/94/bill.png'
        : value.contains('penerimaan') || value.contains('timbangan')
        ? 'https://img.icons8.com/3d-fluency/94/truck.png'
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(sheetContext);
          if (onOpenModule != null) {
            onOpenModule!(module);
          } else {
            onOpenModules?.call();
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconUrl != null)
                SizedBox(
                  width: 43,
                  height: 43,
                  child: CachedNetworkImage(
                    imageUrl: iconUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: 94,
                    memCacheHeight: 94,
                    errorWidget: (_, _, _) =>
                        Icon(Icons.grid_view_rounded, color: Color(0xFF1F7A2E)),
                  ),
                )
              else
                Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: Color(0xFFE6EFE0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: Color(0xFF1F7A2E),
                    size: 22,
                  ),
                ),
              SizedBox(height: 4),
              Text(
                module.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.05,
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
