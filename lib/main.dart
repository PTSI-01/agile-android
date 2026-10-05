import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/api_config.dart';
import 'models/dashboard_model.dart';
import 'models/user_model.dart';
import 'screens/dashboard_overview_page.dart';
import 'screens/login_page.dart';
import 'screens/modules_page.dart';
import 'screens/profile_page.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  await ThemeService.init();
  await PushNotificationService.initialize();
  final loggedIn = await AuthService.isLoggedIn();
  UserModel? user = loggedIn ? await AuthService.getCurrentUser() : null;
  final dashboard = loggedIn ? await AuthService.getDashboard() : null;
  if (dashboard == null && !await AuthService.isLoggedIn()) user = null;

  runApp(MyApp(initialUser: user, initialDashboard: dashboard));
}

const ink = Color(0xFF183C32);
const green = Color(0xFF1F7A2E);
const muted = Color(0xFF7D8983);

class MyApp extends StatelessWidget {
  final UserModel? initialUser;
  final DashboardData? initialDashboard;
  const MyApp({super.key, this.initialUser, this.initialDashboard});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeService.mode,
    builder: (context, themeMode, _) => MaterialApp(
      title: 'Agile E-Procurement',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: initialUser != null
          ? HomePage(user: initialUser, dashboard: initialDashboard)
          : const LoginPage(),
    ),
  );

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF102019) : Colors.white;
    final filterSurface = dark ? const Color(0xFF14271F) : Colors.white;
    final selectedFilter = dark
        ? const Color(0xFF294737)
        : const Color(0xFFE5EFDF);
    final onSurface = dark ? const Color(0xFFEAF3EE) : ink;
    final filterBorder = dark
        ? const Color(0xFF365247)
        : const Color(0xFFD7E0D8);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: brightness,
        surface: surface,
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: dark
          ? const Color(0xFF09130F)
          : const Color(0xFFF7F9F5),
      canvasColor: surface,
      cardColor: dark ? const Color(0xFF14271F) : Colors.white,
      dialogTheme: DialogThemeData(backgroundColor: surface),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: dark
            ? const Color(0xFF09130F)
            : const Color(0xFFF7F9F5),
        foregroundColor: dark ? const Color(0xFFEAF3EE) : ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: dark
            ? const Color(0xFF294737)
            : const Color(0xFFE5EFDF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF14271F) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: filterSurface,
        selectedColor: selectedFilter,
        disabledColor: dark ? const Color(0xFF102019) : const Color(0xFFF0F3EF),
        labelStyle: TextStyle(color: onSurface),
        secondaryLabelStyle: TextStyle(color: onSurface),
        side: BorderSide(color: filterBorder),
        shape: const StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? selectedFilter
                : filterSurface,
          ),
          foregroundColor: WidgetStatePropertyAll(onSurface),
          side: WidgetStatePropertyAll(BorderSide(color: filterBorder)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: filterSurface,
        textStyle: TextStyle(color: onSurface),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: onSurface),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(filterSurface),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(filterSurface),
          foregroundColor: WidgetStatePropertyAll(onSurface),
          side: WidgetStatePropertyAll(BorderSide(color: filterBorder)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: dark ? const Color(0xFFEAF3EE) : ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(
          color: dark ? const Color(0xFFEAF3EE) : ink,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: dark ? const Color(0xFFD7E5DD) : ink),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final UserModel? user;
  final DashboardData? dashboard;
  const HomePage({super.key, this.user, this.dashboard});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late UserModel? _currentUser;
  late DashboardData? _dashboard;
  bool _loadingDashboard = false;
  final GlobalKey<ModulesPageState> _modulesKey = GlobalKey<ModulesPageState>();
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _dashboard = widget.dashboard;
    if (_currentUser == null) {
      _loadUser();
    }
    if (_dashboard == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reloadDashboard());
    }
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _reloadDashboard() async {
    if (_loadingDashboard) return;
    setState(() => _loadingDashboard = true);
    final dashboard = await AuthService.getDashboard();
    if (!mounted) return;
    if (dashboard != null) {
      setState(() {
        _dashboard = dashboard;
        _loadingDashboard = false;
      });
      return;
    }
    if (!await AuthService.isLoggedIn()) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
      return;
    }
    setState(() => _loadingDashboard = false);
  }

  Widget _dashboardState() {
    if (_loadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: muted),
            const SizedBox(height: 12),
            const Text(
              'Menu belum berhasil dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _reloadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang Menu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDashboard = _dashboard != null;
    final pages = [
      hasDashboard
          ? DashboardOverviewPage(
              user: _currentUser,
              dashboard: _dashboard,
              onOpenModules: () => setState(() => _currentIndex = 1),
              onOpenModule: (module) {
                setState(() => _currentIndex = 1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _modulesKey.currentState?.openRootModule(module);
                });
              },
              onOpenProfile: () => setState(() => _currentIndex = 2),
            )
          : _dashboardState(),
      hasDashboard
          ? ModulesPage(key: _modulesKey, dashboard: _dashboard)
          : _dashboardState(),
      ProfilePage(user: _currentUser),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex == 1) {
          final handled = _modulesKey.currentState?.handleBack() ?? false;
          if (handled) return;

          setState(() => _currentIndex = 0);
          return;
        }

        if (_currentIndex == 2) {
          setState(() => _currentIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar dari aplikasi'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          elevation: 4,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Modul',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
