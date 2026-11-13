
import 'package:sqflite/sqflite.dart';

class DatabaseSeed {
  static Future<void> insertInitialData(Database db) async {
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
