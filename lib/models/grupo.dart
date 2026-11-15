// ============================================================================
// MODELO: GRUPO
// ----------------------------------------------------------------------------
// Representa un grupo o sección de estudiantes (ej. "2026-20-202601"),
// asociado a un instructor y a un periodo académico.
//   - fromMap(): fila de la BD -> objeto Grupo.
//   - toMap()  : objeto Grupo  -> mapa para guardar en la BD.
// ============================================================================

class Grupo {
  final int? grupoId;
  final String codigo;
  final String nombre;
  final String periodo;
  final int instructorId;
  final String estado;
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  Grupo({
    this.grupoId,
    required this.codigo,
    required this.nombre,
    required this.periodo,
    required this.instructorId,
    this.estado = 'activo',
    this.syncStatus = 'pending',
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Crea un Grupo desde una fila (mapa) de la base de datos.
  factory Grupo.fromMap(Map<String, dynamic> map) {
    return Grupo(
      grupoId: map['grupo_id'] as int?,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      periodo: map['periodo'] as String,
      instructorId: map['instructor_id'] as int,
      estado: map['estado'] as String? ?? 'activo',
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // Convierte el Grupo en un mapa para insertarlo/actualizarlo en la BD.
  Map<String, dynamic> toMap() {
    return {
      if (grupoId != null) 'grupo_id': grupoId,
      'codigo': codigo,
      'nombre': nombre,
      'periodo': periodo,
      'instructor_id': instructorId,
      'estado': estado,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}