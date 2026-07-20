import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../services/database_service.dart';
import 'detalle_envio_screen.dart';
import '../../widgets/REPARTIDOR/tarjeta_envio.dart';

class RepartidorHomeScreen extends StatefulWidget {
  const RepartidorHomeScreen({super.key});

  @override
  State<RepartidorHomeScreen> createState() => _RepartidorHomeScreenState();
}

class _RepartidorHomeScreenState extends State<RepartidorHomeScreen> {
  late Future<List<Map<String, dynamic>>> _futureEnvios;
  int _entregasCompletadas = 0;

  @override
  void initState() {
    super.initState();
    _cargarEnvios();
  }

  void _cargarEnvios() {
    _futureEnvios = DatabaseService.instancia.obtenerEnviosRepartidor();
  }

  Future<void> _refrescar() async {
    setState(() => _cargarEnvios());
  }

  Future<void> _navegarADetalle(
    Map<String, dynamic> envio,
    List<Map<String, dynamic>> listaActual,
  ) async {
    final entregaConfirmada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetalleEnvioScreen(envio: envio)),
    );

    if (entregaConfirmada == true && mounted) {
      setState(() {
        _entregasCompletadas++;
        // Recargamos la lista desde Supabase para reflejar el estado real
        _cargarEnvios();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entrega a ${envio['razonSocial']} confirmada ✓'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adminBackground,
      appBar: AppBar(
        title: const Text(
          'Mis Envíos del Día',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.secondaryColor,
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.go('/'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refrescar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEnvios,
        builder: (context, snapshot) {
          // --- Estado: cargando ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          // --- Estado: error de red o Supabase ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudieron cargar los envíos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verifica tu conexión e intenta de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refrescar,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final envios = snapshot.data ?? [];

          // --- Estado: sin envíos asignados ---
          if (envios.isEmpty) {
            return _buildEmptyState();
          }

          // --- Estado: lista con datos ---
          return RefreshIndicator(
            onRefresh: _refrescar,
            color: AppTheme.primaryColor,
            child: Column(
              children: [
                _buildResumenHeader(totalAsignados: envios.length),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: envios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final envio = envios[index];
                      return TarjetaEnvio(
                        envio: envio,
                        precioFormateado: envio['precioFormateado'],
                        onEntregado: (envioEntregado) {
                          setState(() {
                            _entregasCompletadas++;
                            _cargarEnvios();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Entrega a ${envioEntregado['razonSocial']} confirmada ✓',
                              ),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumenHeader({required int totalAsignados}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.local_shipping_rounded,
            label: 'Pendientes',
            value: '$totalAsignados',
            color: AppTheme.primaryColor,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            label: 'Completados',
            value: '$_entregasCompletadas',
            color: AppTheme.successColor,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.access_time_rounded,
            label: 'Próximo',
            value: totalAsignados > 0 ? 'Ver lista' : '--',
            color: AppTheme.infoColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Jornada completada!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No tienes envíos pendientes por el momento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
