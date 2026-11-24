import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/sign_in_required_dialog.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/domain/entities/coordinates.dart';
import '../../../dashboard/ui/bloc/profile_bloc.dart';
import '../../../dashboard/ui/bloc/profile_event.dart';
import '../../../dashboard/ui/bloc/profile_state.dart';
import '../../../dashboard/ui/pages/profile_page.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../pages/feed_page.dart';
import '../pages/map_page.dart';

/// The shell: host Screen with the bottom navigation bar. Each tab is a Page;
/// `IndexedStack` keeps them alive, so switching tabs does not reload the map
/// nor the feed. The city the map shows is the one the Comunidad feed lists
/// (HU-19): the shell forwards every change of it from the [MapBloc] to the
/// [FeedBloc]. A guest (HU-22) browses the same shell; actions that need an
/// account open the sign-in modal instead.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// The app opens on the map (RN-14, HU-19 criterion 1); the profile is one tap away.
  static const int mapTab = 0;
  static const int feedTab = 1;
  static const int profileTab = 2;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ephemeral UI state of the host screen, so setState is the right tool.
  int _tab = HomeScreen.mapTab;

  static const _titles = ['Mapa', 'Comunidad', 'Mi perfil'];

  @override
  void initState() {
    super.initState();
    // The map may have resolved its city before this screen was built.
    final city = context.read<MapBloc>().state.city;
    if (city != null) context.read<FeedBloc>().add(FeedCityChanged(city));
  }

  /// A guest is invited to sign in instead of opening the wizard (HU-22).
  void _onReportPressed(bool isGuest) {
    if (!isGuest) {
      _openReportWizard();
      return;
    }
    showSignInRequiredDialog(
      context,
      message: 'Para reportar un daño necesitas una cuenta. Inicia sesión o regístrate; es gratis.',
      onSignIn: () => Navigator.pushNamed(context, AppRoutes.login),
      onRegister: () => Navigator.pushNamed(context, AppRoutes.register),
    );
  }

  /// The wizard pops with the published report, or with nothing when the
  /// citizen cancels. Only a new report makes the map and the feed reload.
  Future<void> _openReportWizard() async {
    final published = await Navigator.pushNamed(context, AppRoutes.reportWizard);
    if (!mounted || published == null) return;
    context.read<MapBloc>().add(MapStarted());
    context.read<FeedBloc>().add(FeedRefreshed());
    // A new report changes the counters and the XP of "Mi perfil" (HU-23).
    context.read<ProfileBloc>().add(ProfileRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    // Forwarding the city is a side effect, so it runs once per change here and
    // never in a builder. The same city again does nothing in the FeedBloc.
    return BlocListener<MapBloc, MapState>(
      listenWhen: (previous, current) => current.city != null && previous.city != current.city,
      listener: (context, state) => context.read<FeedBloc>().add(FeedCityChanged(state.city!)),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (previous, current) =>
            (previous.status == ProfileStatus.guest) != (current.status == ProfileStatus.guest),
        builder: (context, state) => _buildShell(context, isGuest: state.status == ProfileStatus.guest),
      ),
    );
  }

  Widget _buildShell(BuildContext context, {required bool isGuest}) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        automaticallyImplyLeading: false,
        actions: [
          const ThemeToggleButton(),
          if (_tab == HomeScreen.profileTab && !isGuest)
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
          // IndexedStack keeps every tab alive but does not pause their animations:
          // a hidden tab's spinner would keep drawing frames nobody sees.
          children: [
            for (final (index, page) in [
              const MapPage(),
              // Only the position matters to the feed: the distance of each card.
              BlocSelector<MapBloc, MapState, Coordinates?>(
                selector: (state) => state.myLocation,
                builder: (context, myLocation) => FeedPage(
                  myLocation: myLocation,
                  onReportPressed: () => _onReportPressed(isGuest),
                ),
              ),
              ProfilePage(onReportPressed: () => _onReportPressed(isGuest)),
            ].indexed)
              TickerMode(enabled: index == _tab, child: page),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onReportPressed(isGuest),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Reportar daño'),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (index) {
            setState(() => _tab = index);
            // Coming to "Mi perfil" reads the numbers again: the citizen may have
            // endorsed, commented or earned points on the other tabs (HU-23).
            if (index == HomeScreen.profileTab && !isGuest) context.read<ProfileBloc>().add(ProfileRefreshed());
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Comunidad',
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
