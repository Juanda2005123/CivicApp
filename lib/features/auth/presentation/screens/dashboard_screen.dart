import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Initial Civic Dashboard Screen (Data Confirmation and Secure Logout).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve route arguments if passed as fallback
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String fullName = args?['fullName'] ?? args?['nombre'] ?? 'Civic Citizen';
        String email = args?['email'] ?? 'citizen@vigia.co';
        String cityName = args?['cityName'] ?? args?['ciudad'] ?? 'Cali (Valle del Cauca)';
        String rank = 'Urban Observer (Rank 1)';
        int points = 0;

        if (state is Authenticated) {
          fullName = state.user.fullName;
          email = state.user.email;
          cityName = state.user.cityName ?? cityName;
          rank = "${state.user.rankName} (Rank ${state.user.rankId})";
          points = state.user.reputationPoints;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('VIGÍA Civic Dashboard'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Log Out',
                icon: const Icon(Icons.logout),
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success Header
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
                                'Successfully logged in!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Active civic session and confirmed credentials.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Civic Profile Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Civic Profile Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Divider(height: 24),

                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: fullName,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            value: email,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Residence City',
                            value: cityName,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.military_tech_outlined,
                            label: 'Civic Rank',
                            value: rank,
                          ),
                          const SizedBox(height: 14),

                          _buildInfoRow(
                            icon: Icons.stars_outlined,
                            label: 'Reputation Points',
                            value: '$points pts',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Prominent Secure Logout Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Log Out'),
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
