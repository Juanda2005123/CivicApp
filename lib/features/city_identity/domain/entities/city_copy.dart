import 'package:equatable/equatable.dart';

import 'day_part.dart';

/// The words of a city. Spanish, with the voice of the place.
class CityCopy extends Equatable {
  /// Placeholder a regional look uses for the citizen's own city.
  static const String cityPlaceholder = '{ciudad}';

  final String morningGreeting;
  final String afternoonGreeting;
  final String nightGreeting;

  /// Line under the greeting ("Cali se cuida entre vecinos.").
  final String slogan;

  /// Cheer shown when a report reaches the community validation.
  final String validationCheer;

  /// Title of the rank ladder ("Tu subida al Pueblito Paisa").
  final String climbTitle;

  const CityCopy({
    required this.morningGreeting,
    required this.afternoonGreeting,
    required this.nightGreeting,
    required this.slogan,
    required this.validationCheer,
    required this.climbTitle,
  });

  String greetingFor(DayPart part) => switch (part) {
        DayPart.morning => morningGreeting,
        DayPart.afternoon => afternoonGreeting,
        DayPart.night => nightGreeting,
      };

  /// The same copy with [cityPlaceholder] replaced by [cityName].
  CityCopy forCity(String cityName) => CityCopy(
        morningGreeting: morningGreeting.replaceAll(cityPlaceholder, cityName),
        afternoonGreeting: afternoonGreeting.replaceAll(cityPlaceholder, cityName),
        nightGreeting: nightGreeting.replaceAll(cityPlaceholder, cityName),
        slogan: slogan.replaceAll(cityPlaceholder, cityName),
        validationCheer: validationCheer.replaceAll(cityPlaceholder, cityName),
        climbTitle: climbTitle.replaceAll(cityPlaceholder, cityName),
      );

  @override
  List<Object?> get props => [
        morningGreeting,
        afternoonGreeting,
        nightGreeting,
        slogan,
        validationCheer,
        climbTitle,
      ];
}
