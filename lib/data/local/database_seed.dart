
// ============================================================================
// DATOS INICIALES (SEED) DE LA BASE DE DATOS
// ----------------------------------------------------------------------------
// Inserta registros por defecto la primera vez que se crea la base de datos,
// para que la app tenga al menos una actividad disponible con la que puntuar.
// ============================================================================

import 'package:sqflite/sqflite.dart';

class DatabaseSeed {
  // Inserta los datos iniciales, evitando duplicados si ya existen.
  static Future<void> insertInitialData(Database db) async {
    // Fecha/hora actual en formato ISO (texto) para los campos de auditoría.
    final now = DateTime.now().toIso8601String();

    // Actividades iniciales del sistema
    final actividades = [
      {
        'nombre': 'Participación en clase',
        'descripcion': 'Participación durante la sesión académica',
        'valor_puntuacion': 1.0,
        'estado': 'activo',
      },
    ];

    for (final actividad in actividades) {
      // Se comprueba si la actividad ya está registrada para no duplicarla.
      final existente = await db.query(
        'actividad',
        columns: ['actividad_id'],
        where: 'nombre = ?',
        whereArgs: [actividad['nombre']],
        limit: 1,
      );

      if (existente.isEmpty) {
        await db.insert('actividad', {
          ...actividad,
          'created_at': now,
          'sync_status': 'pending',
        });
      }
    }
  }
}
