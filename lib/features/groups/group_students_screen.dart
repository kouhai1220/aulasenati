// ============================================================================
// PANTALLA: ESTUDIANTES DE UN GRUPO
// ----------------------------------------------------------------------------
// Muestra los estudiantes asignados a un grupo y permite añadir nuevos
// (eligiendo uno ya registrado o creando uno desde cero).
// ============================================================================

import 'package:flutter/material.dart';
import '../../data/repositories/local_repository.dart';
import '../../models/estudiante.dart';
import '../../models/grupo.dart';
import '../../models/grupo_estudiante.dart';

class GroupStudentsScreen extends StatefulWidget {
  final Grupo grupo;
  const GroupStudentsScreen({super.key, required this.grupo});
  @override
  State<GroupStudentsScreen> createState() => _GroupStudentsScreenState();
}

class _GroupStudentsScreenState extends State<GroupStudentsScreen> {
  final _repo = LocalRepository();
  List<Estudiante> _estudiantes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  // Carga los estudiantes que pertenecen a este grupo.
  Future<void> _cargar() async {
    final id = widget.grupo.grupoId;
    if (id == null) return;
    try {
      final datos = await _repo.obtenerEstudiantesPorGrupo(id);
      if (!mounted) return;
      setState(() { _estudiantes = datos; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mensaje('Error al cargar estudiantes: $e');
    }
  }

  void _mensaje(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  // Asigna (incorpora) un estudiante al grupo actual.
  Future<void> _asignar(Estudiante estudiante) async {
    final grupoId = widget.grupo.grupoId;
    final estudianteId = estudiante.estudianteId;
    if (grupoId == null || estudianteId == null) return;
    try {
      await _repo.incorporarEstudianteAGrupo(GrupoEstudiante(
        grupoId: grupoId,
        estudianteId: estudianteId,
        fechaIncorporacion: DateTime.now().toIso8601String(),
      ));
      await _cargar();
      if (mounted) _mensaje('Estudiante asignado correctamente.');
    } catch (e) { if (mounted) _mensaje('No se pudo asignar: $e'); }
  }

  // Abre el panel inferior para elegir o registrar un estudiante.
  Future<void> _abrirGestion() async {
    final todos = await _repo.obtenerEstudiantes();
    final ids = _estudiantes.map((e) => e.estudianteId).toSet();
    final disponibles = todos.where((e) => !ids.contains(e.estudianteId)).toList();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Añadir estudiantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Selecciona un estudiante registrado o registra uno nuevo.'),
              const SizedBox(height: 12),
              if (disponibles.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No hay estudiantes disponibles.'))
              else
                ...disponibles.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text('${e.apellidos}, ${e.nombres}'),
                  subtitle: Text('Código: ${e.codigoInstitucional}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF003B70)),
                    onPressed: () async { await _asignar(e); if (sheetContext.mounted) Navigator.pop(sheetContext); },
                  ),
                )),
              const Divider(),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add), label: const Text('Registrar nuevo estudiante'),
                onPressed: () async {
                  final nuevo = await _formulario();
                  if (nuevo == null) return;
                  try {
                    final id = await _repo.insertarEstudiante(nuevo);
                    await _asignar(Estudiante(estudianteId: id, codigoInstitucional: nuevo.codigoInstitucional, nombres: nuevo.nombres, apellidos: nuevo.apellidos));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  } catch (e) {
                    if (mounted) _mensaje(e.toString().contains('UNIQUE') ? 'Ese código institucional ya está registrado.' : 'No se pudo registrar: $e');
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // Muestra el diálogo para registrar un estudiante nuevo.
  Future<Estudiante?> _formulario() async {
    final key = GlobalKey<FormState>();
    final codigo = TextEditingController();
    final nombres = TextEditingController();
    final apellidos = TextEditingController();
    return showDialog<Estudiante>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Registrar estudiante'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: codigo, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código institucional'), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
        TextFormField(controller: nombres, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombres'), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
        TextFormField(controller: apellidos, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Apellidos'), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () { if (!key.currentState!.validate()) return; Navigator.pop(ctx, Estudiante(codigoInstitucional: codigo.text.trim().toUpperCase(), nombres: nombres.text.trim(), apellidos: apellidos.text.trim())); }, child: const Text('Registrar')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Estudiantes - ${widget.grupo.codigo}')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _estudiantes.isEmpty
      ? const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school_outlined, size: 54, color: Colors.blueGrey), SizedBox(height: 12),
          Text('Este grupo todavía no tiene estudiantes.', textAlign: TextAlign.center),
          Text('Añade estudiantes para comenzar.', style: TextStyle(color: Colors.blueGrey)),
        ])))
      : RefreshIndicator(onRefresh: _cargar, child: ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: _estudiantes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) { final e = _estudiantes[i]; return Card(child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('${e.apellidos}, ${e.nombres}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Código: ${e.codigoInstitucional}'),
          )); },
        )),
    floatingActionButton: FloatingActionButton.extended(onPressed: _abrirGestion, icon: const Icon(Icons.person_add_alt_1), label: const Text('Añadir estudiante')),
  );
}
