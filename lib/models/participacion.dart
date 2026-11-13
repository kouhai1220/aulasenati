class Participacion {
  final int? participacionId;
  final int sesionId;
  final int estudianteId;
  final int actividadId;
  final double puntos;
  final String fecha;
  final String? observacion;
  final String operacionId;
  final String syncStatus;
  final String createdAt;

  Participacion({
    this.participacionId,
    required this.sesionId,
    required this.estudianteId,
    required this.actividadId,
    required this.puntos,
    required this.fecha,
    this.observacion,
    required this.operacionId,
    this.syncStatus = 'pending',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Participacion.fromMap(Map<String, dynamic> map) {
    return Participacion(
      participacionId: map['participacion_id'] as int?,
      sesionId: map['sesion_id'] as int,
      estudianteId: map['estudiante_id'] as int,
      actividadId: map['actividad_id'] as int,
      puntos: (map['puntos'] as num).toDouble(),
      fecha: map['fecha'] as String,
      observacion: map['observacion'] as String?,
      operacionId: map['operacion_id'] as String,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (participacionId != null) 'participacion_id': participacionId,
      'sesion_id': sesionId,
      'estudiante_id': estudianteId,
      'actividad_id': actividadId,
      'puntos': puntos,
      'fecha': fecha,
      'observacion': observacion,
      'operacion_id': operacionId,
      'sync_status': syncStatus,
      'created_at': createdAt,
    };
  }
}