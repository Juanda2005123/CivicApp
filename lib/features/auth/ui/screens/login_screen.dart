import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/civic_brand_header.dart';
import '../../../../core/widgets/liquid_glass_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Premium light Login Screen — Apple-inspired Liquid Glass design.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
            arguments: {
              'fullName': state.user.fullName,
              'email': state.user.email,
              'cityName': state.user.cityName ?? 'Cali (Valle del Cauca)',
              'nombre': state.user.fullName,
              'ciudad': state.user.cityName ?? 'Cali (Valle del Cauca)',
            },
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.statusError, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.dark900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: CivicBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: GlassCard(
                    maxWidth: 420,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CivicBrandHeader(compact: true),
                          const SizedBox(height: 18),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'example@email.com',
                              prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.slate500),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email address';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            enabled: !isLoading,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppTheme.slate500),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.slate500,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Apple Liquid Glass Login Button
                          LiquidGlassButton(
                            onPressed: isLoading ? null : _handleLogin,
                            isLoading: isLoading,
                            label: 'Log In',
                            height: 50,
                          ),
                          const SizedBox(height: 18),

                          // Subtle Apple Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.borderLight, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'o',
                                  style: TextStyle(color: AppTheme.slate400, fontSize: 13),
                                ),
                              ),
                              Expanded(child: Divider(color: AppTheme.borderLight, thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Register link
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "Don't have a civic account? ",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        Navigator.pushNamed(context, AppRoutes.register);
                                      },
                                child: const Text(
                                  'Register here',
                                  style: TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
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
      },
    );
  }
}
