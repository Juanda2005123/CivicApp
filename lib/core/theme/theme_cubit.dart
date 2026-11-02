import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-wide theme mode. It starts following the system and, once the user taps
/// the toggle, keeps the choice until the app is closed.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  /// Switches to the opposite of the theme being shown right now, so the first
  /// tap always changes what the user sees, even while following the system.
  void toggle(Brightness current) {
    emit(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
