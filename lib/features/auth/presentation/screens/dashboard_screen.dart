import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla de Dashboard Cívico Inicial (Confirmación de Datos y Logout Seguro).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperar argumentos transmitidos por ruta en caso de fallback
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String nombre = args?['nombre'] ?? 'Ciudadano VIGÍA';
        String email = args?['email'] ?? 'ciudadano@vigia.gov.co';
        String ciudad = args?['ciudad'] ?? 'Cali (Valle del Cauca)';
        String rango = 'Observador (Rango 1)';
        int puntos = 0;

        if (state is Authenticated) {
          nombre = state.usuario.nombreCompleto;
          email = state.usuario.email;
          ciudad = state.usuario.ciudadNombre ?? ciudad;
          rango = "${state.usuario.nivelReputacionNombre} (Rango ${state.usuario.nivelReputacionId})";
          puntos = state.usuario.puntosReputacion;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Panel Cívico VIGÍA'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Cerrar Sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado de Éxito
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Te has logueado con éxito!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sesión cívica activa y datos confirmados.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta de Perfil Cívico
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen del Perfil Cívico',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Divider(height: 24),

                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: 'Nombre Completo',
                            value: nombre,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Correo Electrónico',
                            value: email,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Ciudad de Residencia',
                            value: ciudad,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.military_tech_outlined,
                            label: 'Rango Cívico',
                            value: rango,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.stars_outlined,
                            label: 'Puntos de Reputación',
                            value: '$puntos pts',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Botón Prominente de Deslogueo Seguro
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Salir / Desloguearse'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _handleLogout(BuildContext context) {
    context.read<AuthCubit>().logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  static Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryCivic),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
