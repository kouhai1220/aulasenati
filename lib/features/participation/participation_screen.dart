
// ============================================================================
// PANTALLA: REGISTRO DE PARTICIPACIÓN (PUNTOS)
// ----------------------------------------------------------------------------
// Permite otorgar puntos a un estudiante por una actividad dentro de una
// sesión. Abajo se muestra el historial de participaciones de la sesión y el
// total acumulado de puntos.
// ============================================================================

import 'package:flutter/material.dart';

import '../../data/repositories/local_repository.dart';
import '../../models/actividad.dart';
import '../../models/estudiante.dart';
import '../../models/participacion.dart';
import '../../models/sesion.dart';

class ParticipationScreen extends StatefulWidget {
  final bool isActive;

  const ParticipationScreen({
    super.key,
    this.isActive = false,
  });

  @override
  State<ParticipationScreen> createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends State<ParticipationScreen> {
  final LocalRepository _repository = LocalRepository();

  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  List<Sesion> _sesiones = [];
  List<Actividad> _actividades = [];
  List<Estudiante> _estudiantes = [];
  List<Participacion> _participaciones = [];

  Sesion? _selectedSesion;
  Actividad? _selectedActividad;
  Estudiante? _selectedEstudiante;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant ParticipationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Al volver a esta pestaña, actualiza sesiones, actividades y registros.
    if (!oldWidget.isActive && widget.isActive) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  // Carga sesiones y actividades, y selecciona la primera de cada lista.
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resultados = await Future.wait([
        _repository.obtenerSesiones(),
        _repository.obtenerActividades(),
      ]);

      if (!mounted) return;

      _sesiones = resultados[0] as List<Sesion>;
      _actividades = resultados[1] as List<Actividad>;

      _selectedSesion = _sesiones.isNotEmpty ? _sesiones.first : null;
      _selectedActividad =
          _actividades.isNotEmpty ? _actividades.first : null;

      if (_selectedSesion != null) {
        await _loadSessionData(_selectedSesion!);
      } else {
        _estudiantes = [];
        _participaciones = [];
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudieron cargar los datos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Carga los estudiantes del grupo de la sesión y sus participaciones.
  Future<void> _loadSessionData(Sesion sesion) async {
    setState(() {
      _isLoading = true;
      _estudiantes = [];
      _participaciones = [];
      _selectedEstudiante = null;
    });

    try {
      final estudiantes =
          await _repository.obtenerEstudiantesPorGrupo(sesion.grupoId);

      final participaciones =
          await _repository.obtenerParticipacionesPorSesion(sesion.sesionId!);

      if (!mounted) return;

      setState(() {
        _estudiantes = estudiantes;
        _participaciones = participaciones;
        _selectedEstudiante =
            estudiantes.isNotEmpty ? estudiantes.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo cargar la sesión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Cambia la sesión seleccionada y recarga sus datos.
  Future<void> _changeSession(Sesion? sesion) async {
    if (sesion == null) return;

    setState(() {
      _selectedSesion = sesion;
      _errorMessage = null;
    });

    await _loadSessionData(sesion);
  }

  // Valida los datos y registra una nueva participación (puntos).
  Future<void> _registerParticipation() async {
    if (_isSaving) return;

    if (_selectedSesion == null ||
        _selectedActividad == null ||
        _selectedEstudiante == null) {
      _showMessage('Selecciona una sesión, actividad y estudiante.');
      return;
    }

    final pointsText = _pointsController.text.trim().replaceAll(',', '.');
    final double? points = double.tryParse(pointsText);

    if (points == null || !points.isFinite || points <= 0) {
      _showMessage('Ingresa una puntuación válida mayor que cero.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final operationId =
          'part_${DateTime.now().microsecondsSinceEpoch}_'
          '${_selectedSesion!.sesionId}_'
          '${_selectedEstudiante!.estudianteId}';

      final participation = Participacion(
        sesionId: _selectedSesion!.sesionId!,
        estudianteId: _selectedEstudiante!.estudianteId!,
        actividadId: _selectedActividad!.actividadId!,
        puntos: points,
        fecha: DateTime.now().toIso8601String(),
        observacion: _observationController.text.trim().isEmpty
            ? null
            : _observationController.text.trim(),
        operacionId: operationId,
      );

      await _repository.registrarParticipacion(participation);

      final updatedList =
          await _repository.obtenerParticipacionesPorSesion(
        _selectedSesion!.sesionId!,
      );

      if (!mounted) return;

      setState(() {
        _participaciones = updatedList;
        _pointsController.clear();
        _observationController.clear();
      });

      _showMessage('Participación registrada correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo registrar la participación: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Muestra un mensaje emergente (SnackBar).
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Devuelve "apellidos, nombres" del estudiante a partir de su id.
  String _studentName(int id) {
    for (final student in _estudiantes) {
      if (student.estudianteId == id) {
        return '${student.apellidos}, ${student.nombres}';
      }
    }
    return 'Estudiante #$id';
  }

  // Devuelve el nombre de la actividad a partir de su id.
  String _activityName(int id) {
    for (final activity in _actividades) {
      if (activity.actividadId == id) return activity.nombre;
    }
    return 'Actividad #$id';
  }

  // Convierte una fecha ISO (texto) al formato dd/mm/aaaa.
  String _formatDate(String date) {
    if (date.length >= 10) {
      final parts = date.substring(0, 10).split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
    return date;
  }

  // Suma todos los puntos de las participaciones mostradas.
  double get _totalPoints {
    return _participaciones.fold(
      0,
      (total, participation) => total + participation.puntos,
    );
  }

  // Tarjeta que muestra una participación del historial.
  Widget _buildHistoryCard(Participacion participation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.star, color: Colors.amber),
        ),
        title: Text(
          _studentName(participation.estudianteId),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_activityName(participation.actividadId)),
            if (participation.observacion != null &&
                participation.observacion!.isNotEmpty)
              Text('Observación: ${participation.observacion}'),
            Text(
              _formatDate(participation.fecha),
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+${participation.puntos}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const Text('puntos', style: TextStyle(fontSize: 11)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // Mensaje centrado para estados vacíos o de error.
  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Participación'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadInitialData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildEmptyMessage(_errorMessage!)
              : _sesiones.isEmpty
                  ? _buildEmptyMessage(
                      'Todavía no hay sesiones registradas. '
                      'Primero debes crear una sesión.',
                    )
                  : _actividades.isEmpty
                      ? _buildEmptyMessage(
                          'No hay actividades activas disponibles.',
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<Sesion>(
                                initialValue: _selectedSesion,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Sesión',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                items: _sesiones.map((session) {
                                  return DropdownMenuItem(
                                    value: session,
                                    child: Text(
                                      'Sesión #${session.sesionId} - '
                                      '${_formatDate(session.fecha)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _changeSession,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<Actividad>(
                                initialValue: _selectedActividad,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Actividad',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.star_outline),
                                ),
                                items: _actividades.map((activity) {
                                  return DropdownMenuItem(
                                    value: activity,
                                    child: Text(
                                      activity.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedActividad = value);
                                },
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<Estudiante>(
                                initialValue: _selectedEstudiante,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Estudiante',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items: _estudiantes.map((student) {
                                  return DropdownMenuItem(
                                    value: student,
                                    child: Text(
                                      '${student.apellidos}, ${student.nombres}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedEstudiante = value);
                                },
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _pointsController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Puntos',
                                  hintText: 'Ejemplo: 1 o 2.5',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.score_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _observationController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Observación (opcional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.notes),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving || _estudiantes.isEmpty
                                      ? null
                                      : _registerParticipation,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.add),
                                  label: Text(
                                    _isSaving
                                        ? 'Guardando...'
                                        : 'Registrar participación',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),
                              if (_estudiantes.isEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'No hay estudiantes activos incorporados '
                                  'al grupo de esta sesión.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ],
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Historial de participación',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    avatar: const Icon(
                                      Icons.stars,
                                      size: 17,
                                    ),
                                    label: Text(
                                      'Total: ${_totalPoints.toStringAsFixed(2)}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_participaciones.isEmpty)
                                _buildEmptyMessage(
                                  'Todavía no hay participaciones registradas '
                                  'en esta sesión.',
                                )
                              else
                                ..._participaciones.map(_buildHistoryCard),
                            ],
                          ),
                        ),
    );
  }
}
