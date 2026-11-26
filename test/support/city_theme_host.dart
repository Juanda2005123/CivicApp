import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/city_theme.dart';
import 'package:vigia_app/features/city_identity/data/datasources/city_pack_local_data_source.dart';
import 'package:vigia_app/features/city_identity/domain/entities/day_part.dart';

/// The three looks every city widget is tested with: two cities with a pack and
/// the default one (null).
const testCities = <String?>['Cali', 'Medellín', null];

/// The app theme dressed for [city] (null for the default look), as `main.dart`
/// builds it.
ThemeData cityTestTheme(
  String? city, {
  Brightness brightness = Brightness.light,
  DayPart dayPart = DayPart.afternoon,
}) {
  final packs = CityPackLocalDataSource();
  final identity = city == null ? packs.getDefaultPack() : packs.findFullPack(city)!;
  return AppTheme.build(
    brightness,
    CityTheme.from(identity, brightness, dayPart, featured: packs.getFullPacks()),
  );
}

/// A `MaterialApp` wearing [city]. [reduceMotion] sets "remove animations" for
/// the whole app, routes and overlays included.
Widget cityHost(
  Widget child, {
  String? city,
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
  double textScale = 1,
  bool scaffold = true,
}) {
  return MaterialApp(
    theme: cityTestTheme(city, brightness: brightness),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduceMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: app!,
    ),
    home: scaffold ? Scaffold(body: child) : child,
  );
}
