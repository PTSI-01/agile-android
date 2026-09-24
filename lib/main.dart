import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'models/dashboard_model.dart';
import 'models/user_model.dart';
import 'screens/dashboard_overview_page.dart';
import 'screens/login_page.dart';
import 'screens/modules_page.dart';
import 'screens/profile_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  final loggedIn = await AuthService.isLoggedIn();
  final user = loggedIn ? await AuthService.getCurrentUser() : null;
  final dashboard = loggedIn ? await AuthService.getDashboard() : null;

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
  Widget build(BuildContext context) => MaterialApp(
    title: 'Agile E-Procurement',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F9F5),
      colorScheme: ColorScheme.fromSeed(seedColor: green),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: ink),
      ),
    ),
    home: initialUser != null
        ? HomePage(user: initialUser, dashboard: initialDashboard)
        : const LoginPage(),
  );
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

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    if (_currentUser == null) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() => _currentUser = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardOverviewPage(
        user: _currentUser,
        dashboard: widget.dashboard,
        onOpenModules: () => setState(() => _currentIndex = 1),
        onOpenProfile: () => setState(() => _currentIndex = 2),
      ),
      const ModulesPage(),
      ProfilePage(user: _currentUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5EFDF),
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
    );
  }
}
