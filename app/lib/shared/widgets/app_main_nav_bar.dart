import 'dart:async';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:bola_na_rede/core/routes/app_routes.dart';

class AppMainNavBar extends StatelessWidget {
  final int currentIndex;

  const AppMainNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2E7D32);
    const inactiveColor = Color(0xFF757575);

    final tabs = [
      _TabData(PhosphorIcons.house(), 'Início', AppRoutes.home),
      _TabData(PhosphorIcons.magnifyingGlass(), 'Buscar', AppRoutes.search),
      _TabData(PhosphorIcons.calendar(), 'Partidas', AppRoutes.matchList),
      _TabData(PhosphorIcons.trophy(), 'Ranking', AppRoutes.ranking),
      _TabData(PhosphorIcons.user(), 'Perfil', AppRoutes.profile),
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final isActive = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i != currentIndex) {
                  unawaited(Navigator.pushNamed(context, tab.route));
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, color: isActive ? activeColor : inactiveColor),
                  const SizedBox(height: 2),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
}

class _TabData {
  final IconData icon;
  final String label;
  final String route;

  const _TabData(this.icon, this.label, this.route);
}
