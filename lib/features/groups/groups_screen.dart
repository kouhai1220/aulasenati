
import 'package:flutter/material.dart';

// Elimina el import de AppConstants.
import '../../data/repositories/local_repository.dart';
import '../../models/grupo.dart';
import '../../models/instructor.dart';
import 'group_form_screen.dart';
import 'group_students_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final LocalRepository _repository = LocalRepository();

  List<Grupo> _grupos = [];
  bool _loading = true;
  String? _error;

  static const String _correoInstructor = 'jluque@senati.pe';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Registrar al instructor inicial si todavía no existe.
      final instructores = await _repository.obtenerInstructores();

      final existeInstructor = instructores.any(
        (instructor) =>
            instructor.correo.toLowerCase() ==
            _correoInstructor.toLowerCase(),
      );

      if (!existeInstructor) {
        await _repository.insertarInstructor(
          Instructor(
            nombres: 'JORGE ANTONIO',
            apellidos: 'LUQUE',
            correo: _correoInstructor,
            estado: 'activo',
          ),
        );
      }

      await _cargarGrupos();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los grupos: $e';
      });
    }
  }

  Future<void> _cargarGrupos() async {
    final grupos = await _repository.obtenerGrupos();

    if (!mounted) return;

    setState(() {
      _grupos = grupos;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _abrirFormulario() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => const GroupFormScreen(),
    );

    if (resultado == true) {
      await _cargarGrupos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos SENATI - AULA PUNTOS'),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _abrirFormulario,
        tooltip: 'Crear grupo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 45,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _initialize();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_grupos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 48,
                color: Colors.blueGrey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay grupos registrados.',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                ),
              ),
              Text(
                'Crea un grupo para comenzar.',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarGrupos,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _grupos.length,
        itemBuilder: (context, index) {
          final grupo = _grupos[index];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupStudentsScreen(grupo: grupo),
                  ),
                );
                await _cargarGrupos();
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                grupo.codigo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003B70),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${grupo.nombre}\nPeriodo: ${grupo.periodo}',
                ),
              ),
              isThreeLine: true,
              leading: const CircleAvatar(
                child: Icon(Icons.groups),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
