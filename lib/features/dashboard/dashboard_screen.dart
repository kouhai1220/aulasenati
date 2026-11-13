
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/local_repository.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final bool isActive;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.isActive,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalRepository _repository = LocalRepository();

  int _groupCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupCount();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar el contador al regresar a Inicio.
    if (!oldWidget.isActive && widget.isActive) {
      _loadGroupCount();
    }
  }

  Future<void> _loadGroupCount() async {
    try {
      final grupos = await _repository.obtenerGrupos();

      if (!mounted) return;

      setState(() {
        _groupCount = grupos.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('Error al cargar cantidad de grupos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),

            const SizedBox(height: 16),

            _buildInformationCards(),

            const SizedBox(height: 24),

            const Text(
              'Accesos Rápidos',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 12),

            _buildQuickAccessGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0755A0),
            Color(0xFF003B70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.dashboardTitle,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Control Académico y Puntuación',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Optimiza la gestión de tus grupos y talleres.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.groups,
            iconColor: AppTheme.primaryColor,
            title: 'Mis Grupos',
            value: _isLoading ? '...' : '$_groupCount',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildInfoCard(
            icon: Icons.cloud_off,
            iconColor: Colors.green,
            title: 'Estado del Sistema',
            value: 'Offline',
            valueColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 25,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    final items = [
      _QuickAccessItem(
        title: 'Gestionar Grupos',
        icon: Icons.folder,
        color: AppTheme.primaryColor,
        destination: 1,
      ),
      _QuickAccessItem(
        title: 'Control de Asistencia',
        icon: Icons.how_to_reg,
        color: Colors.teal,
        destination: 2,
      ),
      _QuickAccessItem(
        title: 'Puntuación Rápida',
        icon: Icons.star,
        color: Colors.orange,
        destination: 2,
      ),
      _QuickAccessItem(
        title: 'Reportes y PDF',
        icon: Icons.bar_chart,
        color: Colors.indigo,
        destination: 3,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => widget.onNavigate(item.destination),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: item.color,
                    size: 32,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAccessItem {
  final String title;
  final IconData icon;
  final Color color;
  final int destination;

  const _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.destination,
  });
}
