import 'package:flutter/material.dart';
import '../../data/repositories/local_repository.dart';
import '../../models/asistencia.dart';
import '../../models/estudiante.dart';
import '../../models/sesion.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final LocalRepository _repository = LocalRepository();

  List<Sesion> _sesiones = [];
  Sesion? _selectedSesion;
  List<Estudiante> _estudiantes = [];
  Map<int, String> _asistenciasMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _sesiones = await _repository.obtenerSesiones();
      if (_sesiones.isNotEmpty) {
        _selectedSesion = _sesiones.first;
        await _loadEstudiantesYAsistencia(_selectedSesion!);
      }
    } catch (e) {
      debugPrint('Error al cargar datos iniciales: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEstudiantesYAsistencia(Sesion sesion) async {
    setState(() => _isLoading = true);
    try {
      _estudiantes = await _repository.obtenerEstudiantesPorGrupo(sesion.grupoId);
      final asistenciasPrevias = await _repository.obtenerAsistenciasPorSesion(sesion.sesionId!);

      _asistenciasMap = {
        for (var a in asistenciasPrevias) a.estudianteId: a.estado
      };
    } catch (e) {
      debugPrint('Error al cargar estudiantes y asistencias: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarAsistencia(int estudianteId, String estado) async {
    if (_selectedSesion == null) return;

    try {
      final asistencia = Asistencia(
        sesionId: _selectedSesion!.sesionId!,
        estudianteId: estudianteId,
        estado: estado,
      );

      await _repository.guardarAsistencia(asistencia);

      if (!mounted) return;
      setState(() {
        _asistenciasMap[estudianteId] = estado;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar asistencia: $e')),
      );
    }
  }

  Widget _buildResumenAsistencia() {
    int presentes = _asistenciasMap.values.where((e) => e == 'presente').length;
    int tardanzas = _asistenciasMap.values.where((e) => e == 'tardanza').length;
    int faltas = _asistenciasMap.values.where((e) => e == 'falta').length;
    int justificados = _asistenciasMap.values.where((e) => e == 'justificado').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _chipResumen('Pres.', presentes, Colors.green),
          _chipResumen('Tard.', tardanzas, Colors.orange),
          _chipResumen('Falt.', faltas, Colors.red),
          _chipResumen('Just.', justificados, Colors.blue),
        ],
      ),
    );
  }

  Widget _chipResumen(String label, int count, Color color) {
    return Chip(
      label: Text('$label $count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<Sesion>(
                    // Usamos initialValue en lugar de value por deprecación de Flutter reciente
                    initialValue: _selectedSesion,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Sesión',
                      border: OutlineInputBorder(),
                    ),
                    items: _sesiones.map((sesion) {
                      return DropdownMenuItem(
                        value: sesion,
                        child: Text('Sesión #${sesion.sesionId} - ${sesion.fecha}'),
                      );
                    }).toList(),
                    onChanged: (Sesion? nuevaSesion) async {
                      if (nuevaSesion != null) {
                        setState(() => _selectedSesion = nuevaSesion);
                        await _loadEstudiantesYAsistencia(nuevaSesion);
                      }
                    },
                  ),
                ),
                if (_selectedSesion != null) _buildResumenAsistencia(),
                const Divider(height: 1),
                Expanded(
                  child: _estudiantes.isEmpty
                      ? const Center(
                          child: Text('No hay estudiantes activos en este grupo para la sesión.'),
                        )
                      : ListView.builder(
                          itemCount: _estudiantes.length,
                          itemBuilder: (context, index) {
                            final estudiante = _estudiantes[index];
                            final estadoActual = _asistenciasMap[estudiante.estudianteId] ?? 'presente';

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${estudiante.apellidos}, ${estudiante.nombres}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ToggleButtons(
                                        borderRadius: BorderRadius.circular(8),
                                        constraints: const BoxConstraints(minHeight: 32, minWidth: 65),
                                        isSelected: [
                                          estadoActual == 'presente',
                                          estadoActual == 'tardanza',
                                          estadoActual == 'falta',
                                          estadoActual == 'justificado',
                                        ],
                                        onPressed: (int indexBtn) {
                                          String nuevoEstado = 'presente';
                                          if (indexBtn == 1) nuevoEstado = 'tardanza';
                                          if (indexBtn == 2) nuevoEstado = 'falta';
                                          if (indexBtn == 3) nuevoEstado = 'justificado';

                                          _registrarAsistencia(estudiante.estudianteId!, nuevoEstado);
                                        },
                                        children: const [
                                          Text('Pres.', style: TextStyle(fontSize: 12)),
                                          Text('Tard.', style: TextStyle(fontSize: 12)),
                                          Text('Falta', style: TextStyle(fontSize: 12)),
                                          Text('Just.', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}