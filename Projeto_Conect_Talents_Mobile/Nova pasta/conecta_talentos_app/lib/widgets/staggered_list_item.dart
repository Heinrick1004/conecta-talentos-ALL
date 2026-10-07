import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Entrada em cascata para cada item de listas de vagas e treinamentos.
class StaggeredListItem extends StatelessWidget {
  const StaggeredListItem({
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 60),
    super.key,
  });

  final int index;
  final Widget child;
  final Duration delayPerItem;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delayPerItem * index)
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(
          begin: 0.08,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
  }
}
