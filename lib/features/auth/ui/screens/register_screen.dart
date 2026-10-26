import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/liquid_glass_button.dart';
import '../../domain/validators/password_policy.dart';
import '../../domain/validators/registration_rules.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';
import '../widgets/password_strength_chips.dart';

/// Premium light Register Screen — Apple-inspired frosted glass design.
/// It only draws the [RegisterState] and turns user input into events.
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == RegisterStatus.success) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        } else if (state.status == RegisterStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Could not complete the registration.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppTheme.dark900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == RegisterStatus.loading;
        final isDetectingGps = state.gpsStatus == GpsStatus.detecting;
        final gpsSuccess = state.gpsStatus == GpsStatus.success;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Citizen Registration'),
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.textPrimary),
              onPressed: isLoading ? null : () => Navigator.pop(context),
            ),
          ),
          body: CivicBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: GlassCard(
                  maxWidth: 500,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEEF2FF),
                                    Color(0xFFE0E7FF),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFC7D2FE),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppTheme.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join Civic Oversight',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Audit your city's road infrastructure and participate in community pothole resolution.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Divider(color: AppTheme.borderLight, height: 1),
                        const SizedBox(height: 18),

                        // Full Name
                        TextFormField(
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'e.g. Juan David Quintero',
                            prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.slate500),
                          ),
                          validator: RegistrationRules.validateFullName,
                        ),
                        const SizedBox(height: 14),

                        // Email
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
                            hintText: 'citizen@example.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.slate500),
                          ),
                          validator: RegistrationRules.validateEmail,
                        ),
                        const SizedBox(height: 14),

                        // City Selector Dropdown — exact text match: 'Residence City (DANE Coverage)'
                        DropdownButtonFormField<int>(
                          key: ValueKey(state.selectedCityId),
                          initialValue: state.selectedCityId,
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Residence City (DANE Coverage)',
                            prefixIcon: Icon(Icons.location_city_outlined, size: 20, color: AppTheme.slate500),
                          ),
                          hint: const Text('Select your city', style: TextStyle(color: AppTheme.slate400)),
                          isExpanded: true,
                          items: state.cities.map((city) {
                            return DropdownMenuItem<int>(
                              value: city.id,
                              child: Text(
                                city.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: city.isCapital ? FontWeight.w600 : FontWeight.normal,
                                  color: AppTheme.textPrimary,
                                ),
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
                          validator: (value) => value == null ? 'Please select a coverage city' : null,
                        ),
                        const SizedBox(height: 10),

                        // GPS Button
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: (isLoading || isDetectingGps)
                                ? null
                                : () => context.read<RegisterBloc>().add(NearestCityRequested()),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: gpsSuccess
                                    ? AppTheme.statusSuccessBorder
                                    : AppTheme.borderLight,
                              ),
                              backgroundColor: gpsSuccess
                                    ? AppTheme.statusSuccessBg
                                    : Colors.white,
                            ),
                            icon: isDetectingGps
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(
                                    gpsSuccess ? Icons.check_circle_outline : Icons.my_location,
                                    size: 16,
                                    color: gpsSuccess ? AppTheme.statusSuccess : AppTheme.accent,
                                  ),
                            label: Text(
                              isDetectingGps ? 'Detecting location...' : 'Detect nearest city via GPS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: gpsSuccess ? AppTheme.statusSuccess : AppTheme.accent,
                              ),
                            ),
                          ),
                        ),
                        if (state.gpsMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: gpsSuccess
                                  ? AppTheme.statusSuccessBg
                                  : AppTheme.statusErrorBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: gpsSuccess
                                    ? AppTheme.statusSuccessBorder
                                    : AppTheme.statusErrorBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  gpsSuccess ? Icons.check_circle_outline : Icons.info_outline,
                                  size: 14,
                                  color: gpsSuccess ? AppTheme.statusSuccess : AppTheme.statusError,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.gpsMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: gpsSuccess ? AppTheme.statusSuccess : AppTheme.statusError,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Minimum 6 characters',
                            prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppTheme.slate500),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.slate500,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: PasswordPolicy.validate,
                        ),
                        const SizedBox(height: 8),

                        // Live password chips
                        PasswordStrengthChips(checks: _passwordChecks),
                        const SizedBox(height: 14),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleRegister(),
                          enabled: !isLoading,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Repeat your password',
                            prefixIcon: Icon(Icons.lock_reset_outlined, size: 20, color: AppTheme.slate500),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.slate500,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 24),

                        // Apple Liquid Glass Submit Button
                        LiquidGlassButton(
                          onPressed: isLoading ? null : _handleRegister,
                          isLoading: isLoading,
                          label: 'Create Civic Account',
                          height: 50,
                        ),
                        const SizedBox(height: 18),

                        // Link to Login
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: isLoading ? null : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Log In',
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
        );
      },
    );
  }
}
