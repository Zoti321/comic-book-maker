import 'package:flutter/material.dart';

/// 项目数量 [Badge]，显示在标题旁。
class LibraryCountChip extends StatelessWidget {
  const LibraryCountChip({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Badge(
      label: Text('$count'),
      backgroundColor: scheme.primaryContainer,
      textColor: scheme.onPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: const SizedBox(width: 8, height: 20),
    );
  }
}
