import 'package:equatable/equatable.dart';
import '../../domain/entities/incident.dart';

enum IncidentDetailStatus {
  initial,
  loading,
  success,
  failure,
}

/// State representation for the report detail screen (HU-14).
class IncidentDetailState extends Equatable {
  final IncidentDetailStatus status;
  final Incident? incident;
  final String? errorMessage;

  const IncidentDetailState({
    this.status = IncidentDetailStatus.initial,
    this.incident,
    this.errorMessage,
  });

  IncidentDetailState copyWith({
    IncidentDetailStatus? status,
    Incident? incident,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return IncidentDetailState(
      status: status ?? this.status,
      incident: incident ?? this.incident,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, incident, errorMessage];
}
