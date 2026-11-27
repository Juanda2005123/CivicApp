import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/city_theme.dart';
import '../../../../core/widgets/sign_in_required_dialog.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/domain/entities/city.dart';
import '../../../auth/domain/entities/coordinates.dart';
import '../../../city_identity/ui/bloc/city_ambience_bloc.dart';
import '../../../city_identity/ui/bloc/city_ambience_event.dart';
import '../../../dashboard/ui/bloc/profile_bloc.dart';
import '../../../dashboard/ui/bloc/profile_event.dart';
import '../../../dashboard/ui/bloc/profile_state.dart';
import '../../../dashboard/ui/pages/profile_page.dart';
import '../../../notifications/ui/bloc/push_bloc.dart';
import '../../../notifications/ui/bloc/push_event.dart';
import '../../domain/entities/report_filter.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../pages/feed_page.dart';
import '../pages/map_page.dart';
import 'package:vigia_app/core/widgets/city/city_motion.dart';

/// Icon of a tab. In a city the active one sits in a pill of its accent; the
/// default look has a transparent pill.
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _NavIcon(this.icon, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.navPillWidth,
      height: AppSizes.navPillHeight,
      alignment: Alignment.center,
      decoration: active
          ? ShapeDecoration(color: CityTheme.of(context).navPill, shape: const StadiumBorder())
          : null,
      child: Icon(icon),
    );
  }
}

/// The shell: host Screen with the bottom navigation bar. Each tab is a Page;
/// `IndexedStack` keeps them alive, so switching tabs does not reload the map
/// nor the feed. The city the map shows is the one the Comunidad feed lists
/// (HU-19): the shell forwards every change of it from the [MapBloc] to the
/// [FeedBloc] and to the [CityAmbienceBloc], which dresses the app for it. The
/// citizen's own city, from the profile, gives the places of their rank climb.
/// A guest (HU-22) browses the same shell; actions that need an account open the
/// sign-in modal instead.
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

  /// City the shell showed last; a different one is a switch (HU-21).
  String? _shownCity;

  bool _pushStarted = false;

  @override
  void initState() {
    super.initState();
    // The map may have resolved its city, and the profile loaded, before this
    // screen was built.
    final city = context.read<MapBloc>().state.city;
    if (city != null) _showCity(city);
    final home = context.read<ProfileBloc>().state.profile?.cityName;
    if (home != null) _showReferenceCity(home);
    final map = context.read<MapBloc>().state.status;
    if (map == MapStatus.success || map == MapStatus.failure) _startPushes();
  }

  /// Turns on the pushes (HU-24) after the first load of the map, which is when
  /// the location was asked. Asking for both permissions at once makes Android
  /// drop one of them: on a fresh install the location request never answered
  /// and the map and the feed stayed loading. Absent in tests without pushes.
  void _startPushes() {
    if (_pushStarted) return;
    _pushStarted = true;
    context.read<PushBloc?>()?.add(const PushStarted());
  }

  /// The feed lists the city of the map and the app wears its look.
  void _showCity(City city) {
    final switched = _shownCity != null && _shownCity != city.name;
    _shownCity = city.name;
    context.read<FeedBloc>().add(FeedCityChanged(city));
    context.read<CityAmbienceBloc?>()?.add(
          ActiveCityChanged(name: city.name, department: city.department, switched: switched),
        );
  }

  /// Absent only in tests that pump the shell without the app around it.
  void _showReferenceCity(String name) =>
      context.read<CityAmbienceBloc?>()?.add(ReferenceCityChanged(name));

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

  /// A report was edited or deleted in its detail (HU-18): the map, the feed and
  /// the profile (its XP changes when a report is deleted) read again.
  void _reloadReports() {
    context.read<MapBloc>().add(MapStarted());
    context.read<FeedBloc>().add(FeedRefreshed());
    context.read<ProfileBloc>().add(ProfileRefreshed());
  }

  /// "Más cercanos" without a known position (HU-20, criterion 4): the map tries
  /// to locate the citizen. If the permission is blocked the map explains how to
  /// unblock it in its own modal; either way the answer says whether it worked.
  Future<bool> _locateForNearestOrder() async {
    final map = context.read<MapBloc>();
    if (map.state.myLocation != null) return true;

    final answer = map.stream.firstWhere((state) =>
        state.myLocationStatus == MyLocationStatus.found ||
        state.myLocationStatus == MyLocationStatus.failure ||
        state.myLocationStatus == MyLocationStatus.blocked);
    map.add(MyLocationRequested());
    final state = await answer;
    return state.myLocationStatus == MyLocationStatus.found && state.myLocation != null;
  }

  @override
  Widget build(BuildContext context) {
    // Forwarding the city is a side effect, so it runs once per change here and
    // never in a builder. The same city again does nothing in the FeedBloc.
    return MultiBlocListener(
      listeners: [
        BlocListener<MapBloc, MapState>(
          listenWhen: (previous, current) =>
              previous.status == MapStatus.loading && current.status != MapStatus.loading,
          listener: (context, state) => _startPushes(),
        ),
        BlocListener<MapBloc, MapState>(
          listenWhen: (previous, current) => current.city != null && previous.city != current.city,
          listener: (context, state) => _showCity(state.city!),
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) =>
              current.profile != null && previous.profile?.cityName != current.profile!.cityName,
          listener: (context, state) => _showReferenceCity(state.profile!.cityName),
        ),
      ],
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
              icon: const Icon(LucideIcons.logOut),
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
              // The filters of Comunidad also narrow the pins (HU-20, criterion 5).
              BlocSelector<FeedBloc, FeedState, ReportFilter>(
                selector: (state) => state.filter,
                builder: (context, filter) => MapPage(
                  filter: filter,
                  onClearFilters: () => context.read<FeedBloc>().add(FeedFiltersCleared()),
                  onReportChanged: _reloadReports,
                ),
              ),
              // Only the position matters to the feed: the distance of each card.
              BlocSelector<MapBloc, MapState, Coordinates?>(
                selector: (state) => state.myLocation,
                builder: (context, myLocation) => FeedPage(
                  myLocation: myLocation,
                  onReportPressed: () => _onReportPressed(isGuest),
                  onLocationNeeded: _locateForNearestOrder,
                  onReportChanged: _reloadReports,
                ),
              ),
              ProfilePage(onReportPressed: () => _onReportPressed(isGuest)),
            ].indexed)
              TickerMode(enabled: index == _tab, child: page),
          ],
        ),
      ),
      floatingActionButton: PressScale(child: FloatingActionButton.extended(
        onPressed: () => _onReportPressed(isGuest),
        icon: const Icon(LucideIcons.mapPinPlus),
        label: const Text('Reportar daño'),
      )),
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
              icon: _NavIcon(LucideIcons.map),
              activeIcon: _NavIcon(LucideIcons.map, active: true),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(LucideIcons.usersRound),
              activeIcon: _NavIcon(LucideIcons.usersRound, active: true),
              label: 'Comunidad',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(LucideIcons.circleUserRound),
              activeIcon: _NavIcon(LucideIcons.circleUserRound, active: true),
              label: 'Mi perfil',
            ),
          ],
        ),
      ),
    );
  }
}
