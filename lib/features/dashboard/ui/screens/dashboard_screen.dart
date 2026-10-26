import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_state.dart';

/// Citizen profile summary (Sprint 1 landing screen) with secure logout.
/// It only draws the [ProfileState]; nothing arrives through route arguments.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileStatus.signedOut) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('VIGÍA Civic Dashboard'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Log Out',
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<ProfileBloc>().add(SignOutRequested()),
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    final profile = state.profile;

    if (state.status == ProfileStatus.failure && profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? 'Could not load your profile.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.read<ProfileBloc>().add(ProfileStarted()),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
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
              child: _ProfileSummary(profile: profile),
            ),
          ),

          const SizedBox(height: 24),

          // Prominent Secure Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => context.read<ProfileBloc>().add(SignOutRequested()),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final Profile profile;

  const _ProfileSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        _InfoRow(icon: Icons.person_outline, label: 'Full Name', value: profile.fullName),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.email_outlined, label: 'Email Address', value: profile.email),
        const SizedBox(height: 14),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Residence City',
          value: profile.cityName,
        ),
        const SizedBox(height: 14),
        _InfoRow(
          icon: Icons.military_tech_outlined,
          label: 'Civic Rank',
          value: '${profile.rankName} (Rank ${profile.rankId})',
        ),
        const SizedBox(height: 14),
        _InfoRow(
          icon: Icons.stars_outlined,
          label: 'Reputation Points',
          value: '${profile.experiencePoints} pts',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
