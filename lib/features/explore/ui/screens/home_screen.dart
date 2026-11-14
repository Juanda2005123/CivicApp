import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../dashboard/ui/bloc/profile_bloc.dart';
import '../../../dashboard/ui/bloc/profile_event.dart';
import '../../../dashboard/ui/pages/profile_page.dart';
import '../pages/map_page.dart';

/// The shell: host Screen with the bottom navigation bar. Each tab is a Page;
/// `IndexedStack` keeps both alive, so switching tabs does not reload the map.
/// Comunidad joins as a third tab with HU-19.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// The profile stays the landing tab after login (HU-19, criterion 1).
  static const int profileTab = 1;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ephemeral UI state of the host screen, so setState is the right tool.
  int _tab = HomeScreen.profileTab;

  static const _titles = ['Mapa', 'Mi perfil'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        automaticallyImplyLeading: false,
        actions: [
          const ThemeToggleButton(),
          if (_tab == HomeScreen.profileTab)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<ProfileBloc>().add(SignOutRequested()),
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: const [MapPage(), ProfilePage()],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.reportWizard),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Reportar daño'),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (index) => setState(() => _tab = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Mi perfil',
            ),
          ],
        ),
      ),
    );
  }
}
