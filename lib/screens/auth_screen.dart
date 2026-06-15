import 'package:flutter/material.dart';
import 'package:kiosk_app/utils/app_constants.dart';
import 'package:kiosk_app/utils/app_theme.dart';
import 'package:kiosk_app/widgets/gradient_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kiosk_app/utils/validators/auth_validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    // Close keyboard
    FocusScope.of(context).unfocus();

    // Validate fields first
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Success! Please check your email.'),
            ),
          );
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalScaffold(
      title: (_isSignUp ? 'Create Owner Account' : 'Owner Login'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final maxFormWidth = isWide ? 520.0 : double.infinity;

            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 24 : 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxFormWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: AppTextStyles.headlineLg().copyWith(
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Staff & Management Portal",
                            style: AppTextStyles.labelCaps(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.bodyLg(),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: Validators.email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            style: AppTextStyles.bodyLg(),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (v) =>
                                Validators.password(v, isSignUp: _isSignUp),
                            onFieldSubmitted: (_) =>
                                _isLoading ? null : _handleAuth(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 48,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _handleAuth,
                                    icon: Icon(
                                      _isSignUp
                                          ? Icons.person_add_alt_1
                                          : Icons.login,
                                    ),
                                    label: Text(
                                      _isSignUp ? 'Register' : 'Login',
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 12),

                          OutlinedButton(
                            onPressed: () => setState(() {
                              _isSignUp = !_isSignUp;

                              // Optional: re-run validation when switching mode
                              _formKey.currentState?.validate();
                            }),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.outlineVariant,
                              ),
                              foregroundColor: AppColors.onSurface,
                              minimumSize: const Size(0, 48),
                            ),
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Login'
                                  : 'New client? Register your business',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
