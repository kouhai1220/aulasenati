
// ============================================================================
// DEFINICIÓN DEL ESQUEMA DE LA BASE DE DATOS (TABLAS SQL)
// ----------------------------------------------------------------------------
// Contiene el "script" SQL de creación de cada tabla del sistema. Estas tablas
// modelan el dominio académico: instructor, grupo, estudiante, sesión,
// asistencia, actividad y participación.
// ============================================================================

class DatabaseTables {
  // Estados de sincronización local
  // (la app es offline; este campo se usa para una futura sincronización
  //  con un servidor, marcando si un registro está pendiente o ya subido).
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
  static const String syncError = 'error';

  // 1. INSTRUCTOR
  // Datos del docente que usa el sistema (nombre, correo, estado).
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
  // Grupo o sección de estudiantes, asociado a un instructor.
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
  // Datos personales y código institucional del estudiante.
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
  // Tabla intermedia: relaciona qué estudiantes pertenecen a qué grupo
  // (relación muchos-a-muchos entre grupo y estudiante).
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
  // Cada clase o encuentro académico de un grupo, con fecha y tema.
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
  // Registro de asistencia de un estudiante en una sesión.
  // El estado solo admite: presente, tardanza, falta o justificado.
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
  // Tipo de actividad que otorga puntos (ej. "Participación en clase").
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
  // Puntos otorgados a un estudiante en una sesión por una actividad.
  // "operacion_id" evita registrar dos veces la misma operación (idempotencia).
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
  // (respeta las dependencias: primero las que no tienen claves foráneas).
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
