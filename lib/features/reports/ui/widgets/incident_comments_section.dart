import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/civic_avatar.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/core/widgets/sign_in_required_dialog.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_comment.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../bloc/comments_state.dart';
import 'package:vigia_app/core/widgets/city/city_motion.dart';
import 'package:vigia_app/core/widgets/city/city_skeleton.dart';

/// Discussion thread of a report and its composer (HU-17), shown at the end of
/// the report detail. Comments read oldest first. A guest reads them and is
/// asked to sign in to write. Stateful to own the text field and to hide
/// "Eliminar" once a comment is older than 5 minutes.
class IncidentCommentsSection extends StatefulWidget {
  final String incidentId;

  const IncidentCommentsSection({super.key, required this.incidentId});

  @override
  State<IncidentCommentsSection> createState() => _IncidentCommentsSectionState();
}

class _IncidentCommentsSectionState extends State<IncidentCommentsSection> {
  final _controller = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    context.read<CommentsBloc>().add(CommentsStarted(widget.incidentId));
    // "Eliminar" disappears by itself when the 5 minutes pass.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _askToSignIn() {
    showSignInRequiredDialog(
      context,
      message: 'Para comentar necesitas una cuenta. Inicia sesión o regístrate; es gratis.',
      onSignIn: () => Navigator.pushNamed(context, AppRoutes.login),
      onRegister: () => Navigator.pushNamed(context, AppRoutes.register),
    );
  }

  Future<void> _confirmDelete(IncidentComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar tu comentario?'),
        content: const Text('Se borrarán el texto y la foto, y perderás los 15 XP que ganaste.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          PressScale(child: FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Eliminar'))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<CommentsBloc>().add(CommentDeleted(comment));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        // A published comment empties the text field; a failure keeps it (criterion 7).
        BlocListener<CommentsBloc, CommentsState>(
          listenWhen: (previous, current) => previous.publishedCount != current.publishedCount,
          listener: (context, state) => _controller.clear(),
        ),
        BlocListener<CommentsBloc, CommentsState>(
          listenWhen: (previous, current) =>
              current.actionError != null && previous.actionError != current.actionError,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.actionError!)));
          },
        ),
      ],
      child: BlocBuilder<CommentsBloc, CommentsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.status == CommentsStatus.success ? 'Comentarios (${state.comments.length})' : 'Comentarios',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildThread(context, state, theme),
              const SizedBox(height: AppSpacing.lg),
              _buildComposer(context, state, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThread(BuildContext context, CommentsState state, ThemeData theme) {
    switch (state.status) {
      case CommentsStatus.initial:
      case CommentsStatus.loading:
        return const CitySkeleton(
          shape: CitySkeletonShape.list,
          semanticLabel: 'Cargando comentarios',
          fill: false,
        );
      case CommentsStatus.failure:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNotice(
              message: state.errorMessage ?? 'No pudimos cargar los comentarios.',
              kind: NoticeKind.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            PressScale(child: OutlinedButton(
              onPressed: () => context.read<CommentsBloc>().add(CommentsStarted(widget.incidentId)),
              child: const Text('Reintentar'),
            )),
          ],
        );
      case CommentsStatus.success:
        if (state.comments.isEmpty) {
          return Text(
            'Aún no hay comentarios. Sé la primera persona en aportar a la discusión.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          );
        }
        final now = DateTime.now();
        return Column(
          children: [
            for (final comment in state.comments)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CommentTile(
                  comment: comment,
                  canDelete: state.viewerId != null && comment.canBeDeletedBy(state.viewerId!, now: now),
                  isDeleting: state.deletingId == comment.id,
                  onDelete: () => _confirmDelete(comment),
                ),
              ),
          ],
        );
    }
  }

  Widget _buildComposer(BuildContext context, CommentsState state, ThemeData theme) {
    if (state.status != CommentsStatus.success) return const SizedBox.shrink();

    if (state.isGuest) {
      return SizedBox(
        width: double.infinity,
        child: PressScale(child: OutlinedButton.icon(
          onPressed: _askToSignIn,
          icon: const Icon(LucideIcons.lock, size: AppSizes.icon),
          label: const Text('Inicia sesión para comentar'),
        )),
      );
    }

    final bloc = context.read<CommentsBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !state.isSending,
          minLines: 2,
          maxLines: 5,
          maxLength: IncidentComment.maxTextLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Tu comentario',
            hintText: 'Cuéntanos cómo sigue el daño…',
          ),
        ),
        if (state.draftPhoto != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _DraftPhoto(
            photo: state.draftPhoto!,
            onRemove: state.isSending ? null : () => bloc.add(const CommentPhotoRemoved()),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            IconButton(
              tooltip: 'Tomar una foto',
              onPressed: state.isSending ? null : () => bloc.add(const CommentPhotoRequested(fromCamera: true)),
              icon: const Icon(LucideIcons.camera),
            ),
            IconButton(
              tooltip: 'Elegir una foto de la galería',
              onPressed: state.isSending ? null : () => bloc.add(const CommentPhotoRequested()),
              icon: const Icon(LucideIcons.imagePlus),
            ),
            const Spacer(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final canSend = (value.text.trim().isNotEmpty || state.draftPhoto != null) && !state.isSending;
                return PressScale(child: FilledButton.icon(
                  onPressed: canSend ? () => bloc.add(CommentSubmitted(_controller.text)) : null,
                  icon: state.isSending
                      ? DottedSpinner(size: 18, color: theme.colorScheme.onPrimary, semanticLabel: 'Publicando')
                      : const Icon(LucideIcons.send, size: AppSizes.icon),
                  label: Text(state.isSending ? 'Publicando…' : 'Publicar'),
                ));
              },
            ),
          ],
        ),
        Text(
          'Ganas +15 XP por cada comentario. Podrás eliminarlo durante los primeros 5 minutos.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final IncidentComment comment;
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = comment.authorName ?? 'Ciudadano anónimo';
    final rank = comment.authorRankName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.medium,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CivicAvatar(
                avatarUrl: comment.authorAvatarUrl,
                rankId: comment.authorRankLevel,
                size: 36,
                semanticLabel: 'Nivel ${comment.authorRankLevel}${rank != null ? ', $rank' : ''}',
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      [?rank, _formatDate(comment.createdAt)].join(' · '),
                      style: AppTextStyles.data(size: 12).copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.hasText) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(comment.text, style: theme.textTheme.bodyMedium),
          ],
          if (comment.hasPhoto) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadii.small,
              child: Image.network(
                comment.photoUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                semanticLabel: 'Foto del comentario de $author',
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(LucideIcons.imageOff, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
          if (canDelete) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isDeleting ? null : onDelete,
                icon: const Icon(LucideIcons.trash2, size: AppSizes.icon),
                label: Text(isDeleting ? 'Eliminando…' : 'Eliminar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// `dd/mm/aaaa hh:mm`, in the device's time.
  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _DraftPhoto extends StatelessWidget {
  final PickedPhoto photo;
  final VoidCallback? onRemove;

  const _DraftPhoto({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadii.small,
          child: Image.memory(
            photo.bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            semanticLabel: 'Foto adjunta al comentario',
            errorBuilder: (context, error, stackTrace) => Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(LucideIcons.image, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('Foto adjunta', style: theme.textTheme.bodySmall),
        ),
        IconButton(
          tooltip: 'Quitar la foto',
          onPressed: onRemove,
          icon: const Icon(LucideIcons.x),
        ),
      ],
    );
  }
}
