import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';

import '../bloc/resolution_bloc.dart';
import '../bloc/resolution_event.dart';
import '../bloc/resolution_state.dart';

/// Opens the "Reportar como reparado" form (HU-25, criterion 1) over the detail,
/// sharing its [ResolutionBloc]. It closes by itself once the proposal is sent.
Future<void> showResolutionProposalSheet(BuildContext context) {
  final bloc = context.read<ResolutionBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: bloc, child: const ResolutionProposalSheet()),
  );
}

/// The form: one mandatory repair photo and a description of the road now.
/// Stateful only to own the text field.
class ResolutionProposalSheet extends StatefulWidget {
  const ResolutionProposalSheet({super.key});

  @override
  State<ResolutionProposalSheet> createState() => _ResolutionProposalSheetState();
}

class _ResolutionProposalSheetState extends State<ResolutionProposalSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<ResolutionBloc>();

    return BlocConsumer<ResolutionBloc, ResolutionState>(
      listenWhen: (previous, current) => previous.submittedCount != current.submittedCount,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final busy = state.isSubmitting;
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.screen,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reportar como reparado', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                AppNotice(
                  message: state.viewerIsAuthor
                      ? 'Eres el autor: al enviar la foto, el reporte quedará resuelto de inmediato.'
                      : 'Tu propuesta quedará en verificación: con 3 confirmaciones de vecinos el reporte '
                          'queda resuelto y ganas +50 XP.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Foto de la reparación (obligatoria)', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                if (state.draftPhoto != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadii.small,
                        child: Image.memory(
                          state.draftPhoto!.bytes,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          semanticLabel: 'Foto de la reparación adjunta',
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120,
                            alignment: Alignment.center,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(LucideIcons.image, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: IconButton.filledTonal(
                          tooltip: 'Quitar la foto',
                          onPressed: busy ? null : () => bloc.add(const ResolutionPhotoRemoved()),
                          icon: const Icon(LucideIcons.x),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => bloc.add(const ResolutionPhotoRequested(fromCamera: true)),
                          icon: const Icon(LucideIcons.camera, size: AppSizes.icon),
                          label: const Text('Tomar foto'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => bloc.add(const ResolutionPhotoRequested()),
                          icon: const Icon(LucideIcons.imagePlus, size: AppSizes.icon),
                          label: const Text('Galería'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _controller,
                  enabled: !busy,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: IncidentResolution.maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '¿Cómo quedó la vía?',
                    hintText: 'Ej.: Taparon el hueco con asfalto nuevo y ya se puede pasar.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final ready = state.draftPhoto != null &&
                        value.text.trim().length >= IncidentResolution.minDescriptionLength;
                    return PrimaryButton(
                      label: 'Enviar evidencia',
                      loadingLabel: 'Enviando…',
                      isLoading: busy,
                      onPressed: ready ? () => bloc.add(ResolutionProposalSubmitted(_controller.text)) : null,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Necesitas una foto y al menos ${IncidentResolution.minDescriptionLength} caracteres.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
