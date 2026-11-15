abstract class CitySwitcherEvent {}

/// The switcher sheet opened: load the catalog, the recents and the shortcuts.
class CitySwitcherOpened extends CitySwitcherEvent {}

/// The citizen typed in the search box.
class CityQueryChanged extends CitySwitcherEvent {
  final String query;

  CityQueryChanged(this.query);
}
