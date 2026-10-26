import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';

void main() {
  test('starts following the system theme', () {
    expect(ThemeCubit().state, ThemeMode.system);
  });

  test('toggling from a light screen goes dark, and back', () {
    final cubit = ThemeCubit();

    cubit.toggle(Brightness.light);
    expect(cubit.state, ThemeMode.dark);

    cubit.toggle(Brightness.dark);
    expect(cubit.state, ThemeMode.light);
  });
}
