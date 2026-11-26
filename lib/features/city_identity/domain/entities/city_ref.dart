import 'package:equatable/equatable.dart';

/// A city by name, as the app remembers the last one it dressed for.
class CityRef extends Equatable {
  final String name;
  final String department;

  const CityRef({required this.name, this.department = ''});

  @override
  List<Object?> get props => [name, department];
}
