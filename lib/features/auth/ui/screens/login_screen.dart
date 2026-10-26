import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../domain/validators/password_policy.dart';
import '../../domain/validators/registration_rules.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

/// Login: email and password. It only draws the [LoginState] and turns input
/// into events; navigation is a reaction to the state.
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
      context.read<LoginBloc>().add(
            LoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
        }
      },
      builder: (context, state) {
        final isLoading = state.status == LoginStatus.loading;

        return Scaffold(
          body: BrandBackdrop(
            child: SafeArea(
              child: Stack(
                children: [
                  const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: ThemeToggleButton(),
                    ),
                  ),
                  Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BrandMark(tagline: 'Tu voz, con evidencia.')),
                          const SizedBox(height: AppSpacing.xl + 4),
                          Text('Ingresa a tu cuenta', style: theme.textTheme.headlineSmall),
                          if (state.status == LoginStatus.failure) ...[
                            const SizedBox(height: AppSpacing.field),
                            AppNotice(
                              kind: NoticeKind.error,
                              message: state.errorMessage ?? 'No pudimos iniciar tu sesión. Inténtalo de nuevo.',
                            ),
                          ],
                          const SizedBox(height: AppSpacing.field),
                          AppTextField(
                            label: 'Correo electrónico',
                            hint: 'nombre@correo.com',
                            controller: _emailController,
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            enabled: !isLoading,
                            validator: RegistrationRules.validateEmail,
                          ),
                          const SizedBox(height: AppSpacing.field),
                          AppTextField(
                            label: 'Contraseña',
                            hint: 'Tu contraseña',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            enabled: !isLoading,
                            onFieldSubmitted: (_) => _handleLogin(),
                            suffix: IconButton(
                              tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Escribe tu contraseña';
                              if (value.length < PasswordPolicy.minLength) {
                                return 'La contraseña debe tener al menos ${PasswordPolicy.minLength} caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl - 2),
                          PrimaryButton(
                            label: 'Ingresar',
                            loadingLabel: 'Ingresando…',
                            isLoading: isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('¿Aún no tienes cuenta?', style: theme.textTheme.bodyMedium),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.pushNamed(context, AppRoutes.register),
                                child: const Text('Regístrate'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'VEEDURÍA VIAL CIUDADANA',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.data(size: 10, line: 14).copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 1,
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
          ),
        );
      },
    );
  }
}
