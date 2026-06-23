import 'package:flutter/material.dart';

class SettingsTileLoadingValue extends StatelessWidget {
  const SettingsTileLoadingValue({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class SettingsTileLoading extends StatelessWidget {
  const SettingsTileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
