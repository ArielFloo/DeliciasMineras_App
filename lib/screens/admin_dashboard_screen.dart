import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/tarjeta_metrica_admin.dart';
import '../core/app_theme.dart';
import '../widgets/grafico_ventas_barras.dart';
import '../widgets/panel_inventario_admin.dart';
import '../data/mock_database.dart';
import '../utils/app_formatters.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _indiceSeleccionado = 0;
  
  // VARIABLES DE ESTADO PARA LOS INDICADORES
  bool _cargandoMetricas = true;
  int _totalProductos = 0;
  int _ingresosTotales = 0;
  int _productosPocoStock = 0;

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  // Función para calcular los KPIs desde la base de datos
  Future<void> _cargarMetricas() async {
    setState(() => _cargandoMetricas = true);
    
    try {
      final productos = await MockDatabase.instancia.obtenerProductos();
      final ventas = await MockDatabase.instancia.obtenerVentasDelDia();

      int ingresosCalculados = 0;
      final hoy = DateTime.now(); // Capturamos la fecha actual

      for (var venta in ventas) {
        DateTime fechaVenta = venta['hora'];
        
        // ¡LA MAGIA AQUÍ! Solo sumamos la venta si el año, mes y día coinciden con HOY
        if (fechaVenta.year == hoy.year && 
            fechaVenta.month == hoy.month && 
            fechaVenta.day == hoy.day) {
          ingresosCalculados += venta['total'] as int;
        }
      }

      int stockCriticoCalculado = 0;
      for (var prod in productos) {
        if ((prod['stock'] as int) <= 5) {
          stockCriticoCalculado++;
        }
      }

      if (mounted) {
        setState(() {
          _totalProductos = productos.length;
          _ingresosTotales = ingresosCalculados;
          _productosPocoStock = stockCriticoCalculado;
          _cargandoMetricas = false;
        });
      }
    } catch (e) {
      print("Error cargando métricas: $e");
    }
  }

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
                  onTap: () {
                    setState(() => _indiceSeleccionado = 0);
                    _cargarMetricas(); // Refresca al volver al inicio
                  },
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            color: AppTheme.primaryColor,
                            tooltip: 'Actualizar Métricas',
                            onPressed: _cargarMetricas,
                          ),
                          const SizedBox(width: 8),
                          Text('Inicio / Tablero Principal', style: TextStyle(color: AppTheme.infoColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: IndexedStack(
                      index: _indiceSeleccionado,
                      children: [
                        // PESTAÑA 0: TABLERO PRINCIPAL
                        _cargandoMetricas 
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                          children: [
                            // FILA DE TARJETAS (Métricas Reales)
                            Row(
                              children: [
                                TarjetaMetricaAdmin(
                                  titulo: 'Productos Registrados', 
                                  valor: '$_totalProductos', 
                                  color: AppTheme.adminCardInfo,
                                  icono: Icons.inventory_2_outlined,
                                  onMasInfo: () => setState(() => _indiceSeleccionado = 1),
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Total Compras', 
                                  valor: '\$0', // Se implementará cuando haya modulo de proveedores
                                  color: AppTheme.adminCardSuccess,
                                  icono: Icons.shopping_cart_checkout,
                                  onMasInfo: () {},
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Ingresos del Día', 
                                  valor: '\$${AppFormatters.formatearDinero(_ingresosTotales)}',
                                  color: AppTheme.adminCardWarning,
                                  icono: Icons.attach_money,
                                  onMasInfo: () {},
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Poco Stock', 
                                  valor: '$_productosPocoStock', 
                                  color: AppTheme.adminCardDanger,
                                  icono: Icons.warning_amber_rounded,
                                  onMasInfo: () => setState(() => _indiceSeleccionado = 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // ZONA DEL GRÁFICO CENTRAL
                            const Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: GraficoVentasBarras(),
                              ),
                            ),
                          ],
                        ),
                        
                        // PESTAÑA 1: PANEL DE INVENTARIO
                        const PanelInventarioAdmin(),

                        // PESTAÑA 2: VENTAS 
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