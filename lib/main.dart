
// ============================================================================
// PUNTO DE ENTRADA DE LA APLICACIÓN "AULA PUNTOS - SENATI"
// ----------------------------------------------------------------------------
// Esta aplicación permite a un instructor/a:
//   1. Registrar grupos de estudiantes.
//   2. Programar sesiones académicas por grupo.
//   3. Controlar la asistencia (presente, tardanza, falta, justificado).
//   4. Otorgar puntos de participación.
//   5. Generar reportes consolidados y exportarlos a PDF / Excel.
// Toda la información se almacena LOCALMENTE en una base de datos SQLite,
// por lo que la aplicación funciona sin conexión a internet (modo offline).
// ============================================================================

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

// Función principal: es lo primero que se ejecuta al abrir la aplicación.
Future<void> main() async {
  // Inicializa los componentes nativos de Flutter antes de usar plugins/SQLite.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar SQLite FFI únicamente en Windows.
  // (En Windows la base de datos se abre mediante esta librería nativa.)
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Arranca la interfaz gráfica de la aplicación.
  runApp(const AulaPuntosApp());
}

// Widget raíz de la aplicación: configura el tema y la pantalla inicial.
class AulaPuntosApp extends StatelessWidget {
  const AulaPuntosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AULA PUNTOS - SENATI',
      // Oculta la cinta de "debug" de Flutter en la esquina superior.
      debugShowCheckedModeBanner: false,
      // Aplica el tema visual global (colores SENATI, fuentes, tarjetas).
      theme: AppTheme.lightTheme,
      // Pantalla inicial: el contenedor principal con la barra de navegación.
      home: const MainNavigationScreen(),
    );
  }
}

// Contenedor principal que agrupa las 6 pantallas de la app y permite
// cambiar entre ellas mediante la barra de navegación inferior.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Índice de la pestaña actualmente visible (0 = Inicio).
  int _currentIndex = 0;

  // Cambia la pantalla activa cuando el usuario pulsa un ítem del menú.
  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene todas las pantallas "vivas" en memoria y solo
      // muestra la del índice actual; así se conserva el estado de cada una.
      body: IndexedStack(
        index: _currentIndex,
       children: [
        // 0. Panel de inicio (resumen y accesos rápidos).
        DashboardScreen(
          onNavigate: _changePage,
          isActive: _currentIndex == 0,
        ),
        // 1. Gestión de grupos de estudiantes.
        GroupsScreen(),
        // 2. Sesiones académicas por grupo.
        const SessionsScreen(),
        // 3. Control de asistencia.
        AttendanceScreen(isActive: _currentIndex == 3),
        // 4. Registro de participación (puntos).
        ParticipationScreen(isActive: _currentIndex == 4),
        // 5. Reportes y exportación (PDF/Excel).
        const ReportsScreen(),
      ],
      ),
      // Barra inferior de navegación con las 6 pestañas.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _changePage,
      ),
    );
  }
}
