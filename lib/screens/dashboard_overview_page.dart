import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/menu_item_model.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';
import '../widgets/menu_bottom_sheet.dart';
import 'supplier/supplier_list_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final supportedShortcuts = MenuData.quickShortcuts
        .where((item) => item.id == 'sc_supplier')
        .toList();
    final supportedGroups = MenuData.menuGroups
        .where((group) => group.id == 'master_data')
        .map((group) => MenuGroupItem(
              id: group.id,
              title: group.title,
              subtitle: 'Supplier, Buyer, Item, Gudang, Surveyor, dan Wilayah',
              icon: group.icon,
              color: group.color,
              lightColor: group.lightColor,
              category: group.category,
              isFeatured: group.isFeatured,
              items: group.items.where((item) => const {
                'md_supplier', 'md_buyer', 'md_inventory', 'md_warehouse',
                'md_surveyor', 'md_wilayah'
              }.contains(item.id)).toList(),
            ))
        .toList();
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
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

            if (dashboard != null) ...[
              const Text(
                'DASHBOARD TERSEDIA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: muted,
                ),
              ),
              const SizedBox(height: 10),
              if (dashboard!.dashboards.isEmpty)
                _backendInfoCard(
                  context,
                  icon: Icons.lock_outline_rounded,
                  title: 'Belum ada dashboard aktif',
                  description: 'Akun ini belum memiliki akses dashboard di Laravel.',
                )
              else
                ...dashboard!.dashboards.map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _backendInfoCard(
                      context,
                      icon: card.code == 'laba_rugi'
                          ? Icons.account_balance_wallet_outlined
                          : Icons.shopping_cart_checkout_rounded,
                      title: card.title,
                      description: card.description,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
            ],

            // 3. KPI / METRIC CARDS
            Row(
              children: [
                _metricCard(
                  title: 'Tonase Masuk',
                  value: '148.5 T',
                  subtitle: '+12.4% vs kemarin',
                  icon: Icons.scale_rounded,
                  iconColor: const Color(0xFFD84315),
                  bgColor: const Color(0xFFFBE9E7),
                ),
                const SizedBox(width: 12),
                _metricCard(
                  title: 'Nilai Pengadaan',
                  value: 'Rp 982 Jt',
                  subtitle: '24 Transaksi aktif',
                  icon: Icons.payments_rounded,
                  iconColor: green,
                  bgColor: const Color(0xFFE8F5E9),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _metricCard(
                  title: 'Rata-rata Kadar Air',
                  value: '18.2%',
                  subtitle: 'Standar GKP (Aman)',
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF1E88E5),
                  bgColor: const Color(0xFFE3F2FD),
                ),
                const SizedBox(width: 12),
                _metricCard(
                  title: 'Perlu Approval',
                  value: '4 Order',
                  subtitle: '2 Manager, 2 Finance',
                  icon: Icons.pending_actions_rounded,
                  iconColor: const Color(0xFFE65100),
                  bgColor: const Color(0xFFFFF3E0),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 4. AKSES CEPAT (QUICK SHORTCUTS)
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
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: supportedShortcuts.length,
              itemBuilder: (context, index) {
                final sc = supportedShortcuts[index];
                return _shortcutButton(context, sc);
              },
            ),
            const SizedBox(height: 28),

            // 5. MODUL UTAMA E-PROCUREMENT (KATEGORI)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modul E-Procurement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                Text(
                  '${supportedGroups.length} Modul',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: supportedGroups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = supportedGroups[index];
                return _moduleCategoryCard(context, group);
              },
            ),
            const SizedBox(height: 28),

            // 6. TARGET BULANAN SOURCING
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2F25) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C4438)
                      : const Color(0xFFE9EDE5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.track_changes_rounded,
                        color: green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Target Pengadaan September',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '76% Tercapai',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Realisasi: 3.420 Ton',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Target: 4.500 Ton',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.76,
                      minHeight: 8,
                      color: green,
                      backgroundColor: Color(0xFFE5EFDF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EDE5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183C32),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D6864),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7D8983),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backendInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDE5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1F7A2E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF183C32))),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF7D8983), height: 1.35)),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFF1F7A2E), size: 22),
        ],
      ),
    );
  }

  Widget _shortcutButton(BuildContext context, SubMenuItem sc) {
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
            border: Border.all(color: const Color(0xFFE9EDE5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  sc.icon,
                  color: const Color(0xFF1F7A2E),
                  size: 20,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _moduleCategoryCard(BuildContext context, MenuGroupItem group) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => MenuBottomSheet.show(context, group),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9EDE5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: group.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(group.icon, color: group.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183C32),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      group.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7D8983),
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
                  color: group.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${group.items.length} Menu',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: group.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: group.color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
