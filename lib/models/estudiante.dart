// ============================================================================
// MODELO: ESTUDIANTE
// ----------------------------------------------------------------------------
// Representa a un estudiante, identificado por su código institucional.
//   - fromMap(): fila de la BD -> objeto Estudiante.
//   - toMap()  : objeto Estudiante -> mapa para guardar en la BD.
// ============================================================================

class Estudiante {
  final int? estudianteId;
  final String codigoInstitucional;
  final String nombres;
  final String apellidos;
  final String estado;
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  Estudiante({
    this.estudianteId,
    required this.codigoInstitucional,
    required this.nombres,
    required this.apellidos,
    this.estado = 'activo',
    this.syncStatus = 'pending',
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Crea un Estudiante desde una fila (mapa) de la base de datos.
  factory Estudiante.fromMap(Map<String, dynamic> map) {
    return Estudiante(
      estudianteId: map['estudiante_id'] as int?,
      codigoInstitucional: map['codigo_institucional'] as String,
      nombres: map['nombres'] as String,
      apellidos: map['apellidos'] as String,
      estado: map['estado'] as String? ?? 'activo',
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // Convierte el Estudiante en un mapa para insertarlo/actualizarlo en la BD.
  Map<String, dynamic> toMap() {
    return {
      if (estudianteId != null) 'estudiante_id': estudianteId,
      'codigo_institucional': codigoInstitucional,
      'nombres': nombres,
      'apellidos': apellidos,
      'estado': estado,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}