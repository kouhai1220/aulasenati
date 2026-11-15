
// ============================================================================
// PANTALLA: SESIONES ACADÉMICAS
// ----------------------------------------------------------------------------
// Lista las sesiones (clases) registradas de todos los grupos y permite crear
// una nueva sesión con el botón "+".
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/local_repository.dart';
import '../../models/grupo.dart';
import '../../models/sesion.dart';
import 'session_form_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final LocalRepository _repository = LocalRepository();

  List<Sesion> _sesiones = [];
  List<Grupo> _grupos = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carga en paralelo las sesiones y los grupos (para mostrar sus nombres).
  Future<void> _loadData() async {
    try {
      final resultados = await Future.wait([
        _repository.obtenerSesiones(),
        _repository.obtenerGrupos(),
      ]);

      if (!mounted) return;

      setState(() {
        _sesiones = resultados[0] as List<Sesion>;
        _grupos = resultados[1] as List<Grupo>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      debugPrint('Error al cargar sesiones: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar las sesiones.'),
        ),
      );
    }
  }

  // Abre el formulario de nueva sesión y recarga si se guardó.
  Future<void> _openForm() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const SessionFormScreen(),
      ),
    );

    if (resultado == true) {
      await _loadData();
    }
  }

  // Convierte una fecha ISO (texto) al formato dd/mm/aaaa.
  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // Devuelve "código - nombre" del grupo a partir de su id.
  String _groupName(int grupoId) {
    for (final grupo in _grupos) {
      if (grupo.grupoId == grupoId) {
        return '${grupo.codigo} - ${grupo.nombre}';
      }
    }

    return 'Grupo no encontrado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiones académicas'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Construye el cuerpo según el estado: cargando, vacío o lista.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_sesiones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 75,
                color: Colors.blueGrey.shade200,
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay sesiones registradas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea una sesión académica para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openForm,
                icon: const Icon(Icons.add),
                label: const Text('Crear sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sesiones registradas: ${_sesiones.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          ..._sesiones.map((sesion) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.10),
                  child: Icon(
                    Icons.event_note,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: Text(
                  sesion.tema?.isNotEmpty == true
                      ? sesion.tema!
                      : 'Sesión sin tema',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_groupName(sesion.grupoId)),
                      const SizedBox(height: 4),
                      Text('Fecha: ${_formatDate(sesion.fecha)}'),
                      const SizedBox(height: 4),
                      Text('Estado: ${sesion.estado}'),
                    ],
                  ),
                ),
                isThreeLine: true,
              ),
            );
          }),
        ],
      ),
    );
  }
}
