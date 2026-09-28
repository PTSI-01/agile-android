import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/menu_item_model.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';
import 'supplier/supplier_list_page.dart';
import 'purchase_page.dart';

class DashboardOverviewPage extends StatelessWidget {
  final UserModel? user;
  final DashboardData? dashboard;
  final VoidCallback? onOpenModules;
  final VoidCallback? onOpenProfile;

  const DashboardOverviewPage({
    super.key,
    this.user,
    this.dashboard,
    this.onOpenModules,
    this.onOpenProfile,
  });

  bool _hasMenuAccess(
    List<DashboardMenuModel> menus,
    SubMenuItem shortcut,
  ) {
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
      ? const <SubMenuItem>[]
      : MenuData.quickShortcuts
        .where((shortcut) => _hasMenuAccess(
            dashboard!.menus,
            shortcut,
          ))
        .toList();
    const ink = Color(0xFF183C32);
    const muted = Color(0xFF7D8983);

    final displayName = user?.name.split(' ').first ?? 'Pengguna';
    final roleName = user?.role ?? 'Sourcing Team';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // 1. TOP BAR
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo_agile.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFD8EFAC),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AGILE JAYA ABADI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: ink,
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
                const Spacer(),
                IconButton(
                  tooltip: 'Notifikasi',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tidak ada notifikasi baru.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Badge(
                    label: Text('3'),
                    child: Icon(Icons.notifications_none_rounded, color: ink),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFFE7ECDD),
                    child: Text(
                      user?.initials ?? 'AR',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 2. HERO GREETING CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14382E), Color(0xFF235A49)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14382E).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8EFAC).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Color(0xFFD8EFAC),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              roleName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD8EFAC),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Musim Panen 2026',
                        style: TextStyle(
                          color: Color(0xFFB5CBC0),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Halo, $displayName! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
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
            const SizedBox(height: 24),

            // 3. QUICK ACCESS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Akses Cepat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                TextButton(
                  onPressed: onOpenModules,
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemCount: supportedShortcuts.length,
              itemBuilder: (context, index) => _shortcutButton(
                context,
                supportedShortcuts[index],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _shortcutButton(BuildContext context, SubMenuItem sc) {
    final accent = sc.badgeColor ?? const Color(0xFF1F7A2E);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (sc.id == 'sc_supplier' || sc.route == '/master-data/supplier') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupplierListPage()),
            );
          } else if (sc.id == 'pb_transaksi' || sc.route == '/pembelian/transaksi') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PurchasePage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Akses Cepat: ${sc.title}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF1F7A2E),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
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
                          colors: [
                            Color.lerp(Colors.white, accent, 0.18)!,
                            accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.24),
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 4,
                            left: 7,
                            child: Container(
                              width: 12,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          Icon(sc.icon, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sc.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF183C32),
                  height: 1.2,
                ),
              ),
              if (sc.badge != null) ...[
                const SizedBox(height: 5),
                Text(
                  sc.badge!,
                  style: TextStyle(
                    fontSize: 9,
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

}
