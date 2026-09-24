import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final UserModel? user;

  const ProfilePage({super.key, this.user});

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Konfigurasi Server API',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Base URL backend Laravel Agile:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8000/api',
                labelText: 'Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contoh:\n• Android Emulator: http://10.0.2.2:8000/api\n• HP Asli / WiFi: http://192.168.x.x:8000/api\n• Windows Desktop: http://127.0.0.1:8000/api',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiConfig.resetBaseUrl();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reset Default'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ApiConfig.setBaseUrl(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Anda akan diarahkan kembali ke halaman login dan token sesi Anda akan dicabut.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD14942),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Ya, Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);
    const muted = Color(0xFF7D8983);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil & Akun',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
          children: [
            // 1. PROFILE CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE9EDE5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFE7ECDD),
                    child: Text(
                      user?.initials ?? 'AR',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Pengguna Agile',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'user@agilejayaabadi.com',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user?.role != null
                                ? 'Role: ${user!.role}'
                                : 'Role: Sourcing Team',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. SETTINGS LIST
            const Text(
              'Pengaturan & Sambungan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9EDE5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.settings_ethernet_rounded,
                        color: Color(0xFF1E88E5),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Base URL Server API',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      ApiConfig.baseUrl,
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showServerConfigDialog(context),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F3ED)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFE65100),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Status Sesi Login',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Sesi Tunggal (Single-Session Protected)',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. TENTANG APLIKASI
            const Text(
              'Informasi Sistem',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9EDE5)),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: muted),
                    title: Text(
                      'Aplikasi E-Procurement Agile',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      'v1.0.0',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                  Divider(height: 1, color: Color(0xFFF0F3ED)),
                  ListTile(
                    leading: Icon(Icons.business_rounded, color: muted),
                    title: Text(
                      'PT Agile Jaya Abadi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Sistem Pengadaan Gabah & Komoditas Beras',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. SIGN OUT BUTTON
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD14942),
                  side: const BorderSide(color: Color(0xFFD14942), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _confirmSignOut(context),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Sign Out (Keluar Akun)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

