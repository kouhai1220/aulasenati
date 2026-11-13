
class DatabaseTables {
  // Estados de sincronización local
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
  static const String syncError = 'error';

  // 1. INSTRUCTOR
  static const String instructor = '''
    CREATE TABLE instructor (
      instructor_id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombres TEXT NOT NULL,
      apellidos TEXT NOT NULL,
      correo TEXT NOT NULL UNIQUE,
      estado TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  // 2. GRUPO
  static const String grupo = '''
    CREATE TABLE grupo (
      grupo_id INTEGER PRIMARY KEY AUTOINCREMENT,
      codigo TEXT NOT NULL,
      nombre TEXT NOT NULL,
      periodo TEXT NOT NULL,
      instructor_id INTEGER NOT NULL,
      estado TEXT NOT NULL DEFAULT 'activo',
      sync_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT,

      FOREIGN KEY (instructor_id)
        REFERENCES instructor(instructor_id)
    )
  ''';

  // 3. ESTUDIANTE
  static const String estudiante = '''
    CREATE TABLE estudiante (
      estudiante_id INTEGER PRIMARY KEY AUTOINCREMENT,
      codigo_institucional TEXT NOT NULL UNIQUE,
      nombres TEXT NOT NULL,
      apellidos TEXT NOT NULL,
      estado TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  // 4. GRUPO_ESTUDIANTE
  static const String grupoEstudiante = '''
    CREATE TABLE grupo_estudiante (
      grupo_id INTEGER NOT NULL,
      estudiante_id INTEGER NOT NULL,
      fecha_incorporacion TEXT NOT NULL,
      estado TEXT NOT NULL DEFAULT 'activo',
      sync_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT,

      PRIMARY KEY (grupo_id, estudiante_id),

      FOREIGN KEY (grupo_id)
        REFERENCES grupo(grupo_id),

      FOREIGN KEY (estudiante_id)
        REFERENCES estudiante(estudiante_id)
    )
  ''';

  // 5. SESION
  static const String sesion = '''
    CREATE TABLE sesion (
      sesion_id INTEGER PRIMARY KEY AUTOINCREMENT,
      grupo_id INTEGER NOT NULL,
      fecha TEXT NOT NULL,
      tema TEXT,
      estado TEXT NOT NULL DEFAULT 'activa',
      sync_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT,

      FOREIGN KEY (grupo_id)
        REFERENCES grupo(grupo_id)
    )
  ''';

  // 6. ASISTENCIA
  static const String asistencia = '''
    CREATE TABLE asistencia (
      asistencia_id INTEGER PRIMARY KEY AUTOINCREMENT,
      sesion_id INTEGER NOT NULL,
      estudiante_id INTEGER NOT NULL,

      estado TEXT NOT NULL CHECK (
        estado IN (
          'presente',
          'tardanza',
          'falta',
          'justificado'
        )
      ),

      fecha_registro TEXT NOT NULL,
      fecha_actualizacion TEXT,
      observacion TEXT,
      sync_status TEXT NOT NULL DEFAULT 'pending',

      FOREIGN KEY (sesion_id)
        REFERENCES sesion(sesion_id),

      FOREIGN KEY (estudiante_id)
        REFERENCES estudiante(estudiante_id),

      UNIQUE (sesion_id, estudiante_id)
    )
  ''';

  // 7. ACTIVIDAD
  static const String actividad = '''
    CREATE TABLE actividad (
      actividad_id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      valor_puntuacion REAL NOT NULL,
      estado TEXT NOT NULL DEFAULT 'activo',
      sync_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  // 8. PARTICIPACION
  static const String participacion = '''
    CREATE TABLE participacion (
      participacion_id INTEGER PRIMARY KEY AUTOINCREMENT,
      sesion_id INTEGER NOT NULL,
      estudiante_id INTEGER NOT NULL,
      actividad_id INTEGER NOT NULL,
      puntos REAL NOT NULL CHECK (puntos > 0),
      fecha TEXT NOT NULL,
      observacion TEXT,

      
      operacion_id TEXT NOT NULL UNIQUE,

      sync_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,

      FOREIGN KEY (sesion_id)
        REFERENCES sesion(sesion_id),

      FOREIGN KEY (estudiante_id)
        REFERENCES estudiante(estudiante_id),

      FOREIGN KEY (actividad_id)
        REFERENCES actividad(actividad_id)
    )
  ''';

  // Orden de creación de las tablas
  static const List<String> allTables = [
    instructor,
    grupo,
    estudiante,
    grupoEstudiante,
    sesion,
    asistencia,
    actividad,
    participacion,
  ];
}
