import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/core/constants/app_routes.dart';

import '../bloc/push_bloc.dart';
import '../bloc/push_state.dart';

/// Opens the report of a tapped push notification (HU-24, criterion 3) on top
/// of the shell it wraps.
class PushOpenedListener extends StatelessWidget {
  final Widget child;

  const PushOpenedListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PushBloc, PushState>(
      listenWhen: (previous, current) =>
          current.openedIncidentId != null && previous.openedCount != current.openedCount,
      listener: (context, state) =>
          Navigator.pushNamed(context, AppRoutes.reportDetail, arguments: state.openedIncidentId),
      child: child,
    );
  }
}
