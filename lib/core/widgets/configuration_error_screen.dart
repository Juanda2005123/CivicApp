import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown instead of the app when the Supabase credentials are missing, so the
/// problem is explicit and not hidden behind a fake backend.
class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIGÍA - Configuration required',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_outlined, size: 40, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Supabase is not configured',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Copy .env.example to .env and set SUPABASE_URL and '
                    'SUPABASE_ANON_KEY, then restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
