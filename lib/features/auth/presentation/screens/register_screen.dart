import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/config/app_env.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/dane_cities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/city_remote_data_source.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Civic Registration Screen integrated with Supabase, BLoC, and live DANE catalog.
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

  // City catalog (Option B: Live Supabase with offline fallback)
  late final CityRemoteDataSource _cityDataSource;
  List<DaneCity> _cities = DaneCitiesCatalog.cities;
  int? _selectedCityId;

  // GPS sensor state for assisted onboarding (RN-14)
  bool _isDetectingGps = false;
  String? _gpsMessage;
  bool _gpsSuccess = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _cityDataSource = CityRemoteDataSource(
      supabaseClient: AppEnv.isSupabaseConfigured ? Supabase.instance.client : null,
    );
    _loadCities();
  }

  Future<void> _loadCities() async {
    final list = await _cityDataSource.getCities();
    if (mounted) {
      setState(() {
        _cities = list;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// GPS-assisted detection to auto-select the nearest coverage city
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

      // 1. Try last known position first (instant response < 100ms)
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. Fall back to low accuracy with short timeout if cache is empty
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );

      final closest = DaneCitiesCatalog.findClosestCity(
        position.latitude,
        position.longitude,
      );

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
          const SnackBar(
            content: Text('Please select your residence city.'),
            backgroundColor: Colors.redAccent,
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
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Citizen Registration'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: isLoading ? null : () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Join Civic Oversight',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Audit your city's road infrastructure and participate in community pothole resolution.",
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Full Name Field
                    TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. Juan David Quintero',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryCivic),
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
                    const SizedBox(height: 16),

                    // Email Address Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'citizen@example.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryCivic),
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
                    const SizedBox(height: 16),

                    // Official DANE Coverage Dropdown
                    DropdownButtonFormField<int>(
                      key: ValueKey(_selectedCityId),
                      initialValue: _selectedCityId,
                      decoration: const InputDecoration(
                        labelText: 'Residence City (DANE Coverage)',
                        prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.primaryCivic),
                      ),
                      hint: const Text('Select your city'),
                      isExpanded: true,
                      items: _cities.map((city) {
                        return DropdownMenuItem<int>(
                          value: city.id,
                          child: Text(
                            city.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: city.isCapital ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCityId = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a coverage city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // GPS Assisted Button
                    OutlinedButton.icon(
                      onPressed: (isLoading || _isDetectingGps) ? null : _detectNearestCity,
                      icon: _isDetectingGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                        _isDetectingGps ? 'Detecting location...' : 'Detect nearest city via GPS',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),

                    if (_gpsMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _gpsSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _gpsSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _gpsSuccess ? Icons.check_circle_outline : Icons.info_outline,
                              size: 16,
                              color: _gpsSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _gpsMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _gpsSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Minimum 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryCivic),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
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
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Must contain at least 6 characters';
                        }
                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return 'Must contain at least one lowercase letter';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Must contain at least one uppercase letter';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Must contain at least one number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Repeat your password',
                        prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppTheme.primaryCivic),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit Button with spinner
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Civic Account'),
                    ),
                    const SizedBox(height: 16),

                    // Link to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : () => Navigator.pop(context),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: AppTheme.primaryCivic,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
        );
      },
    );
  }
}
