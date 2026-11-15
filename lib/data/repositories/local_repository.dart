// ============================================================================
// REPOSITORIO LOCAL (CAPA DE ACCESO A DATOS)
// ----------------------------------------------------------------------------
// Centraliza TODAS las operaciones contra la base de datos SQLite (insertar,
// consultar, actualizar). Las pantallas de la app usan esta clase en lugar de
// escribir SQL directamente, manteniendo el código de la interfaz más limpio.
// ============================================================================

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
  // Se reutiliza la conexión única que entrega DatabaseHelper.
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Getter corregido de la base de datos
  Future<Database> get _database async {
    return await _databaseHelper.database;
  }

  // ============================================================
  // INSTRUCTORES
  // ============================================================

  // Registra un nuevo instructor en la base de datos.
  Future<int> insertarInstructor(Instructor instructor) async {
    final db = await _database;
    return db.insert(
      'instructor',
      instructor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Devuelve todos los instructores ordenados por nombre.
  Future<List<Instructor>> obtenerInstructores() async {
    final db = await _database;
    final resultado = await db.query(
      'instructor',
      orderBy: 'nombres ASC',
    );
    return resultado.map((e) => Instructor.fromMap(e)).toList();
  }

  // Busca un instructor por su correo (o null si no existe).
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

  // Crea un nuevo grupo (sección) en la base de datos.
  Future<int> insertarGrupo(Grupo grupo) async {
    final db = await _database;
    return db.insert(
      'grupo',
      grupo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Lista los grupos ACTIVOS, mostrando primero los más recientes.
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

  // Busca un grupo por su id (o null si no existe).
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

  // Registra un nuevo estudiante en la base de datos.
  Future<int> insertarEstudiante(Estudiante estudiante) async {
    final db = await _database;
    return db.insert(
      'estudiante',
      estudiante.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Lista los estudiantes ACTIVOS ordenados por apellido.
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

  // Busca un estudiante por su id (o null si no existe).
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

  // Vincula (incorpora) un estudiante a un grupo.
  Future<void> incorporarEstudianteAGrupo(GrupoEstudiante relacion) async {
    final db = await _database;
    await db.insert(
      'grupo_estudiante',
      relacion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Devuelve los estudiantes ACTIVOS que pertenecen a un grupo.
  // Usa un JOIN entre estudiante y la tabla intermedia grupo_estudiante.
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

  // Indica si un estudiante pertenece (activamente) a un grupo.
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

  // Crea una nueva sesión (clase) para un grupo.
  Future<int> insertarSesion(Sesion sesion) async {
    final db = await _database;
    return db.insert(
      'sesion',
      sesion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Lista todas las sesiones, de la más reciente a la más antigua.
  Future<List<Sesion>> obtenerSesiones() async {
    final db = await _database;
    final resultado = await db.query(
      'sesion',
      orderBy: 'fecha DESC',
    );
    return resultado.map((e) => Sesion.fromMap(e)).toList();
  }

  // Lista las sesiones de un grupo específico (para los reportes por grupo).
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

  // Guarda (crea o actualiza) la asistencia de un estudiante en una sesión.
  // Se ejecuta dentro de una TRANSACCIÓN para validar todo antes de escribir:
  //   1. El estado debe ser uno de los permitidos.
  //   2. La sesión debe existir.
  //   3. El estudiante debe pertenecer al grupo de esa sesión.
  // Si ya existía un registro para esa sesión/estudiante, lo ACTUALIZA.
  Future<int> guardarAsistencia(Asistencia asistencia) async {
    const estadosPermitidos = ['presente', 'tardanza', 'falta', 'justificado'];

    if (!estadosPermitidos.contains(asistencia.estado)) {
      throw ArgumentError('Estado de asistencia no válido.');
    }

    final db = await _database;

    return db.transaction((txn) async {
      // Verifica que la sesión exista.
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

      // Verifica que el estudiante pertenezca al grupo de la sesión.
      final pertenencia = await txn.query(
        'grupo_estudiante',
        where: 'grupo_id = ? AND estudiante_id = ? AND estado = ?',
        whereArgs: [grupoId, asistencia.estudianteId, 'activo'],
        limit: 1,
      );

      if (pertenencia.isEmpty) {
        throw Exception('El estudiante no pertenece al grupo de esta sesión.');
      }

      // Busca si ya había un registro previo de asistencia.
      final existente = await txn.query(
        'asistencia',
        where: 'sesion_id = ? AND estudiante_id = ?',
        whereArgs: [asistencia.sesionId, asistencia.estudianteId],
        limit: 1,
      );

      // Prepara los datos a escribir (sin id ni fecha de registro original).
      final datos = asistencia.toMap()
        ..remove('asistencia_id')
        ..remove('fecha_registro');

      datos['fecha_actualizacion'] = DateTime.now().toIso8601String();

      // Si ya existía, se actualiza; si no, se inserta uno nuevo.
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

  // Devuelve todas las asistencias registradas en una sesión.
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

  // Devuelve todo el historial de asistencias de un estudiante.
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

  // Crea un nuevo tipo de actividad puntuable.
  Future<int> insertarActividad(Actividad actividad) async {
    final db = await _database;
    return db.insert(
      'actividad',
      actividad.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Lista las actividades activas ordenadas por nombre.
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

  // Registra puntos de participación de un estudiante.
  // Se ejecuta en una TRANSACCIÓN que valida, en orden:
  //   1. Que los puntos sean mayores que cero.
  //   2. Que no exista ya la misma operación (evita duplicados).
  //   3. Que la sesión exista.
  //   4. Que el estudiante pertenezca al grupo de la sesión.
  //   5. Que la actividad exista y esté activa.
  Future<int> registrarParticipacion(Participacion participacion) async {
    if (participacion.puntos <= 0) {
      throw ArgumentError('Los puntos deben ser mayores que cero.');
    }

    final db = await _database;

    return db.transaction((txn) async {
      // Si la operación ya fue registrada, devuelve su id (evita duplicados).
      final operacionExistente = await txn.query(
        'participacion',
        where: 'operacion_id = ?',
        whereArgs: [participacion.operacionId],
        limit: 1,
      );

      if (operacionExistente.isNotEmpty) {
        return operacionExistente.first['participacion_id'] as int;
      }

      // Verifica que la sesión exista.
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

      // Verifica que el estudiante pertenezca al grupo de la sesión.
      final pertenencia = await txn.query(
        'grupo_estudiante',
        where: 'grupo_id = ? AND estudiante_id = ? AND estado = ?',
        whereArgs: [grupoId, participacion.estudianteId, 'activo'],
        limit: 1,
      );

      if (pertenencia.isEmpty) {
        throw Exception('El estudiante no pertenece al grupo de esta sesión.');
      }

      // Verifica que la actividad exista y esté activa.
      final actividad = await txn.query(
        'actividad',
        where: 'actividad_id = ? AND estado = ?',
        whereArgs: [participacion.actividadId, 'activo'],
        limit: 1,
      );

      if (actividad.isEmpty) {
        throw Exception('La actividad no existe o está inactiva.');
      }

      // Inserta el registro de participación.
      return txn.insert(
        'participacion',
        participacion.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  // Devuelve las participaciones (puntos) registradas en una sesión.
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

  
  // ============================================================
  // REPORTES - CALIFICACIONES CONSOLIDADAS
  // ============================================================

  // Genera el reporte de calificaciones: por cada estudiante del grupo,
  // suma TODOS sus puntos de participación (columna total_puntos).
  // Parámetros opcionales:
  //   - sesionId    : limita la suma a una sola sesión.
  //   - estudianteId: limita el resultado a un solo estudiante.
  Future<List<Map<String, dynamic>>> obtenerReporteCalificaciones({
    required int grupoId,
    int? sesionId,
    int? estudianteId,
  }) async {
    final db = await _database;

    final resultado = await db.rawQuery('''
      SELECT
        e.estudiante_id,
        e.codigo_institucional,
        e.nombres,
        e.apellidos,
        COALESCE(SUM(p.puntos), 0) AS total_puntos

      FROM estudiante e

      INNER JOIN grupo_estudiante ge
        ON ge.estudiante_id = e.estudiante_id

      LEFT JOIN sesion s
        ON s.grupo_id = ge.grupo_id

      LEFT JOIN participacion p
        ON p.estudiante_id = e.estudiante_id
        AND p.sesion_id = s.sesion_id

      WHERE ge.grupo_id = ?
        AND ge.estado = 'activo'
        AND e.estado = 'activo'
        AND (? IS NULL OR s.sesion_id = ?)
        AND (? IS NULL OR e.estudiante_id = ?)

      GROUP BY
        e.estudiante_id,
        e.codigo_institucional,
        e.nombres,
        e.apellidos

      ORDER BY e.apellidos ASC, e.nombres ASC
    ''', [
      grupoId,
      sesionId,
      sesionId,
      estudianteId,
      estudianteId,
    ]);

    return resultado;
  }

}