import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla de Inicio de Sesión Cívico integrada con Supabase y BLoC/Cubit.
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
          // Navegación post-login exitoso con purga de historial hacia el Dashboard
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
            arguments: {
              'nombre': state.usuario.nombreCompleto,
              'email': state.usuario.email,
              'ciudad': state.usuario.ciudadNombre ?? 'Cali (Valle del Cauca)',
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
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Escudo Cívico
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryCivic, width: 2),
                          ),
                          child: const Icon(
                            Icons.remove_red_eye_rounded,
                            size: 42,
                            color: AppTheme.primaryCivic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título y Subtítulo
                      const Text(
                        'VIGÍA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppTheme.primaryCivic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Plataforma de Auditoría Vial y Veeduría Ciudadana',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Campo Correo Electrónico
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          hintText: 'ejemplo@correo.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryCivic),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu correo electrónico';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: '••••••••',
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
                            return 'Ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botón Iniciar Sesión con indicador de carga
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 16),

                      // Enlace a Registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta cívica? ',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(context, AppRoutes.register);
                                  },
                            child: const Text(
                              'Regístrate aquí',
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
          ),
        );
      },
    );
  }
}
