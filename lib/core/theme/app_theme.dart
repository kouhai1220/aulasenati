
// ============================================================================
// TEMA VISUAL GLOBAL
// ----------------------------------------------------------------------------
// Construye el ThemeData que da estilo a toda la app: colores, tipografía,
// apariencia de las tarjetas, barras superiores y botones flotantes.
// ============================================================================

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppTheme {
  // Color principal de la marca (azul SENATI), tomado de las constantes.
  static const Color primaryColor =
      Color(AppConstants.primaryColorValue);

  // Color de fondo general de las pantallas.
  static const Color backgroundColor =
      Color(AppConstants.backgroundColorValue);

  // Color de fondo de las tarjetas.
  static const Color cardColor =
      Color(AppConstants.cardColorValue);

  // Tema "claro" de la aplicación (modo de color que se aplica globalmente).
  static ThemeData get lightTheme {
    return ThemeData(
      // Usa las pautas de diseño Material 3.
      useMaterial3: true,
      fontFamily: AppConstants.primaryFont,
      scaffoldBackgroundColor: backgroundColor,

      // Esquema de colores generado a partir del color principal.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: cardColor,
      ),

      // Estilo de las barras superiores (AppBar).
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Estilo por defecto de todas las tarjetas (bordes redondeados, sombra).
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // Estilo de la barra de navegación inferior.
      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.blueGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
        ),
      ),

      // Estilo del botón flotante (FloatingActionButton).
      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
