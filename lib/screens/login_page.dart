import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/auth/supabase_auth_manager.dart';
import 'package:lidarmesure/components/modern_button.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authManager = SupabaseAuthManager();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authManager.signInWithEmail(
        context,
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo SOLOL
                      Image.asset(
                        'assets/icons/SOLOL.png',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SOLOL',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).isFrench ? 'Connectez-vous a votre compte' : 'Sign in to your account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).email,
                          hintText: 'exemple@email.fr',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context).pleaseEnterEmail;
                          }
                          if (!value.contains('@')) {
                            return AppLocalizations.of(context).invalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).password,
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context).pleaseEnterPassword;
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context).passwordTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ModernButton(
                        label: AppLocalizations.of(context).login,
                        onPressed: _isLoading ? null : _handleLogin,
                        loading: _isLoading,
                        expand: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).noAccount,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.push('/signup'),
                            child: Text(AppLocalizations.of(context).signup),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
