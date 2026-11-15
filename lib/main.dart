
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


import 'core/theme/app_theme.dart';
import 'core/widgets/app_bottom_navigation.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/sessions/sessions_screen.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/participation/participation_screen.dart';
import 'features/reports/reports_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar SQLite FFI únicamente en Windows.
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const AulaPuntosApp());
}

class AulaPuntosApp extends StatelessWidget {
  const AulaPuntosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AULA PUNTOS - SENATI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
       children: [
  DashboardScreen(
    onNavigate: _changePage,
    isActive: _currentIndex == 0,
  ),
  GroupsScreen(),
  const SessionsScreen(),
  AttendanceScreen(isActive: _currentIndex == 3),
  ParticipationScreen(isActive: _currentIndex == 4),
  const ReportsScreen(),
],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _changePage,
      ),
    );
  }
}
