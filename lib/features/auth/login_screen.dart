import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/theme/duo_theme.dart';
import '../settings/language_selector.dart';

/// Tela de login com a identidade da marca (Nunito + verde PyEstudo +
/// relevo 3D), em vez do Material default — é a primeira impressão de quem
/// chega da landing.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _loading = false;
  String? _error;

  AppStrings get _strings => AppStrings.of(LocaleScope.of(context).language);

  Future<void> _submitEmail() async {
    final strings = _strings;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isRegistering) {
        await _auth.registerWithEmail(email, password);
      } else {
        await _auth.signInWithEmail(email, password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = strings.authError(e.code, e.message));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitGoogle() async {
    final strings = _strings;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = strings.authError(e.code, e.message));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final strings = _strings;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = strings.enterEmailForReset);
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.resetEmailSent)));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = strings.authError(e.code, e.message));
    }
  }

  InputDecoration _fieldDecoration(DuoColors duo, String label) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 2),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: DuoText.body.copyWith(color: duo.muted),
      filled: true,
      fillColor: duo.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: border(duo.border),
      focusedBorder: border(DuoPalette.blue),
      errorBorder: border(DuoPalette.red),
      focusedErrorBorder: border(DuoPalette.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    final duo = DuoColors.of(context);
    return Scaffold(
      backgroundColor: duo.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const LanguageSelector(),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Wordmark(),
                        const SizedBox(height: 6),
                        Text(
                          _isRegistering
                              ? strings.loginSubtitleRegister
                              : strings.loginSubtitleSignIn,
                          textAlign: TextAlign.center,
                          style: DuoText.body.copyWith(color: duo.muted),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: DuoText.body.copyWith(color: duo.text),
                          decoration: _fieldDecoration(duo, strings.emailLabel),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: DuoText.body.copyWith(color: duo.text),
                          decoration: _fieldDecoration(
                            duo,
                            strings.passwordLabel,
                          ),
                          onSubmitted: (_) => _loading ? null : _submitEmail(),
                        ),
                        if (!_isRegistering)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _forgotPassword,
                              child: Text(
                                strings.forgotPassword,
                                style: DuoText.small.copyWith(
                                  color: DuoPalette.blue,
                                ),
                              ),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          _ErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 16),
                        DuoButton3D(
                          color: _loading ? duo.locked : DuoPalette.green,
                          shadowColor: _loading
                              ? duo.lockedShadow
                              : DuoPalette.greenShadow,
                          depth: 5,
                          onTap: _loading ? null : _submitEmail,
                          semanticsLabel: _isRegistering
                              ? strings.createAccount
                              : strings.signIn,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      (_isRegistering
                                              ? strings.createAccount
                                              : strings.signIn)
                                          .toUpperCase(),
                                      style: DuoText.eyebrow.copyWith(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                  _isRegistering = !_isRegistering;
                                  _error = null;
                                }),
                          child: Text(
                            _isRegistering
                                ? strings.haveAccount
                                : strings.createNewAccount,
                            style: DuoText.bold.copyWith(
                              color: DuoPalette.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Divider(color: duo.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                strings.or,
                                style: DuoText.small.copyWith(color: duo.muted),
                              ),
                            ),
                            Expanded(child: Divider(color: duo.border)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DuoButton3D(
                          color: duo.surface,
                          shadowColor: duo.lockedShadow,
                          border: Border.all(color: duo.border, width: 2),
                          depth: 4,
                          onTap: _loading ? null : _submitGoogle,
                          semanticsLabel: strings.continueWithGoogle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.g_mobiledata,
                                  size: 28,
                                  color: duo.text,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  strings.continueWithGoogle,
                                  style: DuoText.bold.copyWith(
                                    color: duo.text,
                                    fontSize: 14,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logomarca: bloco verde com relevo 3D e `{ }` + nome em Nunito Black.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: DuoPalette.green,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: DuoPalette.greenShadow,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '{ }',
              style: TextStyle(
                fontFamily: duoFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'PyEstudo',
          textAlign: TextAlign.center,
          style: DuoText.display.copyWith(color: duo.text, fontSize: 26),
        ),
      ],
    );
  }
}

/// Erro de autenticação como banner com fundo, não texto solto.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DuoPalette.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DuoPalette.red.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: DuoPalette.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: DuoText.body.copyWith(color: DuoPalette.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
