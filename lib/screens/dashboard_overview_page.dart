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
    final quickModules = dashboard == null
        ? <DashboardMenuModel>[]
        : dashboard!.menus
              .where((module) => module.children.isNotEmpty)
              .take(4)
              .toList();
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
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        children: [
                          TextSpan(
                            text: 'E-PROCUREMENT ',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const TextSpan(
                            text: 'AJA',
                            style: TextStyle(color: Color(0xFFB27A19)),
                          ),
                        ],
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
                          ? Badge(label: Text('$count'), child: icon)
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
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1DF),
                borderRadius: BorderRadius.circular(22),
                image: const DecorationImage(
                  image: AssetImage('assets/images/sawah.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  opacity: 0.62,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF14382E).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFB8D0AF).withValues(alpha: 0.98),
                            const Color(0xFFDDEAD5).withValues(alpha: 0.86),
                            const Color(0xFFE8F1DF).withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang, $displayName',
                            style: TextStyle(
                              color: const Color(0xFF183C32),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bersama E-Procurement AJA wujudkan rantai pemasok yang lebih efisien.',
                            style: TextStyle(
                              color: const Color(0xFF5B7165),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x220F3B2E),
                            blurRadius: 7,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CV Agile',
                                style: TextStyle(
                                  color: Color(0xFF285A3B),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'Jaya Abadi',
                                style: TextStyle(
                                  color: Color(0xFF285A3B),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(height: 3),
                              SizedBox(
                                width: 28,
                                height: 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE5B52D),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),

            Text(
              'Ringkasan Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.35,
              children: [
                _metricCard(
                  context,
                  'Pembelian',
                  '${dashboard?.metrics['po_count'] ?? 0}',
                  Icons.shopping_cart_rounded,
                  const Color(0xFFE3F3E4),
                  previousValue: dashboard?.metrics['po_count_yesterday'],
                ),
                _metricCard(
                  context,
                  'Timbangan',
                  '${dashboard?.metrics['final_tonnage'] ?? 0} Kg',
                  Icons.scale_rounded,
                  const Color(0xFFFFF0D0),
                ),
                _metricCard(
                  context,
                  'Lab',
                  'Rp ${dashboard?.metrics['lab_average_price'] ?? 0}',
                  Icons.science_rounded,
                  const Color(0xFFE0EEFF),
                ),
                _metricCard(
                  context,
                  'Finance',
                  dashboard?.metrics['profit_label']?.toString() ??
                      'Belum ada data',
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFFF0E5FF),
                ),
              ],
            ),
            SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Akses Cepat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenModules,
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                mainAxisExtent: 78,
              ),
              itemCount: quickModules.length,
              itemBuilder: (context, index) =>
                  _moduleShortcutButton(context, quickModules[index]),
            ),
            SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenModules,
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            ...((dashboard?.metrics['latest_transactions'] as List? ?? const [])
                .take(10)
                .map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long),
                    ),
                    title: Text(item['kode_transaksi']?.toString() ?? '-'),
                    subtitle: Text(
                      '${item['nama_supplier'] ?? '-'} - Qty ${item['tonase_final_aol'] ?? '-'}',
                    ),
                    trailing: Text('Rp ${item['harga_final'] ?? '-'}'),
                  );
                })
                .toList()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color bg, {
    dynamic previousValue,
  }) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9EDE5)),
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1F5B42), size: 18),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7D8983)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (previousValue != null)
          _trendIndicator(context, _number(value), _number(previousValue)),
      ],
    ),
  );

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  Widget _trendIndicator(
    BuildContext context,
    double current,
    double previous,
  ) {
    final isUp = current > previous;
    final isDown = current < previous;
    final percent = previous == 0
        ? (current == 0 ? 0 : 100)
        : ((current - previous).abs() / previous.abs() * 100).round();
    final color = isUp
        ? const Color(0xFF42A85A)
        : isDown
        ? const Color(0xFFD45C4C)
        : const Color(0xFF89958E);
    final icon = isUp
        ? Icons.trending_up_rounded
        : isDown
        ? Icons.trending_down_rounded
        : Icons.drag_handle_rounded;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        Text(
          '$percent%',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
                              ].join(' Ãƒâ€šÃ‚Â· '),
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

  Widget _moduleShortcutButton(
    BuildContext context,
    DashboardMenuModel module,
  ) {
    final accent = _moduleAccent(module);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (onOpenModule != null) {
            onOpenModule!(module);
          } else {
            onOpenModules?.call();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _moduleIconFor('${module.code} ${module.title}'),
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                module.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _moduleAccent(DashboardMenuModel module) {
    final value = '${module.code} ${module.title}'.toLowerCase();
    if (value.contains('pembelian')) return const Color(0xFF2E7D32);
    if (value.contains('timbang') || value.contains('penerimaan')) {
      return const Color(0xFFB47A16);
    }
    if (value.contains('lab')) return const Color(0xFF2774B8);
    if (value.contains('finance')) return const Color(0xFF7543A8);
    return const Color(0xFF1F5B42);
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

  IconData _moduleIconFor(String value) {
    if (value.contains('supplier group')) return Icons.groups_rounded;
    if (value.contains('supplier')) return Icons.local_shipping_rounded;
    if (value.contains('buyer group')) return Icons.group_rounded;
    if (value.contains('buyer')) return Icons.person_rounded;
    if (value.contains('pembelian') || value.contains('purchase')) {
      return Icons.shopping_bag_rounded;
    }
    if (value.contains('timbangan') || value.contains('penerimaan')) {
      return Icons.scale_rounded;
    }
    if (value.contains('bongkaran')) return Icons.local_shipping_rounded;
    if (value.contains('lab') || value.contains('qc')) {
      return Icons.science_rounded;
    }
    if (value.contains('finance') || value.contains('laba'))
      return Icons.payments_rounded;
    if (value.contains('supplier')) return Icons.local_shipping_rounded;
    if (value.contains('buyer')) return Icons.person_rounded;
    if (value.contains('item') || value.contains('kategori')) {
      return Icons.inventory_2_rounded;
    }
    if (value.contains('gudang') || value.contains('warehouse')) {
      return Icons.warehouse_rounded;
    }
    if (value.contains('wilayah') ||
        value.contains('provinsi') ||
        value.contains('kota') ||
        value.contains('kecamatan') ||
        value.contains('desa')) {
      return Icons.map_rounded;
    }
    if (value.contains('report') || value.contains('laporan')) {
      return Icons.analytics_rounded;
    }
    if (value.contains('change log') || value.contains('changelog')) {
      return Icons.history_rounded;
    }
    if (value.contains('user') || value.contains('akun')) {
      return Icons.manage_accounts_rounded;
    }
    return Icons.grid_view_rounded;
  }

  Widget _moduleSheetItem(
    BuildContext sheetContext,
    DashboardMenuModel module,
  ) {
    final value = '${module.code} ${module.title}'.toLowerCase();
    final moduleIcon = _moduleIconFor(value);

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
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EFE0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  moduleIcon,
                  color: const Color(0xFF1F5B42),
                  size: 23,
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
