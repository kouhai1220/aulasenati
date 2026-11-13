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