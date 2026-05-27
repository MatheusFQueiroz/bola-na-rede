import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  static const _labels = ['Início', 'Buscar', 'Partidas', 'Ranking', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.primary;
    final inactive = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(5, (i) {
          final isActive = i == currentIndex;
          final color = isActive ? active : inactive;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icon(i, isActive), color: color, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  IconData _icon(int index, bool active) {
    final style =
        active ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular;
    return switch (index) {
      0 => PhosphorIcons.house(style),
      1 => PhosphorIcons.magnifyingGlass(style),
      2 => PhosphorIcons.calendar(style),
      3 => PhosphorIcons.trophy(style),
      _ => PhosphorIcons.user(style),
    };
  }
}
