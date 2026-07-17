import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/ADMIN/tarjeta_metrica_admin.dart';
import '../core/app_theme.dart';
import '../widgets/ADMIN/grafico_ventas_barras.dart';
import '../widgets/ADMIN/panel_inventario_admin.dart';
import '../services/database_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/ADMIN/admin_breadcrumbs.dart';
import '../widgets/ADMIN/panel_ventas_admin.dart';
import '../widgets/ADMIN/panel_usuarios_admin.dart';
import '../widgets/ADMIN/panel_clientes_admin.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

// Variables para el desglose diario
  int _ingresosEfectivo = 0;
  int _ingresosTarjeta = 0;
  int _cantidadBoletas = 0;
  int _cantidadFacturas = 0;

  int _indiceSeleccionado = 0;
  String _filtroParaInventario = 'Predeterminado'; 
  
  bool _cargandoMetricas = true;
  int _totalProductos = 0;
  int _ingresosTotales = 0;
  int _productosPocoStock = 0;
  int _totalCompras = 0;

  bool _sidebarExpandido = true;

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

Future<void> _cargarMetricas() async {
    setState(() => _cargandoMetricas = true);
    try {
      final productos = await MockDatabase.instancia.obtenerProductos();
      final ventas = await MockDatabase.instancia.obtenerVentasDelDia();

      int ingresosCalculados = 0;
      int comprasCalculadas = 0;
      
      int calcEfectivo = 0;
      int calcTarjeta = 0;
      int calcBoletas = 0;
      int calcFacturas = 0;

      final hoy = DateTime.now(); 

      for (var venta in ventas) {
        DateTime fechaVenta = venta['hora'];
        if (fechaVenta.year == hoy.year && 
            fechaVenta.month == hoy.month && 
            fechaVenta.day == hoy.day) {

          // ARREGLO 1: Usamos 'num' y lo forzamos a int (El dinero en Chile no usa decimales)
          int totalVenta = (venta['total'] as num).toInt();
          
          ingresosCalculados += totalVenta;
          comprasCalculadas++;

          if (venta['documento'] == 'Factura') {
            calcFacturas++;
          } else {
            calcBoletas++;
          }

          String metodo = venta['metodo_pago'] ?? 'Tarjeta'; 
          if (metodo == 'Efectivo') {
            calcEfectivo += totalVenta;
          } else {
            calcTarjeta += totalVenta;
          }
        }
      }

      int stockCriticoCalculado = 0;
      for (var prod in productos) {
        // ARREGLO 2: Usamos 'num' porque el stock ahora puede ser double (ej: 1.250 kg de pan)
        if ((prod['stock'] as num) <= 5) {
          stockCriticoCalculado++;
        }
      }

      if (mounted) {
        setState(() {
          _totalProductos = productos.length;
          _totalCompras = comprasCalculadas;
          _ingresosTotales = ingresosCalculados;
          _productosPocoStock = stockCriticoCalculado;
          
          _ingresosEfectivo = calcEfectivo;
          _ingresosTarjeta = calcTarjeta;
          _cantidadBoletas = calcBoletas;
          _cantidadFacturas = calcFacturas;
          
          _cargandoMetricas = false;
        });
      }
    } catch (e) {
      print("Error cargando métricas: $e");
    }
  }

  void _mostrarDesgloseDelDia(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera del Modal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppTheme.warningColor),
                  ),
                  const SizedBox(width: 16),
                  const Text('Cuadre de Caja Hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),

              // Sección: Métodos de Pago
              Text('POR MÉTODO DE PAGO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              _FilaDesglose(icono: Icons.payments_rounded, titulo: 'Efectivo', valor: '\$${AppFormatters.formatearDinero(_ingresosEfectivo)}'),
              const SizedBox(height: 8),
              _FilaDesglose(icono: Icons.credit_card_rounded, titulo: 'Débito / Crédito', valor: '\$${AppFormatters.formatearDinero(_ingresosTarjeta)}'),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),

              // Sección: Documentos Emitidos
              Text('DOCUMENTOS TRIBUTARIOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              _FilaDesglose(icono: Icons.receipt_long_rounded, titulo: 'Boletas Emitidas', valor: '$_cantidadBoletas u.'),
              const SizedBox(height: 8),
              _FilaDesglose(icono: Icons.request_quote_rounded, titulo: 'Facturas Emitidas', valor: '$_cantidadFacturas u.'),

              const SizedBox(height: 24),
              
              // Botón Cerrar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.adminSidebar,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar Resumen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adminBackground,
      body: Row(
        children: [
          // ==========================================
          // ZONA 1: SIDEBAR INTERACTIVO Y COLAPSABLE
          // ==========================================
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _sidebarExpandido ? 250 : 76, // Ligeramente más ancho colapsado para los nuevos botones
            color: AppTheme.adminSidebar,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CABECERA (BANNER CON MÁRGENES Y MENOS INVASIVO)
                InkWell(
                  onTap: () {
                    setState(() {
                      _sidebarExpandido = !_sidebarExpandido;
                    });
                  },
                  highlightColor: Colors.transparent,
                  splashColor: Colors.white.withOpacity(0.05),
                  child: Container(
                    height: 110, // Le damos más altura para que el logo pueda crecer a lo alto
                    alignment: Alignment.center,
                    // Reducimos el margen: de 16px pasamos a solo 6px a los lados y 12px arriba/abajo
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _sidebarExpandido
                          ? Image.asset(
                              'assets/banner.png',
                              key: const ValueKey('banner_completo'),
                              fit: BoxFit.contain, 
                            )
                          : Image.asset(
                              'assets/logo.png', 
                              key: const ValueKey('logo_icono'),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // ITEMS DEL MENÚ MODERNOS
                _ItemMenuLateral(
                  titulo: 'Tablero Principal',
                  icono: Icons.dashboard_rounded,
                  estaActivo: _indiceSeleccionado == 0,
                  mostrarTexto: _sidebarExpandido,
                  onTap: () {
                    setState(() {
                      _indiceSeleccionado = 0;
                      _filtroParaInventario = 'Predeterminado'; 
                      _cargarMetricas();
                    });
                  },
                ),
                _ItemMenuLateral(
                  titulo: 'Productos',
                  icono: Icons.inventory_2_rounded,
                  estaActivo: _indiceSeleccionado == 1,
                  mostrarTexto: _sidebarExpandido,
                  onTap: () => setState(() {
                    _indiceSeleccionado = 1;
                    _filtroParaInventario = 'Predeterminado'; 
                  }),
                ),
                _ItemMenuLateral(
                  titulo: 'Ventas',
                  icono: Icons.point_of_sale_rounded,
                  estaActivo: _indiceSeleccionado == 2,
                  mostrarTexto: _sidebarExpandido,
                  onTap: () => setState(() {
                    _indiceSeleccionado = 2;
                    _filtroParaInventario = 'Predeterminado';
                  }),
                ),
                _ItemMenuLateral(
                  titulo: 'Personal',
                  icono: Icons.people_alt_rounded,
                  estaActivo: _indiceSeleccionado == 3,
                  mostrarTexto: _sidebarExpandido,
                  onTap: () => setState(() {
                    _indiceSeleccionado = 3;
                    _filtroParaInventario = 'Predeterminado';
                  }),
                ),
                
                _ItemMenuLateral(
                  titulo: 'Clientes',
                  icono: Icons.business_center_rounded,
                  estaActivo: _indiceSeleccionado == 4,
                  mostrarTexto: _sidebarExpandido,
                  onTap: () => setState(() {
                    _indiceSeleccionado = 4;
                    _filtroParaInventario = 'Predeterminado';
                  }),
                ),
                
                const Spacer(),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                
                _ItemMenuLateral(
                  titulo: 'Cerrar Sesión',
                  icono: Icons.logout_rounded,
                  estaActivo: false,
                  mostrarTexto: _sidebarExpandido,
                  esPeligro: true,
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
                Container(
                  height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_sidebarExpandido ? Icons.menu_open_rounded : Icons.menu_rounded),
                            color: Colors.grey[700],
                            onPressed: () {
                              setState(() {
                                _sidebarExpandido = !_sidebarExpandido;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                      Text(
                        _indiceSeleccionado == 0 
                            ? 'Tablero Principal' 
                            : _indiceSeleccionado == 1 
                                ? 'Control de Inventario' 
                                : _indiceSeleccionado == 2
                                    ? 'Historial de Ventas'
                                    : _indiceSeleccionado == 3 
                                        ? 'Personal & Turnos'
                                        : 'Cartera de Clientes Mayoristas',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_indiceSeleccionado == 0) ...[
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              color: AppTheme.primaryColor,
                              tooltip: 'Actualizar Métricas',
                              onPressed: _cargarMetricas,
                            ),
                            const SizedBox(width: 12),
                          ],
                          AdminBreadcrumbs(
                            indiceSeleccionado: _indiceSeleccionado,
                            onInicioPressed: () {
                              setState(() {
                                _indiceSeleccionado = 0;
                                _filtroParaInventario = 'Predeterminado'; 
                                _cargarMetricas();
                              });
                            },
                          ),
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
                        _cargandoMetricas 
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                          children: [
                            Row(
                              children: [
                                TarjetaMetricaAdmin(
                                  titulo: 'Productos Registrados', 
                                  valor: '$_totalProductos', 
                                  color: AppTheme.adminCardInfo,
                                  icono: Icons.inventory_2_outlined,
                                  onMasInfo: () => setState(() {
                                    _indiceSeleccionado = 1;
                                    _filtroParaInventario = 'Predeterminado';
                                  }),
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Total Compras', 
                                  valor: '$_totalCompras',
                                  color: AppTheme.adminCardSuccess,
                                  icono: Icons.shopping_cart_checkout,
                                  onMasInfo: () => setState(() {
                                    _indiceSeleccionado = 2;
                                  }),
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Ingresos del Día', 
                                  valor: '\$${AppFormatters.formatearDinero(_ingresosTotales)}', 
                                  color: AppTheme.adminCardWarning,
                                  icono: Icons.attach_money,
                                  onMasInfo: () => _mostrarDesgloseDelDia(context),
                                ),
                                const SizedBox(width: 16),
                                TarjetaMetricaAdmin(
                                  titulo: 'Poco Stock', 
                                  valor: '$_productosPocoStock', 
                                  color: AppTheme.adminCardDanger,
                                  icono: Icons.warning_amber_rounded,
                                  onMasInfo: () => setState(() {
                                    _indiceSeleccionado = 1;
                                    _filtroParaInventario = 'Menor Stock (Crítico)';
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: GraficoVentasBarras(),
                              ),
                            ),
                          ],
                        ),
                        PanelInventarioAdmin(
                          key: ValueKey(_filtroParaInventario),
                          filtroInicialOrden: _filtroParaInventario,
                        ),
                        // PESTAÑA 2: HISTORIAL DE VENTAS
                        const PanelVentasAdmin(),
                        const PanelUsuariosAdmin(),
                        const PanelClientesAdmin()
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

// ==========================================
// NUEVO WIDGET LATERAL: DINÁMICO, REDONDEADO Y CON HOVER
// ==========================================
class _ItemMenuLateral extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final bool estaActivo;
  final bool mostrarTexto;
  final bool esPeligro;
  final VoidCallback onTap;

  const _ItemMenuLateral({
    required this.titulo,
    required this.icono,
    required this.estaActivo,
    required this.mostrarTexto,
    this.esPeligro = false,
    required this.onTap,
  });

  @override
  State<_ItemMenuLateral> createState() => _ItemMenuLateralState();
}

class _ItemMenuLateralState extends State<_ItemMenuLateral> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Definimos el color de fondo y de texto dependiendo del estado (activo, hover, peligro)
    final colorFondo = widget.estaActivo
        ? AppTheme.primaryColor.withOpacity(0.15) // Fondo sutil del color primario
        : _isHovered
            ? (widget.esPeligro ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.08))
            : Colors.transparent;

    final colorContenido = widget.estaActivo
        ? AppTheme.primaryColor // Resalta en el color principal (naranja)
        : _isHovered
            ? (widget.esPeligro ? Colors.redAccent : Colors.white) // Se ilumina en hover
            : Colors.white54; // Apagado por defecto

    return Padding(
      // Padding exterior para que no toque los bordes del sidebar
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12), // Bordes redondeados modernos
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuint,
            // Aquí está la magia: el padding lateral aumenta si pasas el mouse (crea un efecto de ampliación)
            padding: EdgeInsets.symmetric(
              vertical: 14.0, 
              horizontal: widget.mostrarTexto ? (_isHovered ? 20.0 : 16.0) : 0, 
            ),
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: widget.mostrarTexto ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  // El ícono se agranda ligeramente
                  transform: Matrix4.identity()..scale(_isHovered ? 1.1 : 1.0),
                  child: Icon(
                    widget.icono,
                    color: colorContenido,
                    size: 24,
                  ),
                ),
                if (widget.mostrarTexto) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorContenido,
                        fontWeight: widget.estaActivo || _isHovered ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaDesglose extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _FilaDesglose({required this.icono, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(titulo, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
          ],
        ),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}