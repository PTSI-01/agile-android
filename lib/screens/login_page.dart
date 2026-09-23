import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Keep the user on this page until real Laravel authentication is available.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Login belum tersedia. Silakan gunakan website Agile untuk masuk sementara.',
        ),
        behavior: SnackBarBehavior.floating,
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton.filledTonal(
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
                                    const SizedBox(height: 30),
                                    _label('Email', text),
                                    const SizedBox(height: 9),
                                    TextFormField(
                                      controller: _email,
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
                                      onChanged: (value) => setState(
                                        () => _remember = value ?? false,
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
                                        onPressed: _submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: forest,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.login_rounded,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'Masuk',
                                          style: TextStyle(
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
