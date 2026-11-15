
import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.groups_outlined),
      activeIcon: Icon(Icons.groups),
      label: 'Grupos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month_outlined),
      activeIcon: Icon(Icons.calendar_month),
      label: 'Sesiones',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.fact_check_outlined),
      activeIcon: Icon(Icons.fact_check),
      label: 'Asistencia',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.stars_outlined),
      activeIcon: Icon(Icons.stars),
      label: 'Participación',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: 'Reportes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    );
  }
}
