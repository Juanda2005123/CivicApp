import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/report_filter.dart';

/// Search bar and filters of Comunidad (HU-20): a text field, three chips
/// (categoría, barrio, orden) that open a sheet each, and, while a filter is on,
/// how many reports match with a one-tap "Limpiar filtros". Pure UI: it draws
/// the [filter] and reports what the citizen did.
class FeedFilterBar extends StatefulWidget {
  final ReportFilter filter;

  /// How many reports match the filter; null hides the count (nothing filtered).
  final int? resultCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onCategoryPressed;
  final VoidCallback onNeighborhoodPressed;
  final VoidCallback onSortPressed;
  final VoidCallback onClearFilters;

  const FeedFilterBar({
    super.key,
    required this.filter,
    required this.resultCount,
    required this.onQueryChanged,
    required this.onCategoryPressed,
    required this.onNeighborhoodPressed,
    required this.onSortPressed,
    required this.onClearFilters,
  });

  @override
  State<FeedFilterBar> createState() => _FeedFilterBarState();
}

class _FeedFilterBarState extends State<FeedFilterBar> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.filter.query;
  }

  /// "Limpiar filtros" empties the bloc's search from outside: the field follows.
  @override
  void didUpdateWidget(FeedFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.filter.query,
        selection: TextSelection.collapsed(offset: widget.filter.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = widget.filter;
    final count = widget.resultCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyLarge,
            onChanged: (value) {
              widget.onQueryChanged(value);
              setState(() {});
            },
            decoration: InputDecoration(
              // Short on purpose: a longer hint is cut off on a 375 dp phone.
              hintText: 'Buscar reportes',
              prefixIcon: const Icon(Icons.search, size: AppSizes.icon),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.close, size: AppSizes.icon),
                      onPressed: () {
                        _controller.clear();
                        widget.onQueryChanged('');
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // A Wrap, not a scrolling row: on a narrow phone, or with larger text,
          // the chips go to a second line and none is hidden off the edge.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _FilterChip(
                icon: Icons.category_outlined,
                label: filter.categoryName ?? 'Categoría',
                selected: filter.categoryName != null,
                onPressed: widget.onCategoryPressed,
              ),
              _FilterChip(
                icon: Icons.holiday_village_outlined,
                label: filter.neighborhood ?? 'Barrio',
                selected: filter.neighborhood != null,
                onPressed: widget.onNeighborhoodPressed,
              ),
              _FilterChip(
                icon: Icons.sort,
                label: filter.sort.labelSpanish,
                selected: false,
                onPressed: widget.onSortPressed,
              ),
            ],
          ),
          if (filter.isActive && count != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    count == 1 ? '1 reporte coincide' : '$count reportes coinciden',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                // With no match the empty state already offers it: one button, not two.
                if (count > 0) TextButton(onPressed: widget.onClearFilters, child: const Text('Limpiar filtros')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A chip that opens a sheet. The one with a value shows it, in bold, with a
/// check: the filter that is on is never told by color alone.
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterChip({required this.icon, required this.label, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      showCheckmark: selected,
      avatar: selected ? null : Icon(icon, size: AppSizes.icon),
      label: Text(label),
      labelStyle: selected ? const TextStyle(fontWeight: FontWeight.w700) : null,
      onSelected: (_) => onPressed(),
    );
  }
}
