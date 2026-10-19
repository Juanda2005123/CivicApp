import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/dane_cities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/liquid_glass_button.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Premium light Register Screen — Apple-inspired frosted glass design.
/// Pure Clean Architecture: consumes domain GetCitiesUseCase and AuthCubit.
class RegisterScreen extends StatefulWidget {
  final GetCitiesUseCase? getCitiesUseCase;

  const RegisterScreen({super.key, this.getCitiesUseCase});

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

  // Live password criteria
  bool _hasMinLength = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  // City catalog (Domain layer)
  late final GetCitiesUseCase _getCitiesUseCase;
  List<City> _cities = DaneCitiesCatalog.cities;
  int? _selectedCityId;

  // GPS state
  bool _isDetectingGps = false;
  String? _gpsMessage;
  bool _gpsSuccess = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController()..addListener(_updatePasswordStrength);
    _confirmPasswordController = TextEditingController();

    // Pure Dependency Injection: use injected use case or offline fallback
    _getCitiesUseCase = widget.getCitiesUseCase ?? const _OfflineFallbackGetCitiesUseCase();

    _loadCities();
  }

  void _updatePasswordStrength() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 6;
      _hasLowercase = RegExp(r'[a-z]').hasMatch(text);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
      _hasNumber = RegExp(r'[0-9]').hasMatch(text);
    });
  }

  Future<void> _loadCities() async {
    try {
      final list = await _getCitiesUseCase();
      if (mounted && list.isNotEmpty) setState(() => _cities = list);
    } catch (_) {
      // Graceful fallback to canonical catalog
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _detectNearestCity() async {
    setState(() {
      _isDetectingGps = true;
      _gpsMessage = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isDetectingGps = false;
          _gpsSuccess = false;
          _gpsMessage = 'Location services are disabled. You can select your city from the list.';
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isDetectingGps = false;
            _gpsSuccess = false;
            _gpsMessage = 'Permission denied. Please select your city manually from the catalog.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isDetectingGps = false;
          _gpsSuccess = false;
          _gpsMessage = 'Permission permanently denied. Please use the city selector.';
        });
        return;
      }
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );
      final closest = DaneCitiesCatalog.findClosestCity(position.latitude, position.longitude);
      setState(() {
        _isDetectingGps = false;
        _selectedCityId = closest.id;
        _gpsSuccess = true;
        _gpsMessage = 'Detected nearest city: ${closest.displayName}';
      });
    } catch (_) {
      setState(() {
        _isDetectingGps = false;
        _gpsSuccess = false;
        _gpsMessage = 'Unable to acquire GPS coordinates. Please select your city from the list.';
      });
    }
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select your residence city.'),
            backgroundColor: AppTheme.dark900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      final selectedCity = _cities.firstWhere(
        (c) => c.id == _selectedCityId,
        orElse: () => _cities.first,
      );
      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            cityId: _selectedCityId!,
            cityName: selectedCity.name,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          final selectedCity = _cities.firstWhere(
            (c) => c.id == _selectedCityId,
            orElse: () => _cities.first,
          );
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
            arguments: {
              'fullName': state.user.fullName,
              'email': state.user.email,
              'cityName': state.user.cityName ?? selectedCity.displayName,
              'nombre': state.user.fullName,
              'ciudad': state.user.cityName ?? selectedCity.displayName,
            },
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.dark900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.trim().split(' ').length < 2) {
                              return 'Please enter at least a first and last name';
                            }
                            return null;
                          },
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // City Selector Dropdown — exact text match: 'Residence City (DANE Coverage)'
                        DropdownButtonFormField<int>(
                          key: ValueKey(_selectedCityId),
                          initialValue: _selectedCityId,
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
                          items: _cities.map((city) {
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
                          onChanged: isLoading ? null : (value) => setState(() => _selectedCityId = value),
                          validator: (value) => value == null ? 'Please select a coverage city' : null,
                        ),
                        const SizedBox(height: 10),

                        // GPS Button
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: (isLoading || _isDetectingGps) ? null : _detectNearestCity,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _gpsSuccess
                                    ? AppTheme.statusSuccessBorder
                                    : AppTheme.borderLight,
                              ),
                              backgroundColor: _gpsSuccess
                                    ? AppTheme.statusSuccessBg
                                    : Colors.white,
                            ),
                            icon: _isDetectingGps
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(
                                    _gpsSuccess ? Icons.check_circle_outline : Icons.my_location,
                                    size: 16,
                                    color: _gpsSuccess ? AppTheme.statusSuccess : AppTheme.accent,
                                  ),
                            label: Text(
                              _isDetectingGps ? 'Detecting location...' : 'Detect nearest city via GPS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _gpsSuccess ? AppTheme.statusSuccess : AppTheme.accent,
                              ),
                            ),
                          ),
                        ),
                        if (_gpsMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _gpsSuccess
                                  ? AppTheme.statusSuccessBg
                                  : AppTheme.statusErrorBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _gpsSuccess
                                    ? AppTheme.statusSuccessBorder
                                    : AppTheme.statusErrorBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _gpsSuccess ? Icons.check_circle_outline : Icons.info_outline,
                                  size: 14,
                                  color: _gpsSuccess ? AppTheme.statusSuccess : AppTheme.statusError,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _gpsMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _gpsSuccess ? AppTheme.statusSuccess : AppTheme.statusError,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter a password';
                            if (value.length < 6) return 'Must contain at least 6 characters';
                            if (!RegExp(r'[a-z]').hasMatch(value)) return 'Must contain at least one lowercase letter';
                            if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain at least one uppercase letter';
                            if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain at least one number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Live password chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildChip('6+ caracteres', _hasMinLength),
                            _buildChip('Mayúscula (A-Z)', _hasUppercase),
                            _buildChip('Minúscula (a-z)', _hasLowercase),
                            _buildChip('Número (0-9)', _hasNumber),
                          ],
                        ),
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
                            GestureDetector(
                              onTap: isLoading ? null : () => Navigator.pop(context),
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

  Widget _buildChip(String label, bool satisfied) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: satisfied
            ? AppTheme.statusSuccessBg
            : const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: satisfied
              ? AppTheme.statusSuccessBorder
              : const Color(0xFFE2E8F0), // Slate 200
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.circle_outlined,
            size: 11,
            color: satisfied ? AppTheme.statusSuccess : AppTheme.slate400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: satisfied ? FontWeight.w600 : FontWeight.normal,
              color: satisfied ? AppTheme.statusSuccess : AppTheme.slate600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback Use Case implementation when running in standalone unit/widget tests without DI
class _OfflineFallbackGetCitiesUseCase implements GetCitiesUseCase {
  const _OfflineFallbackGetCitiesUseCase();

  @override
  CityRepository get repository => throw UnimplementedError();

  @override
  Future<List<City>> call() async {
    return DaneCitiesCatalog.cities;
  }
}
