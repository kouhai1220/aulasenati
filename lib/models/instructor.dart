class Instructor {
  final int? instructorId;
  final String nombres;
  final String apellidos;
  final String correo;
  final String estado;
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  Instructor({
    this.instructorId,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.estado,
    this.syncStatus = 'pending',
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Instructor.fromMap(Map<String, dynamic> map) {
    return Instructor(
      instructorId: map['instructor_id'] as int?,
      nombres: map['nombres'] as String,
      apellidos: map['apellidos'] as String,
      correo: map['correo'] as String,
      estado: map['estado'] as String,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (instructorId != null) 'instructor_id': instructorId,
      'nombres': nombres,
      'apellidos': apellidos,
      'correo': correo,
      'estado': estado,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}