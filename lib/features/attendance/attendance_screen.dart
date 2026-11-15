
import 'package:flutter/material.dart';

import '../../data/repositories/local_repository.dart';
import '../../models/asistencia.dart';
import '../../models/estudiante.dart';
import '../../models/sesion.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isActive;

  const AttendanceScreen({
    super.key,
    this.isActive = false,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final LocalRepository _repository = LocalRepository();

  List<Sesion> _sesiones = [];
  List<Estudiante> _estudiantes = [];
  Map<int, String> _asistenciasMap = {};

  Sesion? _selectedSesion;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Al volver a esta pestaña, vuelve a consultar las sesiones guardadas.
    if (!oldWidget.isActive && widget.isActive) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sesiones = await _repository.obtenerSesiones();

      if (!mounted) return;

      setState(() {
        _sesiones = sesiones;
        _selectedSesion = sesiones.isNotEmpty ? sesiones.first : null;
      });

      if (_selectedSesion != null) {
        await _loadStudentsAndAttendance(_selectedSesion!);
      } else {
        setState(() {
          _estudiantes = [];
          _asistenciasMap = {};
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudieron cargar las sesiones: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsAndAttendance(Sesion sesion) async {
    setState(() {
      _isLoading = true;
      _asistenciasMap = {};
      _estudiantes = [];
    });

    try {
      final estudiantes =
          await _repository.obtenerEstudiantesPorGrupo(sesion.grupoId);

      final asistencias = await _repository.obtenerAsistenciasPorSesion(
        sesion.sesionId!,
      );

      if (!mounted) return;

      setState(() {
        _estudiantes = estudiantes;
        _asistenciasMap = {
          for (final asistencia in asistencias)
            asistencia.estudianteId: asistencia.estado,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo cargar la asistencia: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeSession(Sesion? sesion) async {
    if (sesion == null) return;

    setState(() => _selectedSesion = sesion);
    await _loadStudentsAndAttendance(sesion);
  }

  Future<void> _registerAttendance(
    int estudianteId,
    String estado,
  ) async {
    if (_selectedSesion == null || _isSaving) return;

    setState(() => _isSaving = true);

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asistencia guardada: ${_statusLabel(estado)}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar asistencia: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _statusLabel(String estado) {
    switch (estado) {
      case 'presente':
        return 'Presente';
      case 'tardanza':
        return 'Tardanza';
      case 'falta':
        return 'Falta';
      case 'justificado':
        return 'Justificado';
      default:
        return 'Sin registrar';
    }
  }

  Widget _summaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final presentes =
        _asistenciasMap.values.where((e) => e == 'presente').length;
    final tardanzas =
        _asistenciasMap.values.where((e) => e == 'tardanza').length;
    final faltas =
        _asistenciasMap.values.where((e) => e == 'falta').length;
    final justificados =
        _asistenciasMap.values.where((e) => e == 'justificado').length;
    final sinRegistrar = _estudiantes.length - _asistenciasMap.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de asistencia',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _summaryItem('Presentes', presentes, Colors.green),
              _summaryItem('Tardanzas', tardanzas, Colors.orange),
              _summaryItem('Faltas', faltas, Colors.red),
              _summaryItem('Justificados', justificados, Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sin registrar: $sinRegistrar',
            style: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Estudiante estudiante) {
    final id = estudiante.estudianteId!;
    final estadoActual = _asistenciasMap[id];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${estudiante.apellidos}, ${estudiante.nombres}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        estadoActual == null
                            ? 'Sin registrar'
                            : _statusLabel(estadoActual),
                        style: TextStyle(
                          color: estadoActual == null
                              ? Colors.blueGrey
                              : _statusColor(estadoActual),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _statusButton(id, 'presente', 'Presente', Colors.green,
                    estadoActual),
                _statusButton(id, 'tardanza', 'Tardanza', Colors.orange,
                    estadoActual),
                _statusButton(id, 'falta', 'Falta', Colors.red, estadoActual),
                _statusButton(id, 'justificado', 'Justificado', Colors.blue,
                    estadoActual),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String estado) {
    switch (estado) {
      case 'presente':
        return Colors.green;
      case 'tardanza':
        return Colors.orange;
      case 'falta':
        return Colors.red;
      case 'justificado':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _statusButton(
    int estudianteId,
    String estado,
    String label,
    Color color,
    String? estadoActual,
  ) {
    final selected = estadoActual == estado;

    return OutlinedButton(
      onPressed: _isSaving
          ? null
          : () => _registerAttendance(estudianteId, estado),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : color,
        backgroundColor: selected ? color : Colors.transparent,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia'),
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _sesiones.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Todavía no hay sesiones registradas. '
                          'Primero debes crear una sesión para controlar su asistencia.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: DropdownButtonFormField<Sesion>(
                            initialValue: _selectedSesion,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar sesión',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            items: _sesiones.map((sesion) {
                              return DropdownMenuItem(
                                value: sesion,
                                child: Text(
                                  'Sesión #${sesion.sesionId} - '
                                  '${sesion.fecha.substring(0, 10)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _changeSession,
                          ),
                        ),
                        if (_selectedSesion != null) _buildSummary(),
                        const Divider(height: 1),
                        Expanded(
                          child: _estudiantes.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No hay estudiantes activos incorporados '
                                      'al grupo de esta sesión.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 16),
                                  itemCount: _estudiantes.length,
                                  itemBuilder: (context, index) =>
                                      _buildStudentCard(_estudiantes[index]),
                                ),
                        ),
                      ],
                    ),
    );
  }
}
