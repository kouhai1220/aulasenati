// ============================================================================
// MODELO: GRUPO_ESTUDIANTE (relación)
// ----------------------------------------------------------------------------
// Representa la pertenencia de un estudiante a un grupo (relación N a N entre
// Grupo y Estudiante). Guarda la fecha en que el estudiante se incorporó.
// ============================================================================

class GrupoEstudiante {
  final int grupoId;
  final int estudianteId;
  final String fechaIncorporacion;
  final String estado;
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  GrupoEstudiante({
    required this.grupoId,
    required this.estudianteId,
    required this.fechaIncorporacion,
    this.estado = 'activo',
    this.syncStatus = 'pending',
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Crea la relación desde una fila (mapa) de la base de datos.
  factory GrupoEstudiante.fromMap(Map<String, dynamic> map) {
    return GrupoEstudiante(
      grupoId: map['grupo_id'] as int,
      estudianteId: map['estudiante_id'] as int,
      fechaIncorporacion: map['fecha_incorporacion'] as String,
      estado: map['estado'] as String? ?? 'activo',
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // Convierte la relación en un mapa para guardarla en la BD.
  Map<String, dynamic> toMap() {
    return {
      'grupo_id': grupoId,
      'estudiante_id': estudianteId,
      'fecha_incorporacion': fechaIncorporacion,
      'estado': estado,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}