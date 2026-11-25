import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/location_blocked_dialog.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/domain/entities/city.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/domain/validators/password_policy.dart';
import '../../../auth/domain/validators/registration_rules.dart';
import '../../../auth/ui/widgets/password_strength_chips.dart';
import '../bloc/edit_profile_bloc.dart';
import '../bloc/edit_profile_event.dart';
import '../bloc/edit_profile_state.dart';

/// "Datos personales" screen (HU-04): edit full name, DANE residence city,
/// email (with inbox verification notice), and password.
class EditProfileScreen extends StatefulWidget {
  final Profile initialProfile;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _infoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String? _selectedCityName;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.fullName);
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _selectedCityName = widget.initialProfile.cityName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _savePersonalInfo() {
    if (!(_infoFormKey.currentState?.validate() ?? false)) return;
    final cityName = _selectedCityName;
    if (cityName == null || cityName.isEmpty) return;

    context.read<EditProfileBloc>().add(EditProfileSaved(
          fullName: _nameController.text.trim(),
          cityName: cityName,
          email: _emailController.text.trim(),
        ));
  }

  void _changePassword() {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    context.read<EditProfileBloc>().add(EditProfilePasswordChanged(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos personales'),
        actions: const [ThemeToggleButton()],
      ),
      body: BlocConsumer<EditProfileBloc, EditProfileState>(
        listenWhen: (previous, current) =>
            previous.locationStatus != current.locationStatus ||
            previous.detectedCity != current.detectedCity ||
            previous.passwordStatus != current.passwordStatus,
        listener: (context, state) {
          if (state.locationStatus == EditProfileLocationStatus.detected &&
              state.detectedCity != null) {
            setState(() {
              _selectedCityName = state.detectedCity!.name;
            });
          } else if (state.locationStatus == EditProfileLocationStatus.blocked) {
            showLocationBlockedDialog(
              context,
              message: state.locationErrorMessage ??
                  'El permiso de ubicación está bloqueado. Toca "Abrir ajustes" y luego Permisos → Ubicación.',
              onOpenSettings: () =>
                  context.read<EditProfileBloc>().add(EditProfileLocationSettingsRequested()),
            );
          }

          if (state.passwordStatus == PasswordChangeStatus.saved) {
            _currentPasswordController.clear();
            _newPasswordController.clear();
          }
        },
        builder: (context, state) {
          final isSavingInfo = state.status == EditProfileStatus.saving;
          final isSavingPassword = state.passwordStatus == PasswordChangeStatus.saving;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPersonalInfoCard(context, theme, state, isSavingInfo),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPasswordCard(context, theme, state, isSavingPassword),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalInfoCard(
    BuildContext context,
    ThemeData theme,
    EditProfileState state,
    bool isSaving,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _infoFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Información de cuenta', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (state.status == EditProfileStatus.failure && state.errorMessage != null) ...[
                AppNotice(kind: NoticeKind.error, message: state.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ] else if (state.status == EditProfileStatus.saved) ...[
                AppNotice(
                  kind: state.emailVerificationPending ? NoticeKind.info : NoticeKind.success,
                  message: state.emailVerificationPending
                      ? 'Revisa tu nuevo correo y confirma el enlace de verificación para que el cambio sea efectivo.'
                      : 'Tus datos personales quedaron actualizados.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                controller: _nameController,
                label: 'Nombre completo',
                hint: 'Ej. Juan David Quintero',
                prefixIcon: Icons.person_outline,
                validator: RegistrationRules.validateFullName,
              ),
              const SizedBox(height: AppSpacing.field),
              _CitySelector(
                cities: state.cities,
                selectedCityName: _selectedCityName,
                onSelected: (city) => setState(() => _selectedCityName = city.name),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: state.locationStatus == EditProfileLocationStatus.detecting
                      ? null
                      : () => context.read<EditProfileBloc>().add(EditProfileCityDetectRequested()),
                  icon: const Icon(Icons.my_location_outlined, size: AppSizes.icon),
                  label: Text(
                    state.locationStatus == EditProfileLocationStatus.detecting
                        ? 'Detectando tu ubicación…'
                        : 'Detectar mi ciudad por GPS',
                  ),
                ),
              ),
              if (state.locationStatus == EditProfileLocationStatus.error &&
                  state.locationErrorMessage != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppNotice(kind: NoticeKind.info, message: state.locationErrorMessage!),
              ],
              const SizedBox(height: AppSpacing.field),
              AppTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                hint: 'nombre@correo.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: RegistrationRules.validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Guardar cambios',
                isLoading: isSaving,
                onPressed: _savePersonalInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard(
    BuildContext context,
    ThemeData theme,
    EditProfileState state,
    bool isSaving,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cambiar contraseña', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (state.passwordStatus == PasswordChangeStatus.failure &&
                  state.passwordErrorMessage != null) ...[
                AppNotice(kind: NoticeKind.error, message: state.passwordErrorMessage!),
                const SizedBox(height: AppSpacing.md),
              ] else if (state.passwordStatus == PasswordChangeStatus.saved) ...[
                const AppNotice(
                  kind: NoticeKind.success,
                  message: 'Tu contraseña se actualizó correctamente.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                controller: _currentPasswordController,
                label: 'Contraseña actual',
                hint: 'Escribe tu contraseña actual',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCurrent,
                suffix: IconButton(
                  tooltip: _obscureCurrent ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Escribe tu contraseña actual' : null,
              ),
              const SizedBox(height: AppSpacing.field),
              AppTextField(
                controller: _newPasswordController,
                label: 'Nueva contraseña',
                hint: 'Mínimo 6 caracteres',
                prefixIcon: Icons.lock_reset_outlined,
                obscureText: _obscureNew,
                onChanged: (_) => setState(() {}),
                suffix: IconButton(
                  tooltip: _obscureNew ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: PasswordPolicy.validate,
              ),
              const SizedBox(height: AppSpacing.sm),
              PasswordStrengthChips(checks: PasswordPolicy.evaluate(_newPasswordController.text)),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Actualizar contraseña',
                isLoading: isSaving,
                onPressed: _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CitySelector extends StatelessWidget {
  final List<City> cities;
  final String? selectedCityName;
  final ValueChanged<City> onSelected;

  const _CitySelector({
    required this.cities,
    required this.selectedCityName,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final matchingCity = cities.cast<City?>().firstWhere(
          (c) => c?.name == selectedCityName,
          orElse: () => null,
        );

    return AppDropdownField<City>(
      label: 'Ciudad de residencia',
      hint: 'Elige tu ciudad',
      prefixIcon: Icons.location_city_outlined,
      value: matchingCity,
      entries: [
        for (final city in cities)
          DropdownMenuEntry<City>(
            value: city,
            label: '${city.name} · ${city.department}',
          ),
      ],
      onChanged: (city) {
        if (city != null) onSelected(city);
      },
      validator: (city) => city == null ? 'Elige tu ciudad de la lista' : null,
    );
  }
}
