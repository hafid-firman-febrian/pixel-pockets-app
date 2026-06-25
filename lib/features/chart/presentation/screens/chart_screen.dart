import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';

/// Placeholder until the chart feature lands. Exists so the CHART nav tab has a
/// branch — shell branches are positional, so every nav item needs one.
class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'CHART — coming soon',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
