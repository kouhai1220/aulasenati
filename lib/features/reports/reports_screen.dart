
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/local_repository.dart';
import '../../models/grupo.dart';
import '../../models/sesion.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final LocalRepository _repository = LocalRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Grupo> _grupos = [];
  List<Sesion> _sesiones = [];
  List<Map<String, dynamic>> _reporte = [];

  int? _grupoId;
  int _sesionId = -1;

  bool _isLoading = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGA DE INFORMACIÓN
  // ============================================================

  Future<void> _cargarGrupos() async {
    try {
      final grupos = await _repository.obtenerGrupos();

      if (!mounted) return;

      setState(() {
        _grupos = grupos;
        _grupoId = grupos.isNotEmpty ? grupos.first.grupoId : null;
        _isLoading = false;
      });

      if (_grupoId != null) {
        await _cargarSesiones();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _mostrarMensaje('No se pudieron cargar los grupos.');
    }
  }

  Future<void> _cargarSesiones() async {
    if (_grupoId == null) return;

    try {
      final sesiones =
          await _repository.obtenerSesionesPorGrupo(_grupoId!);

      if (!mounted) return;

      setState(() {
        _sesiones = sesiones;
        _sesionId = -1;
      });

      await _cargarReporte();
    } catch (e) {
      _mostrarMensaje('No se pudieron cargar las sesiones.');
    }
  }

  Future<void> _cargarReporte() async {
    if (_grupoId == null) return;

    setState(() => _isLoading = true);

    try {
      final resultados =
          await _repository.obtenerReporteCalificaciones(
        grupoId: _grupoId!,
        sesionId: _sesionId == -1 ? null : _sesionId,
      );

      if (!mounted) return;

      setState(() {
        _reporte = resultados;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _mostrarMensaje('No se pudo generar el reporte: $e');
    }
  }

  // ============================================================
  // FILTROS Y RESUMEN
  // ============================================================

  List<Map<String, dynamic>> get _reporteFiltrado {
    if (_busqueda.trim().isEmpty) return _reporte;

    final texto = _busqueda.toLowerCase().trim();

    return _reporte.where((estudiante) {
      final nombre =
          '${estudiante['apellidos']} ${estudiante['nombres']}'
              .toLowerCase();

      final codigo =
          estudiante['codigo_institucional'].toString().toLowerCase();

      return nombre.contains(texto) || codigo.contains(texto);
    }).toList();
  }

  double get _totalPuntos {
    return _reporteFiltrado.fold<double>(
      0,
      (total, estudiante) =>
          total + (estudiante['total_puntos'] as num).toDouble(),
    );
  }

  String _nombreGrupo() {
    final grupo = _grupos.where((g) => g.grupoId == _grupoId);

    if (grupo.isEmpty) return '';

    return '${grupo.first.codigo} - ${grupo.first.nombre}';
  }

  String _periodoGrupo() {
    final grupo = _grupos.where((g) => g.grupoId == _grupoId);

    if (grupo.isEmpty) return '';

    return grupo.first.periodo.toString();
  }

  String _formatearFecha(String fecha) {
    final date = DateTime.tryParse(fecha);

    if (date == null) return fecha;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _fechaActual() {
    final fecha = DateTime.now();

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _nombreArchivo(String extension) {
    final ahora = DateTime.now();

    final marcaTiempo =
        '${ahora.year}'
        '${ahora.month.toString().padLeft(2, '0')}'
        '${ahora.day.toString().padLeft(2, '0')}_'
        '${ahora.hour.toString().padLeft(2, '0')}'
        '${ahora.minute.toString().padLeft(2, '0')}'
        '${ahora.second.toString().padLeft(2, '0')}';

    return 'reporte_calificaciones_$marcaTiempo.$extension';
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // ============================================================
  // EXPORTACIÓN PDF
  // ============================================================

  Future<void> _exportarPdf() async {
    if (_reporteFiltrado.isEmpty) {
      _mostrarMensaje('No hay información para exportar.');
      return;
    }

    try {
      final pdf = pw.Document();

      final nombreGrupo = _nombreGrupo();
      final periodo = _periodoGrupo();
      final fechaGeneracion = _fechaActual();

      final criterioSesion = _sesionId == -1
          ? 'Todas las sesiones'
          : 'Sesión $_sesionId';

      final criterioEstudiante = _busqueda.trim().isEmpty
          ? 'Todos'
          : _busqueda.trim();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              pw.Text(
                'AULA PUNTOS - SENATI',
                style: pw.TextStyle(
                  fontSize: 19,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF041739),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'REPORTE CONSOLIDADO DE CALIFICACIONES',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),

              pw.Text('Grupo: $nombreGrupo'),
              pw.Text('Periodo: $periodo'),
              pw.Text('Sesión: $criterioSesion'),
              pw.Text('Estudiante: $criterioEstudiante'),
              pw.Text('Fecha de generación: $fechaGeneracion'),

              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                headers: [
                  'Estudiante',
                  'Código institucional',
                  'Total puntos',
                ],
                data: _reporteFiltrado.map((estudiante) {
                  final puntos =
                      (estudiante['total_puntos'] as num).toDouble();

                  return [
                    '${estudiante['apellidos']} ${estudiante['nombres']}',
                    estudiante['codigo_institucional'].toString(),
                    puntos.toStringAsFixed(2),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF041739),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Estudiantes: ${_reporteFiltrado.length}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total de puntos: ${_totalPuntos.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final Uint8List bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: _nombreArchivo('pdf'),
      );
    } catch (e) {
      _mostrarMensaje('No se pudo generar el PDF: $e');
    }
  }

  // ============================================================
  // EXPORTACIÓN EXCEL
  // ============================================================

  Future<void> _exportarExcel() async {
    if (_reporteFiltrado.isEmpty) {
      _mostrarMensaje('No hay información para exportar.');
      return;
    }

    try {
      final excel = Excel.createExcel();

      excel.rename('Sheet1', 'Calificaciones');

      final sheet = excel['Calificaciones'];

      final criterioSesion = _sesionId == -1
          ? 'Todas las sesiones'
          : 'Sesión $_sesionId';

      final criterioEstudiante = _busqueda.trim().isEmpty
          ? 'Todos'
          : _busqueda.trim();

      // Información general del reporte.
      sheet.appendRow([
        TextCellValue('AULA PUNTOS - SENATI'),
      ]);

      sheet.appendRow([
        TextCellValue('REPORTE CONSOLIDADO DE CALIFICACIONES'),
      ]);

      sheet.appendRow([
        TextCellValue('Grupo'),
        TextCellValue(_nombreGrupo()),
      ]);

      sheet.appendRow([
        TextCellValue('Periodo'),
        TextCellValue(_periodoGrupo()),
      ]);

      sheet.appendRow([
        TextCellValue('Sesión'),
        TextCellValue(criterioSesion),
      ]);

      sheet.appendRow([
        TextCellValue('Estudiante'),
        TextCellValue(criterioEstudiante),
      ]);

      sheet.appendRow([
        TextCellValue('Fecha de generación'),
        TextCellValue(_fechaActual()),
      ]);

      sheet.appendRow([
        TextCellValue(''),
      ]);

      // Encabezados de la tabla.
      sheet.appendRow([
        TextCellValue('Estudiante'),
        TextCellValue('Código institucional'),
        TextCellValue('Total puntos'),
      ]);

      // Datos de los estudiantes.
      for (final estudiante in _reporteFiltrado) {
        final puntos =
            (estudiante['total_puntos'] as num).toDouble();

        sheet.appendRow([
          TextCellValue(
            '${estudiante['apellidos']} ${estudiante['nombres']}',
          ),
          TextCellValue(
            estudiante['codigo_institucional'].toString(),
          ),
          DoubleCellValue(puntos),
        ]);
      }

      // Fila de total.
      sheet.appendRow([
        TextCellValue('TOTAL DE PUNTOS'),
        TextCellValue(''),
        DoubleCellValue(_totalPuntos),
      ]);

      // Formato del encabezado.
      final estiloEncabezado = CellStyle(
  bold: true,
  fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
  backgroundColorHex: ExcelColor.fromHexString('#041739'),
  horizontalAlign: HorizontalAlign.Center,
);

      for (var columna = 0; columna < 3; columna++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columna,
                rowIndex: 8,
              ),
            )
            .cellStyle = estiloEncabezado;
      }

      // Formato de la fila de total.
      final estiloTotal = CellStyle(
  bold: true,
  backgroundColorHex: ExcelColor.fromHexString('#DCE6F1'),
);

      final filaTotal = _reporteFiltrado.length + 9;

      for (var columna = 0; columna < 3; columna++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columna,
                rowIndex: filaTotal,
              ),
            )
            .cellStyle = estiloTotal;
      }

      // Ancho de columnas.
      sheet.setColumnWidth(0, 35);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 18);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          'No se pudieron generar los datos del archivo Excel.',
        );
      }

      final nombre = _nombreArchivo('xlsx');

      await SharePlus.instance.share(
        ShareParams(
          title: 'Reporte de calificaciones',
          text: 'Reporte de calificaciones de ${_nombreGrupo()}',
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          fileNameOverrides: [nombre],
        ),
      );
    } catch (e) {
      _mostrarMensaje('No se pudo generar el Excel: $e');
    }
  }

  // ============================================================
  // INTERFAZ PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Exportación'),
        actions: [
          IconButton(
            onPressed: _cargarGrupos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _grupos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_grupos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 65,
                color: Colors.blueGrey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay grupos registrados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Registra un grupo para generar reportes.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarGrupos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFiltros(),
          const SizedBox(height: 18),
          _buildResumen(),
          const SizedBox(height: 18),
          _buildListado(),
          const SizedBox(height: 20),
          _buildExportacion(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Criterios del reporte',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<int>(
              initialValue: _grupoId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Grupo',
                prefixIcon: Icon(Icons.groups_outlined),
                border: OutlineInputBorder(),
              ),
              items: _grupos.map((grupo) {
                return DropdownMenuItem<int>(
                  value: grupo.grupoId,
                  child: Text(
                    '${grupo.codigo} - ${grupo.nombre}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() => _grupoId = value);
                _cargarSesiones();
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<int>(
              initialValue: _sesionId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sesión',
                prefixIcon: Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text('Todas las sesiones'),
                ),
                ..._sesiones.map((sesion) {
                  return DropdownMenuItem<int>(
                    value: sesion.sesionId,
                    child: Text(
                      'Sesión ${sesion.sesionId} - '
                      '${_formatearFecha(sesion.fecha)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() => _sesionId = value);
                _cargarReporte();
              },
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar estudiante',
                hintText: 'Nombre o código institucional',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _busqueda = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _busqueda = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMEN DEL REPORTE
  // ============================================================

  Widget _buildResumen() {
    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REPORTE CONSOLIDADO DE CALIFICACIONES',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _nombreGrupo(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Periodo: ${_periodoGrupo()}',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _datoResumen(
                  'Estudiantes',
                  '${_reporteFiltrado.length}',
                ),
                _datoResumen(
                  'Total puntos',
                  _totalPuntos.toStringAsFixed(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoResumen(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LISTADO DE CALIFICACIONES
  // ============================================================

  Widget _buildListado() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reporteFiltrado.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay estudiantes para los criterios seleccionados.',
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Calificaciones por estudiante',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(height: 1),

          ..._reporteFiltrado.map((estudiante) {
            final puntos =
                (estudiante['total_puntos'] as num).toDouble();

            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.10),
                child: Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                '${estudiante['apellidos']} ${estudiante['nombres']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Código: ${estudiante['codigo_institucional']}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    puntos.toStringAsFixed(2),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const Text(
                    'puntos',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // BOTONES DE EXPORTACIÓN
  // ============================================================

  Widget _buildExportacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exportación',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                _reporteFiltrado.isEmpty || _isLoading
                    ? null
                    : _exportarPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF'),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                _reporteFiltrado.isEmpty || _isLoading
                    ? null
                    : _exportarExcel,
            icon: const Icon(Icons.table_chart),
            label: const Text('Exportar Excel / Compartir'),
          ),
        ),
      ],
    );
  }
}
