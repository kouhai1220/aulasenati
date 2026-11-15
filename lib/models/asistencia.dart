// ============================================================================
// MODELO: ASISTENCIA
// ----------------------------------------------------------------------------
// Representa la asistencia de un estudiante en una sesión.
// El campo "estado" puede ser: presente, tardanza, falta o justificado.
//   - fromMap(): fila de la BD -> objeto Asistencia.
//   - toMap()  : objeto Asistencia -> mapa para guardar en la BD.
// ============================================================================

class Asistencia {
  final int? asistenciaId;
  final int sesionId;
  final int estudianteId;
  final String estado;
  final String fechaRegistro;
  final String? fechaActualizacion;
  final String? observacion;
  final String syncStatus;

  Asistencia({
    this.asistenciaId,
    required this.sesionId,
    required this.estudianteId,
    required this.estado,
    String? fechaRegistro,
    this.fechaActualizacion,
    this.observacion,
    this.syncStatus = 'pending',
  }) : fechaRegistro =
            fechaRegistro ?? DateTime.now().toIso8601String();

  // Crea una Asistencia desde una fila (mapa) de la base de datos.
  factory Asistencia.fromMap(Map<String, dynamic> map) {
    return Asistencia(
      asistenciaId: map['asistencia_id'] as int?,
      sesionId: map['sesion_id'] as int,
      estudianteId: map['estudiante_id'] as int,
      estado: map['estado'] as String,
      fechaRegistro: map['fecha_registro'] as String,
      fechaActualizacion: map['fecha_actualizacion'] as String?,
      observacion: map['observacion'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  // Convierte la Asistencia en un mapa para insertarla/actualizarla en la BD.
  Map<String, dynamic> toMap() {
    return {
      if (asistenciaId != null) 'asistencia_id': asistenciaId,
      'sesion_id': sesionId,
      'estudiante_id': estudianteId,
      'estado': estado,
      'fecha_registro': fechaRegistro,
      'fecha_actualizacion': fechaActualizacion,
      'observacion': observacion,
      'sync_status': syncStatus,
    };
  }
}