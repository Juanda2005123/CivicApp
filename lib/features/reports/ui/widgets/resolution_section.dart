import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/sign_in_required_dialog.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';

import '../bloc/resolution_bloc.dart';
import '../bloc/resolution_event.dart';
import '../bloc/resolution_state.dart';
import 'resolution_proposal_card.dart';
import 'resolution_proposal_sheet.dart';

/// Community resolution block of the report detail (HU-25), right above the
/// discussion: the pinned pending proposal, or "Reportar como reparado", or the
/// "Reparación verificada" notice on a resolved report. [onReportChanged] tells
/// the detail to read the report again after the server decided something.
class ResolutionSection extends StatefulWidget {
  final Incident incident;
  final VoidCallback onReportChanged;

  const ResolutionSection({super.key, required this.incident, required this.onReportChanged});

  @override
  State<ResolutionSection> createState() => _ResolutionSectionState();
}

class _ResolutionSectionState extends State<ResolutionSection> {
  @override
  void initState() {
    super.initState();
    context.read<ResolutionBloc>().add(ResolutionStarted(widget.incident));
  }

  @override
  void didUpdateWidget(covariant ResolutionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incident != widget.incident) {
      context.read<ResolutionBloc>().add(ResolutionIncidentUpdated(widget.incident));
    }
  }

  void _askToSignIn() {
    showSignInRequiredDialog(
      context,
      message: 'Para verificar reparaciones necesitas una cuenta. Inicia sesión o regístrate; es gratis.',
      onSignIn: () => Navigator.pushNamed(context, AppRoutes.login),
      onRegister: () => Navigator.pushNamed(context, AppRoutes.register),
    );
  }

  Future<void> _reject() async {
    final bloc = context.read<ResolutionBloc>();
    final reason = await showDialog<String>(context: context, builder: (_) => const _RejectReasonDialog());
    if (reason != null && mounted) bloc.add(ResolutionRejected(reason));
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ResolutionBloc, ResolutionState>(
          listenWhen: (previous, current) => previous.noticeCount != current.noticeCount && current.notice != null,
          listener: (context, state) => _showMessage(context, state.notice!),
        ),
        BlocListener<ResolutionBloc, ResolutionState>(
          listenWhen: (previous, current) =>
              current.actionError != null && previous.actionError != current.actionError,
          listener: (context, state) => _showMessage(context, state.actionError!),
        ),
        BlocListener<ResolutionBloc, ResolutionState>(
          listenWhen: (previous, current) => previous.reportChangedCount != current.reportChangedCount,
          listener: (context, state) => widget.onReportChanged(),
        ),
      ],
      child: BlocBuilder<ResolutionBloc, ResolutionState>(
        builder: (context, state) {
          if (widget.incident.status == IncidentStatus.resolved) {
            return const AppNotice(
              message: 'Reparación verificada: la comunidad confirmó que este daño ya fue reparado.',
              kind: NoticeKind.success,
              icon: LucideIcons.badgeCheck,
            );
          }
          if (state.status != ResolutionLoadStatus.success) return const SizedBox.shrink();

          final resolution = state.resolution;
          if (resolution != null) {
            return ResolutionProposalCard(
              resolution: resolution,
              role: _roleOf(state),
              hasVoted: state.viewerHasVoted,
              isBusy: state.isVoting,
              now: DateTime.now(),
              onConfirm: state.isGuest
                  ? _askToSignIn
                  : () => context.read<ResolutionBloc>().add(const ResolutionConfirmed()),
              onObject: state.isGuest
                  ? _askToSignIn
                  : () => context.read<ResolutionBloc>().add(const ResolutionObjected()),
              onAccept: () => context.read<ResolutionBloc>().add(const ResolutionAccepted()),
              onReject: _reject,
            );
          }
          if (!state.canPropose) return const SizedBox.shrink();

          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.isGuest ? _askToSignIn : () => showResolutionProposalSheet(context),
              icon: const Icon(LucideIcons.wrench, size: AppSizes.icon),
              label: const Text('Reportar como reparado'),
            ),
          );
        },
      ),
    );
  }

  ResolutionViewerRole _roleOf(ResolutionState state) {
    if (state.isGuest) return ResolutionViewerRole.guest;
    if (state.viewerIsAuthor) return ResolutionViewerRole.author;
    if (state.viewerIsProponent) return ResolutionViewerRole.proponent;
    return ResolutionViewerRole.neighbor;
  }
}

/// Asks the author why they reject the proposal (RN-11: the reason is mandatory).
class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Por qué la rechazas?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Motivo',
          hintText: 'Ej.: Solo le echaron tierra, el hueco sigue ahí.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().length >= IncidentResolution.minRejectionReasonLength
                ? () => Navigator.of(context).pop(_controller.text)
                : null,
            child: const Text('Rechazar'),
          ),
        ),
      ],
    );
  }
}
