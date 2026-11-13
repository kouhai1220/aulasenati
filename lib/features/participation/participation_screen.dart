import 'package:flutter/material.dart';
import '../../data/repositories/local_repository.dart';
import '../../models/actividad.dart';
import '../../models/estudiante.dart';
import '../../models/participacion.dart';
import '../../models/sesion.dart';

class ParticipationScreen extends StatefulWidget {
  const ParticipationScreen({super.key});

  @override
  State<ParticipationScreen> createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends State<ParticipationScreen> {
  final LocalRepository _repository = LocalRepository();

  List<Sesion> _sesiones = [];
  Sesion? _selectedSesion;

  List<Actividad> _actividades = [];
  Actividad? _selectedActividad;

  List<Estudiante> _estudiantes = [];
  Estudiante? _selectedEstudiante;

  final TextEditingController _puntosController = TextEditingController();
  bool _isLoading = true;
  List<Participacion> _participacionesSesion = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _sesiones = await _repository.obtenerSesiones();
      _actividades = await _repository.obtenerActividades();

      if (_sesiones.isNotEmpty) {
        _selectedSesion = _sesiones.first;
        await _onSesionChanged(_selectedSesion!);
      }

      if (_actividades.isNotEmpty) {
        _selectedActividad = _actividades.first;
      }
    } catch (e) {
      debugPrint('Error al cargar datos de participación: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSesionChanged(Sesion sesion) async {
    setState(() {
      _selectedSesion = sesion;
    });
    try {
      _estudiantes = await _repository.obtenerEstudiantesPorGrupo(sesion.grupoId);
      if (_estudiantes.isNotEmpty) {
        _selectedEstudiante = _estudiantes.first;
      } else {
        _selectedEstudiante = null;
      }
      _participacionesSesion = await _repository.obtenerParticipacionesPorSesion(sesion.sesionId!);
      setState(() {});
    } catch (e) {
      debugPrint('Error al cambiar de sesión: $e');
    }
  }

  Future<void> _registrarParticipacion() async {
    if (_selectedSesion == null || _selectedActividad == null || _selectedEstudiante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona sesión, actividad y estudiante.')),
      );
      return;
    }

    final double? puntos = double.tryParse(_puntosController.text);
    if (puntos == null || puntos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una puntuación válida mayor a 0.')),
      );
      return;
    }

    try {
      // Generamos un identificador único de operación (UUID o timestamp con IDs)
      final String operacionId = 'part_${DateTime.now().millisecondsSinceEpoch}';

      final participacion = Participacion(
        operacionId: operacionId,
        sesionId: _selectedSesion!.sesionId!,
        estudianteId: _selectedEstudiante!.estudianteId!,
        actividadId: _selectedActividad!.actividadId!,
        puntos: puntos,
        fecha: DateTime.now().toIso8601String(),
      );

      await _repository.registrarParticipacion(participacion);
      _puntosController.clear();

      // Recargar la lista de participaciones de la sesión
      _participacionesSesion = await _repository.obtenerParticipacionesPorSesion(_selectedSesion!.sesionId!);
      setState(() {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Participación registrada con éxito!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Participación'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Selector de Sesión
                  DropdownButtonFormField<Sesion>(
                    initialValue: _selectedSesion,
                    decoration: const InputDecoration(
                      labelText: 'Sesión',
                      border: OutlineInputBorder(),
                    ),
                    items: _sesiones.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text('Sesión #${s.sesionId} - ${s.fecha}'),
                      );
                    }).toList(),
                    onChanged: (Sesion? val) {
                      if (val != null) _onSesionChanged(val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2. Selector de Actividad
                  DropdownButtonFormField<Actividad>(
                    initialValue: _selectedActividad,
                    decoration: const InputDecoration(
                      labelText: 'Actividad',
                      border: OutlineInputBorder(),
                    ),
                    items: _actividades.map((a) {
                      return DropdownMenuItem(
                        value: a,
                        child: Text(a.nombre),
                      );
                    }).toList(),
                    onChanged: (Actividad? val) {
                      setState(() => _selectedActividad = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Selector de Estudiante
                  DropdownButtonFormField<Estudiante>(
                    initialValue: _selectedEstudiante,
                    decoration: const InputDecoration(
                      labelText: 'Estudiante',
                      border: OutlineInputBorder(),
                    ),
                    items: _estudiantes.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text('${e.apellidos}, ${e.nombres}'),
                      );
                    }).toList(),
                    onChanged: (Estudiante? val) {
                      setState(() => _selectedEstudiante = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 4. Input de Puntos y Botón Guardar
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _puntosController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Puntos',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _registrarParticipacion,
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar Puntos'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Participaciones registradas en esta sesión:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Divider(),

                  // 5. Historial de participaciones en la sesión actual
                  Expanded(
                    child: _participacionesSesion.isEmpty
                        ? const Center(child: Text('No hay registros de participación en esta sesión.'))
                        : ListView.builder(
                            itemCount: _participacionesSesion.length,
                            itemBuilder: (context, index) {
                              final part = _participacionesSesion[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.star, color: Colors.amber),
                                ),
                                title: Text('Estudiante ID: ${part.estudianteId}'),
                                subtitle: Text('Puntos asignados: ${part.puntos}'),
                                trailing: Text(part.fecha.substring(0, 10)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}