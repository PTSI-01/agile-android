import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final UserModel? user;

  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation1;
  late Animation<Offset> _slideAnimation1;
  late Animation<double> _fadeAnimation2;
  late Animation<Offset> _slideAnimation2;
  late Animation<double> _fadeAnimation3;
  late Animation<Offset> _slideAnimation3;

  double _signOutScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation1 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
          ),
        );

    _fadeAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _slideAnimation2 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
          ),
        );

    _fadeAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideAnimation3 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F7A2E);
    const muted = Color(0xFF7D8983);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: green,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final collapsedHeight =
                    MediaQuery.paddingOf(context).top + kToolbarHeight;
                final showCollapsedTitle =
                    constraints.maxHeight <= collapsedHeight + 18;
                return FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsetsDirectional.only(bottom: 16),
                  title: AnimatedOpacity(
                    opacity: showCollapsedTitle ? 1 : 0,
                    duration: const Duration(milliseconds: 140),
                    child: const Text(
                      'Profil & Akun',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF183C32), Color(0xFF1F7A2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Text(
                                  widget.user?.initials ?? 'AR',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: green,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation1,
                            child: SlideTransition(
                              position: _slideAnimation1,
                              child: Column(
                                children: [
                                  Text(
                                    widget.user?.name ?? 'Pengguna Agile',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.user?.email ??
                                        'user@agilejayaabadi.com',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.user?.role != null
                                          ? 'Role: ${widget.user!.role}'
                                          : 'Role: Sourcing Team',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation2,
                    child: SlideTransition(
                      position: _slideAnimation2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Pengaturan & Keamanan'),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Sesi Tunggal (Single-Session Protected)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: Theme.of(context).dividerColor,
                                ),
                                SwitchListTile(
                                  secondary: const Icon(
                                    Icons.dark_mode_outlined,
                                  ),
                                  title: const Text(
                                    'Mode Malam',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Terapkan ke seluruh halaman aplikasi',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: ThemeService.isDark,
                                  onChanged: (_) => ThemeService.toggle(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation3,
                    child: SlideTransition(
                      position: _slideAnimation3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Informasi Sistem'),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.info_outline_rounded,
                                    color: muted,
                                  ),
                                  title: Text(
                                    'E-Procurement AJA',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  trailing: Text(
                                    'v1.0.0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: Theme.of(context).dividerColor,
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.business_rounded,
                                    color: muted,
                                  ),
                                  title: Text(
                                    'CV Agile Jaya Abadi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Sistem Pengadaan Bahan Baku',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _signOutScale = 0.95),
                              onTapUp: (_) =>
                                  setState(() => _signOutScale = 1.0),
                              onTapCancel: () =>
                                  setState(() => _signOutScale = 1.0),
                              onTap: () {
                                _confirmSignOut(context);
                              },
                              child: AnimatedScale(
                                scale: _signOutScale,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  height: 50,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFD14942),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD14942)
                                            .withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: Color(0xFFD14942),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sign Out (Keluar Akun)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFFD14942),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
