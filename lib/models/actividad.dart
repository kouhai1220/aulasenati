class Actividad {
  final int? actividadId;
  final String nombre;
  final String? descripcion;
  final double valorPuntuacion;
  final String estado;
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  Actividad({
    this.actividadId,
    required this.nombre,
    this.descripcion,
    required this.valorPuntuacion,
    this.estado = 'activo',
    this.syncStatus = 'pending',
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Actividad.fromMap(Map<String, dynamic> map) {
    return Actividad(
      actividadId: map['actividad_id'] as int?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      valorPuntuacion: (map['valor_puntuacion'] as num).toDouble(),
      estado: map['estado'] as String? ?? 'activo',
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (actividadId != null) 'actividad_id': actividadId,
      'nombre': nombre,
      'descripcion': descripcion,
      'valor_puntuacion': valorPuntuacion,
      'estado': estado,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}