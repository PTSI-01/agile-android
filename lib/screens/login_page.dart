import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Native adaptation of Laravel's resources/views/login.blade.php.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _remember = false;
  bool _dark = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.login(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success && result.user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selamat datang, ${result.user!.name}!'),
          backgroundColor: const Color(0xFF1F7A2E),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardLoadingPage(user: result.user!),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFFD14942),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showServerConfigDialog() {
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
              setState(() {});
            },
            child: const Text('Reset Default'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ApiConfig.setBaseUrl(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF1F7A2E);
    final background = _dark
        ? const Color(0xFF09130F)
        : const Color(0xFFF7F9F8);
    final surface = _dark ? const Color(0xFF102019) : Colors.white;
    final text = _dark ? const Color(0xFFEAF3EE) : const Color(0xFF1C2321);
    final soft = _dark ? const Color(0xFF9BB0A7) : const Color(0xFF5D6864);
    final border = _dark ? const Color(0xFF2B4035) : const Color(0xFFDCE6DE);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: _dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forest,
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: soft, fontSize: 13),
        prefixIconColor: soft,
        suffixIconColor: soft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: forest, width: 1.5),
        ),
        errorMaxLines: 2,
      ),
    );
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Pengaturan Server API',
                              onPressed: _showServerConfigDialog,
                              style: IconButton.styleFrom(
                                backgroundColor: _dark
                                    ? const Color(0xFF21372A)
                                    : const Color(0xFFE8EFE9),
                              ),
                              icon: const Icon(
                                Icons.settings_ethernet_rounded,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: _dark
                                  ? 'Aktifkan mode terang'
                                  : 'Aktifkan mode gelap',
                              onPressed: () => setState(() => _dark = !_dark),
                              style: IconButton.styleFrom(
                                backgroundColor: _dark
                                    ? const Color(0xFF21372A)
                                    : const Color(0xFFE8EFE9),
                              ),
                              icon: Icon(
                                _dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.asset(
                                            'assets/images/logo_agile.jpg',
                                            width: 58,
                                            height: 58,
                                            fit: BoxFit.contain,
                                            semanticLabel:
                                                'Logo Agile Jaya Abadi',
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'AGILE JAYA ABADI',
                                                style: TextStyle(
                                                  color: text,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: .4,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'E-Procurement',
                                                style: TextStyle(
                                                  color: soft,
                                                  fontSize: 12,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 44),
                                    const Text(
                                      'SELAMAT DATANG',
                                      style: TextStyle(
                                        color: Color(0xFFB58412),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      'Masuk ke akun Anda',
                                      style: TextStyle(
                                        color: text,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.5,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      'Silakan masuk untuk mengakses dashboard dan e-procurement.',
                                      style: TextStyle(
                                        color: soft,
                                        fontSize: 13,
                                        height: 1.7,
                                      ),
                                    ),
                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD14942)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFD14942)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Color(0xFFD14942),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Color(0xFFD14942),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    _label('Email', text),
                                    const SizedBox(height: 9),
                                    TextFormField(
                                      controller: _email,
                                      enabled: !_isLoading,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      autocorrect: false,
                                      style: TextStyle(
                                        color: text,
                                        fontSize: 14,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'nama@agilejayaabadi.com',
                                        prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                          size: 20,
                                        ),
                                      ),
                                      validator: (value) {
                                        final email = value?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'Email tidak boleh kosong.';
                                        }
                                        if (!RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(email)) {
                                          return 'Format email tidak valid.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _label('Password', text),
                                    const SizedBox(height: 9),
                                    TextFormField(
                                      controller: _password,
                                      enabled: !_isLoading,
                                      obscureText: _hidePassword,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      style: TextStyle(
                                        color: text,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _hidePassword
                                              ? 'Tampilkan password'
                                              : 'Sembunyikan password',
                                          onPressed: () => setState(
                                            () =>
                                                _hidePassword = !_hidePassword,
                                          ),
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Password tidak boleh kosong.'
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    CheckboxListTile(
                                      value: _remember,
                                      onChanged: _isLoading
                                          ? null
                                          : (value) => setState(
                                                () =>
                                                    _remember = value ?? false,
                                              ),
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      dense: true,
                                      activeColor: forest,
                                      checkboxShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      title: Text(
                                        'Ingat saya',
                                        style: TextStyle(
                                          color: soft,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 54,
                                      child: FilledButton.icon(
                                        onPressed: _isLoading ? null : _submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: forest,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.login_rounded,
                                                size: 20,
                                              ),
                                        label: Text(
                                          _isLoading ? 'Memproses...' : 'Masuk',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Text(
                            '© 2026 Agile Jaya. All rights reserved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: soft, fontSize: 11),
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
      ),
    );
  }

  Widget _label(String label, Color color) => Text.rich(
    TextSpan(
      text: label,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      children: const [
        TextSpan(
          text: ' *',
          style: TextStyle(color: Color(0xFFD14942)),
        ),
      ],
    ),
  );
}

class DashboardLoadingPage extends StatefulWidget {
  final UserModel user;
  const DashboardLoadingPage({super.key, required this.user});

  @override
  State<DashboardLoadingPage> createState() => _DashboardLoadingPageState();
}

class _DashboardLoadingPageState extends State<DashboardLoadingPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dashboard = await AuthService.getDashboard();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(user: widget.user, dashboard: dashboard),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
