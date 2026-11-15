// ============================================================================
// MODELO: SESION
// ----------------------------------------------------------------------------
// Representa una sesión o clase de un grupo, con su fecha y tema.
//   - fromMap(): fila de la BD -> objeto Sesion.
//   - toMap()  : objeto Sesion -> mapa para guardar en la BD.
// ============================================================================

class Sesion {
  final int? sesionId;
  final int grupoId;
  final String fecha;
  final String? tema;
  final String estado;
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  Sesion({
    this.sesionId,
    required this.grupoId,
    required this.fecha,
    this.tema,
    this.estado = 'activa',
    this.syncStatus = 'pending',
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Crea una Sesion desde una fila (mapa) de la base de datos.
  factory Sesion.fromMap(Map<String, dynamic> map) {
    return Sesion(
      sesionId: map['sesion_id'] as int?,
      grupoId: map['grupo_id'] as int,
      fecha: map['fecha'] as String,
      tema: map['tema'] as String?,
      estado: map['estado'] as String? ?? 'activa',
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // Convierte la Sesion en un mapa para insertarla/actualizarla en la BD.
  Map<String, dynamic> toMap() {
    return {
      if (sesionId != null) 'sesion_id': sesionId,
      'grupo_id': grupoId,
      'fecha': fecha,
      'tema': tema,
      'estado': estado,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}