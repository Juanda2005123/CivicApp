import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/theme_cubit.dart';

/// Icon button that switches between the light and the dark theme. The icon
/// shows the theme you will get, and the tooltip says it in words.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return IconButton(
      tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon),
      onPressed: () => context.read<ThemeCubit>().toggle(brightness),
    );
  }
}
