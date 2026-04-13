import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'priya');
  final _passCtrl = TextEditingController(text: 'priya006');
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final auth = Provider.of<AuthService>(context, listen: false);
    final tr = Provider.of<TranslationService>(context, listen: false);
    final success = await auth.login(_emailCtrl.text, _passCtrl.text);

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() => _error = tr.t('login_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Provider.of<TranslationService>(context);

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Language selector
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tr.locale,
                            dropdownColor: AppColors.gradientStart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            icon: const Icon(Icons.language,
                                color: Colors.white70, size: 18),
                            items: TranslationService.supportedLocales.entries
                                .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) tr.setLocale(v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logo - Monochrome White
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.balance,
                          size: 44, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      tr.t('app_name'),
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 34,
                                letterSpacing: 1.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInDown(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      tr.t('tagline'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login form
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              tr.t('login'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 20),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: tr.t('email'),
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? '' : null,
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: tr.t('password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? '' : null,
                            ),
                            const SizedBox(height: 8),

                            // Error
                            if (_error != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, bottom: 8),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Login button
                            Consumer<AuthService>(
                              builder: (_, auth, __) => ElevatedButton(
                                onPressed: auth.isLoading ? null : _login,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Text(tr.t('login_btn')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: Text(
                      'demo@vidhana.ai / demo123',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
