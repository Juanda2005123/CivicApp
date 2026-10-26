import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../domain/validators/password_policy.dart';
import '../../domain/validators/registration_rules.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';
import '../widgets/password_strength_chips.dart';

/// Registration form. It only draws the [RegisterState] and turns user input
/// into events; the rules live in the domain.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Live password checklist (the rules come from the domain's PasswordPolicy)
  PasswordChecks _passwordChecks = PasswordPolicy.evaluate('');

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController()..addListener(_updatePasswordChecks);
    _confirmPasswordController = TextEditingController();
  }

  void _updatePasswordChecks() {
    setState(() => _passwordChecks = PasswordPolicy.evaluate(_passwordController.text));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordChecks);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RegisterBloc>().add(
            RegisterSubmitted(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  Widget _visibilityToggle({required bool obscured, required VoidCallback onPressed}) {
    return IconButton(
      tooltip: obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
      icon: Icon(obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == RegisterStatus.success) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
        }
      },
      builder: (context, state) {
        final isLoading = state.status == RegisterStatus.loading;
        final isDetectingGps = state.gpsStatus == GpsStatus.detecting;
        final gpsSuccess = state.gpsStatus == GpsStatus.success;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Crear cuenta'),
            leading: IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new, size: AppSizes.icon),
              onPressed: isLoading ? null : () => Navigator.pop(context),
            ),
            actions: const [ThemeToggleButton()],
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Únete a la veeduría de tu ciudad: reporta el estado de las vías y respalda a tus vecinos.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (state.status == RegisterStatus.failure) ...[
                          const SizedBox(height: AppSpacing.field),
                          AppNotice(
                            kind: NoticeKind.error,
                            message: state.errorMessage ?? 'No pudimos completar el registro.',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.field),
                        AppTextField(
                          label: 'Nombre completo',
                          hint: 'Ej. Juan David Quintero',
                          controller: _fullNameController,
                          prefixIcon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          enabled: !isLoading,
                          validator: RegistrationRules.validateFullName,
                        ),
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
                        AppDropdownField<int>(
                          label: 'Ciudad de residencia',
                          hint: 'Elige tu ciudad',
                          prefixIcon: Icons.location_city_outlined,
                          value: state.selectedCityId,
                          items: state.cities.map((city) {
                            return DropdownMenuItem<int>(
                              value: city.id,
                              child: Text(
                                city.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: city.isCapital ? AppTextStyles.bodyStrong : AppTextStyles.body,
                              ),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    context.read<RegisterBloc>().add(CitySelected(value));
                                  }
                                },
                          validator: (value) => value == null ? 'Elige tu ciudad' : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSizes.buttonCompact),
                          ),
                          onPressed: (isLoading || isDetectingGps)
                              ? null
                              : () => context.read<RegisterBloc>().add(NearestCityRequested()),
                          icon: isDetectingGps
                              ? DottedSpinner(size: 18, semanticLabel: 'Detectando tu ubicación')
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(isDetectingGps ? 'Detectando tu ubicación…' : 'Detectar mi ciudad por GPS'),
                        ),
                        if (state.gpsMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppNotice(
                            kind: gpsSuccess ? NoticeKind.success : NoticeKind.error,
                            message: state.gpsMessage!,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.field),
                        AppTextField(
                          label: 'Contraseña',
                          hint: 'Mínimo ${PasswordPolicy.minLength} caracteres',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          enabled: !isLoading,
                          suffix: _visibilityToggle(
                            obscured: _obscurePassword,
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: PasswordPolicy.validate,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PasswordStrengthChips(checks: _passwordChecks),
                        const SizedBox(height: AppSpacing.field),
                        AppTextField(
                          label: 'Confirmar contraseña',
                          hint: 'Repite tu contraseña',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_reset_outlined,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _handleRegister(),
                          suffix: _visibilityToggle(
                            obscured: _obscureConfirmPassword,
                            onPressed: () =>
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (value) =>
                              value != _passwordController.text ? 'Las contraseñas no coinciden' : null,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          label: 'Crear cuenta',
                          loadingLabel: 'Creando cuenta…',
                          isLoading: isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('¿Ya tienes cuenta?', style: theme.textTheme.bodyMedium),
                            TextButton(
                              onPressed: isLoading ? null : () => Navigator.pop(context),
                              child: const Text('Ingresa'),
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
        );
      },
    );
  }
}
