import 'package:sqflite/sqflite.dart';

import '../local/database_helper.dart';
import '../../models/instructor.dart';
import '../../models/grupo.dart';
import '../../models/estudiante.dart';
import '../../models/grupo_estudiante.dart';
import '../../models/sesion.dart';
import '../../models/asistencia.dart';
import '../../models/actividad.dart';
import '../../models/participacion.dart';

class LocalRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Getter corregido de la base de datos
  Future<Database> get _database async {
    return await _databaseHelper.database;
  }

  // ============================================================
  // INSTRUCTORES
  // ============================================================

  Future<int> insertarInstructor(Instructor instructor) async {
    final db = await _database;
    return db.insert(
      'instructor',
      instructor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Instructor>> obtenerInstructores() async {
    final db = await _database;
    final resultado = await db.query(
      'instructor',
      orderBy: 'nombres ASC',
    );
    return resultado.map((e) => Instructor.fromMap(e)).toList();
  }

  Future<Instructor?> obtenerInstructorPorCorreo(String correo) async {
    final db = await _database;
    final resultado = await db.query(
      'instructor',
      where: 'correo = ?',
      whereArgs: [correo],
      limit: 1,
    );
    if (resultado.isEmpty) return null;
    return Instructor.fromMap(resultado.first);
  }

  // ============================================================
  // GRUPOS
  // ============================================================

  Future<int> insertarGrupo(Grupo grupo) async {
    final db = await _database;
    return db.insert(
      'grupo',
      grupo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Grupo>> obtenerGrupos() async {
    final db = await _database;
    final resultado = await db.query(
      'grupo',
      where: 'estado = ?',
      whereArgs: ['activo'],
      orderBy: 'created_at DESC',
    );
    return resultado.map((e) => Grupo.fromMap(e)).toList();
  }

  Future<Grupo?> obtenerGrupoPorId(int grupoId) async {
    final db = await _database;
    final resultado = await db.query(
      'grupo',
      where: 'grupo_id = ?',
      whereArgs: [grupoId],
      limit: 1,
    );
    if (resultado.isEmpty) return null;
    return Grupo.fromMap(resultado.first);
  }

  // ============================================================
  // ESTUDIANTES
  // ============================================================

  Future<int> insertarEstudiante(Estudiante estudiante) async {
    final db = await _database;
    return db.insert(
      'estudiante',
      estudiante.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Estudiante>> obtenerEstudiantes() async {
    final db = await _database;
    final resultado = await db.query(
      'estudiante',
      where: 'estado = ?',
      whereArgs: ['activo'],
      orderBy: 'apellidos ASC',
    );
    return resultado.map((e) => Estudiante.fromMap(e)).toList();
  }

  Future<Estudiante?> obtenerEstudiantePorId(int estudianteId) async {
    final db = await _database;
    final resultado = await db.query(
      'estudiante',
      where: 'estudiante_id = ?',
      whereArgs: [estudianteId],
      limit: 1,
    );
    if (resultado.isEmpty) return null;
    return Estudiante.fromMap(resultado.first);
  }

  // ============================================================
  // RELACIÓN GRUPO - ESTUDIANTE
  // ============================================================

  Future<void> incorporarEstudianteAGrupo(GrupoEstudiante relacion) async {
    final db = await _database;
    await db.insert(
      'grupo_estudiante',
      relacion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Estudiante>> obtenerEstudiantesPorGrupo(int grupoId) async {
    final db = await _database;
    final resultado = await db.rawQuery('''
      SELECT e.*
      FROM estudiante e
      INNER JOIN grupo_estudiante ge
        ON e.estudiante_id = ge.estudiante_id
      WHERE ge.grupo_id = ?
        AND ge.estado = 'activo'
        AND e.estado = 'activo'
      ORDER BY e.apellidos ASC
    ''', [grupoId]);
    return resultado.map((e) => Estudiante.fromMap(e)).toList();
  }

  Future<bool> perteneceAGrupo(int grupoId, int estudianteId) async {
    final db = await _database;
    final resultado = await db.query(
      'grupo_estudiante',
      where: 'grupo_id = ? AND estudiante_id = ? AND estado = ?',
      whereArgs: [grupoId, estudianteId, 'activo'],
      limit: 1,
    );
    return resultado.isNotEmpty;
  }

  // ============================================================
  // SESIONES
  // ============================================================

  Future<int> insertarSesion(Sesion sesion) async {
    final db = await _database;
    return db.insert(
      'sesion',
      sesion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Sesion>> obtenerSesiones() async {
    final db = await _database;
    final resultado = await db.query(
      'sesion',
      orderBy: 'fecha DESC',
    );
    return resultado.map((e) => Sesion.fromMap(e)).toList();
  }

  Future<List<Sesion>> obtenerSesionesPorGrupo(int grupoId) async {
    final db = await _database;
    final resultado = await db.query(
      'sesion',
      where: 'grupo_id = ?',
      whereArgs: [grupoId],
      orderBy: 'fecha DESC',
    );
    return resultado.map((e) => Sesion.fromMap(e)).toList();
  }

  // ============================================================
  // ASISTENCIA
  // ============================================================

  Future<int> guardarAsistencia(Asistencia asistencia) async {
    const estadosPermitidos = ['presente', 'tardanza', 'falta', 'justificado'];

    if (!estadosPermitidos.contains(asistencia.estado)) {
      throw ArgumentError('Estado de asistencia no válido.');
    }

    final db = await _database;

    return db.transaction((txn) async {
      final sesion = await txn.query(
        'sesion',
        where: 'sesion_id = ?',
        whereArgs: [asistencia.sesionId],
        limit: 1,
      );

      if (sesion.isEmpty) {
        throw Exception('La sesión indicada no existe.');
      }

      final grupoId = sesion.first['grupo_id'] as int;

      final pertenencia = await txn.query(
        'grupo_estudiante',
        where: 'grupo_id = ? AND estudiante_id = ? AND estado = ?',
        whereArgs: [grupoId, asistencia.estudianteId, 'activo'],
        limit: 1,
      );

      if (pertenencia.isEmpty) {
        throw Exception('El estudiante no pertenece al grupo de esta sesión.');
      }

      final existente = await txn.query(
        'asistencia',
        where: 'sesion_id = ? AND estudiante_id = ?',
        whereArgs: [asistencia.sesionId, asistencia.estudianteId],
        limit: 1,
      );

      final datos = asistencia.toMap()
        ..remove('asistencia_id')
        ..remove('fecha_registro');

      datos['fecha_actualizacion'] = DateTime.now().toIso8601String();

      if (existente.isNotEmpty) {
        return txn.update(
          'asistencia',
          datos,
          where: 'asistencia_id = ?',
          whereArgs: [existente.first['asistencia_id']],
        );
      }

      return txn.insert(
        'asistencia',
        asistencia.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<List<Asistencia>> obtenerAsistenciasPorSesion(int sesionId) async {
    final db = await _database;
    final resultado = await db.query(
      'asistencia',
      where: 'sesion_id = ?',
      whereArgs: [sesionId],
      orderBy: 'estudiante_id ASC',
    );
    return resultado.map((e) => Asistencia.fromMap(e)).toList();
  }

  Future<List<Asistencia>> obtenerAsistenciasPorEstudiante(int estudianteId) async {
    final db = await _database;
    final resultado = await db.query(
      'asistencia',
      where: 'estudiante_id = ?',
      whereArgs: [estudianteId],
      orderBy: 'sesion_id DESC',
    );
    return resultado.map((e) => Asistencia.fromMap(e)).toList();
  }

  // ============================================================
  // ACTIVIDADES Y PARTICIPACIÓN
  // ============================================================

  Future<int> insertarActividad(Actividad actividad) async {
    final db = await _database;
    return db.insert(
      'actividad',
      actividad.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Actividad>> obtenerActividades() async {
    final db = await _database;
    final resultado = await db.query(
      'actividad',
      where: 'estado = ?',
      whereArgs: ['activo'],
      orderBy: 'nombre ASC',
    );
    return resultado.map((e) => Actividad.fromMap(e)).toList();
  }

  Future<int> registrarParticipacion(Participacion participacion) async {
    if (participacion.puntos <= 0) {
      throw ArgumentError('Los puntos deben ser mayores que cero.');
    }

    final db = await _database;

    return db.transaction((txn) async {
      final operacionExistente = await txn.query(
        'participacion',
        where: 'operacion_id = ?',
        whereArgs: [participacion.operacionId],
        limit: 1,
      );

      if (operacionExistente.isNotEmpty) {
        return operacionExistente.first['participacion_id'] as int;
      }

      final sesion = await txn.query(
        'sesion',
        where: 'sesion_id = ?',
        whereArgs: [participacion.sesionId],
        limit: 1,
      );

      if (sesion.isEmpty) {
        throw Exception('La sesión indicada no existe.');
      }

      final grupoId = sesion.first['grupo_id'] as int;

      final pertenencia = await txn.query(
        'grupo_estudiante',
        where: 'grupo_id = ? AND estudiante_id = ? AND estado = ?',
        whereArgs: [grupoId, participacion.estudianteId, 'activo'],
        limit: 1,
      );

      if (pertenencia.isEmpty) {
        throw Exception('El estudiante no pertenece al grupo de esta sesión.');
      }

      final actividad = await txn.query(
        'actividad',
        where: 'actividad_id = ? AND estado = ?',
        whereArgs: [participacion.actividadId, 'activo'],
        limit: 1,
      );

      if (actividad.isEmpty) {
        throw Exception('La actividad no existe o está inactiva.');
      }

      return txn.insert(
        'participacion',
        participacion.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<List<Participacion>> obtenerParticipacionesPorSesion(int sesionId) async {
    final db = await _database;
    final resultado = await db.query(
      'participacion',
      where: 'sesion_id = ?',
      whereArgs: [sesionId],
      orderBy: 'fecha DESC',
    );
    return resultado.map((e) => Participacion.fromMap(e)).toList();
  }

  Future<double> obtenerPuntosAcumulados(int estudianteId) async {
    final db = await _database;
    final resultado = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(puntos), 0) AS total
      FROM participacion
      WHERE estudiante_id = ?
      ''',
      [estudianteId],
    );
    return (resultado.first['total'] as num).toDouble();
  }
}