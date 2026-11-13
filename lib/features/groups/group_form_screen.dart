
import 'package:flutter/material.dart';

import '../../data/repositories/local_repository.dart';
import '../../models/grupo.dart';


class GroupFormScreen extends StatefulWidget {
  const GroupFormScreen({super.key});

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _periodoController = TextEditingController();

  final LocalRepository _repository = LocalRepository();

  bool _saving = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _periodoController.dispose();
    super.dispose();
  }

  Future<void> _guardarGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final codigo = _codigoController.text.trim();
      final nombre = _nombreController.text.trim();
      final periodo = _periodoController.text.trim();

      // Evitar códigos de sección duplicados.
      final grupos = await _repository.obtenerGrupos();

      final codigoExiste = grupos.any(
        (grupo) =>
            grupo.codigo.toLowerCase() == codigo.toLowerCase(),
      );

      if (codigoExiste) {
        throw Exception('Ya existe un grupo con ese código de sección.');
      }

      // Obtener el instructor registrado.
      final instructores = await _repository.obtenerInstructores();

      final instructor = instructores.firstWhere(
        (item) => item.correo.toLowerCase() == 'jluque@senati.pe',
        orElse: () => throw Exception(
          'No se encontró el instructor inicial.',
        ),
      );

      await _repository.insertarGrupo(
        Grupo(
          codigo: codigo,
          nombre: nombre,
          periodo: periodo,
          instructorId: instructor.instructorId!,
          estado: 'activo',
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Grupo SENATI'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  controller: _nombreController,
                  label: 'Nombre del Grupo',
                  hint: 'Ej. FORMACIÓN MONITORES EMPRESA',
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _periodoController,
                  label: 'Periodo',
                  hint: 'Ej. 2026-20',
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _codigoController,
                  label: 'Código de Sección',
                  hint: 'Ej. 2026-20-202601',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _guardarGrupo,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const UnderlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio.';
        }
        return null;
      },
    );
  }
}
