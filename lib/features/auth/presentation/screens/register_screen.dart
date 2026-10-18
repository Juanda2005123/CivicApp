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

/// Pantalla de Registro Cívico integrada con Supabase, BLoC y catálogo DANE en vivo.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Catálogo de ciudades (Opción B: Supabase en vivo con fallback offline)
  late final CityRemoteDataSource _cityDataSource;
  List<DaneCity> _cities = DaneCitiesCatalog.cities;
  int? _selectedCityId;

  // Estado del sensor GPS para onboarding asistido (RN-14)
  bool _isDetectingGps = false;
  String? _gpsMessage;
  bool _gpsSuccess = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
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
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Detección asistida por GPS para auto-seleccionar la ciudad más cercana
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
          _gpsMessage = 'Servicio de ubicación desactivado. Puedes seleccionar tu ciudad en la lista.';
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
            _gpsMessage = 'Permiso denegado. Selecciona tu ciudad manualmente en el catálogo.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isDetectingGps = false;
          _gpsSuccess = false;
          _gpsMessage = 'Permiso denegado permanentemente. Usa el selector de ciudades.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
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
        _gpsMessage = 'Detectada la ciudad más cercana: ${closest.displayName}';
      });
    } catch (_) {
      setState(() {
        _isDetectingGps = false;
        _gpsSuccess = false;
        _gpsMessage = 'No fue posible obtener coordenadas GPS. Selecciona tu ciudad en la lista.';
      });
    }
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona tu ciudad de residencia.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nombreCompleto: _nombreController.text.trim(),
            ciudadId: _selectedCityId!,
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
              'nombre': state.usuario.nombreCompleto,
              'email': state.usuario.email,
              'ciudad': state.usuario.ciudadNombre ?? selectedCity.displayName,
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
            title: const Text('Registro de Ciudadano'),
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
                      'Únete a la Veeduría Cívica',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Audita el estado de las vías de tu ciudad y participa en la resolución comunitaria de baches.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Nombre Completo
                    TextFormField(
                      controller: _nombreController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        hintText: 'Ej. Juan Camilo Pérez',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryCivic),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu nombre completo';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Ingresa al menos un nombre y un apellido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Correo Electrónico
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        hintText: 'ciudadano@ejemplo.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryCivic),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un correo electrónico';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selector Cerrado DANE (Dropdown de Cobertura Oficial)
                    DropdownButtonFormField<int>(
                      key: ValueKey(_selectedCityId),
                      initialValue: _selectedCityId,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad de Residencia (Cobertura DANE)',
                        prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.primaryCivic),
                      ),
                      hint: const Text('Selecciona tu ciudad'),
                      isExpanded: true,
                      items: _cities.map((city) {
                        return DropdownMenuItem<int>(
                          value: city.id,
                          child: Text(
                            city.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: city.esCapital ? FontWeight.w600 : FontWeight.normal,
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
                          return 'Debes seleccionar una ciudad de cobertura';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Botón Asistido por GPS
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
                        _isDetectingGps ? 'Detectando ubicación...' : 'Detectar ciudad más cercana por GPS',
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

                    // Contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Mínimo 6 caracteres',
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
                          return 'Ingresa una contraseña';
                        }
                        if (value.length < 6) {
                          return 'Debe contener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirmar Contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        hintText: 'Repite tu contraseña',
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
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Botón Crear Cuenta con spinner
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
                          : const Text('Crear Cuenta Cívica'),
                    ),
                    const SizedBox(height: 16),

                    // Enlace a Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : () => Navigator.pop(context),
                          child: const Text(
                            'Inicia Sesión',
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
