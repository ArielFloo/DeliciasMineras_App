import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/tarjeta_metrica_admin.dart';
import '../core/app_theme.dart';
import '../widgets/grafico_ventas_barras.dart';
import '../widgets/panel_inventario.dart'; // Corregí el nombre del import según lo creamos

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _indiceSeleccionado = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adminBackground,
      body: Row(
        children: [
          // ==========================================
          // ZONA 1: MENÚ LATERAL OSCURO (Sidebar)
          // ==========================================
          Container(
            width: 250,
            color: AppTheme.adminSidebar,
            child: Column(
              children: [
                Container(
                  height: 60,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.black.withOpacity(0.2),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Admin POS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                _ItemMenuLateral(
                  titulo: 'Tablero Principal',
                  icono: Icons.dashboard,
                  estaActivo: _indiceSeleccionado == 0,
                  onTap: () => setState(() => _indiceSeleccionado = 0),
                ),
                _ItemMenuLateral(
                  titulo: 'Productos',
                  icono: Icons.inventory,
                  estaActivo: _indiceSeleccionado == 1,
                  onTap: () => setState(() => _indiceSeleccionado = 1),
                ),
                _ItemMenuLateral(
                  titulo: 'Ventas',
                  icono: Icons.point_of_sale,
                  estaActivo: _indiceSeleccionado == 2,
                  onTap: () => setState(() => _indiceSeleccionado = 2),
                ),
                
                const Spacer(),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white54),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white54)),
                  onTap: () => context.go('/'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ==========================================
          // ZONA 2: ÁREA PRINCIPAL DE CONTENIDO
          // ==========================================
          Expanded(
            child: Column(
              children: [
                // Barra superior (AppBar blanca)
                Container(
                  height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tablero Principal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Inicio / Tablero Principal', style: TextStyle(color: AppTheme.infoColor)),
                    ],
                  ),
                ),
                
                // Contenido dinámico según la pestaña seleccionada
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: IndexedStack(
                      index: _indiceSeleccionado,
                      children: [
                        // PESTAÑA 0: TABLERO PRINCIPAL
                        Column(
                          children: [
                            // FILA DE TARJETAS (Métricas)
                            Row(
                              children: [
                                TarjetaMetricaAdmin(
                                  titulo: 'Productos Registrados', 
                                  valor: '102', 
                                  color: AppTheme.adminCardInfo,
                                  icono: Icons.inventory_2_outlined,
                                  onMasInfo: () => setState(() => _indiceSeleccionado = 1), // Te manda a inventario
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Total Compras', 
                                  valor: '\$3,889', 
                                  color: AppTheme.adminCardSuccess,
                                  icono: Icons.shopping_cart_checkout,
                                  onMasInfo: () {},
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Total Ventas', 
                                  valor: '\$238.25', 
                                  color: AppTheme.adminCardWarning,
                                  icono: Icons.attach_money,
                                  onMasInfo: () {},
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Poco Stock', 
                                  valor: '1', 
                                  color: AppTheme.adminCardDanger,
                                  icono: Icons.warning_amber_rounded,
                                  onMasInfo: () => setState(() => _indiceSeleccionado = 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // ZONA DEL GRÁFICO CENTRAL
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.adminCardInfo,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.bar_chart, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Ventas del Mes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
                                        child: GraficoVentasBarras(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // PESTAÑA 1: PANEL DE INVENTARIO
                        const PanelInventarioAdmin(),

                        // PESTAÑA 2: VENTAS (Marcador de posición)
                        const Center(child: Text('Historial de Documentos Emitidos (Próximamente)')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pequeño widget interno para los botones del menú lateral
class _ItemMenuLateral extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final bool estaActivo;
  final VoidCallback onTap;

  const _ItemMenuLateral({
    required this.titulo,
    required this.icono,
    required this.estaActivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        selected: estaActivo,
        selectedTileColor: Colors.white.withOpacity(0.1),
        leading: Icon(icono, color: estaActivo ? Colors.white : Colors.white54),
        title: Text(
          titulo,
          style: TextStyle(
            color: estaActivo ? Colors.white : Colors.white54,
            fontWeight: estaActivo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}