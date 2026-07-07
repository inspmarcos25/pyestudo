import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../settings/language_selector.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.resetEmailSent)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = strings.authError(e.code, e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    return Scaffold(
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
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.code, size: 56),
                        const SizedBox(height: 8),
                        Text(
                          'PyEstudo',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRegistering
                              ? strings.loginSubtitleRegister
                              : strings.loginSubtitleSignIn,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: strings.emailLabel,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.passwordLabel,
                          ),
                          onSubmitted: (_) =>
                              _loading ? null : _submitEmail(),
                        ),
                        if (!_isRegistering)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _forgotPassword,
                              child: Text(strings.forgotPassword),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loading ? null : _submitEmail,
                          child: Text(
                            _isRegistering
                                ? strings.createAccount
                                : strings.signIn,
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(strings.or),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _submitGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: Text(strings.continueWithGoogle),
                        ),
                        if (_loading) ...[
                          const SizedBox(height: 16),
                          const Center(child: CircularProgressIndicator()),
                        ],
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
