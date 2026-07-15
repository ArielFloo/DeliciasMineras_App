import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/mock_database.dart';
import '../../utils/app_formatters.dart';
import '../ticket_térmico.dart';

class PanelVentasAdmin extends StatefulWidget {
  const PanelVentasAdmin({super.key});

  @override
  State<PanelVentasAdmin> createState() => _PanelVentasAdminState();
}

class _PanelVentasAdminState extends State<PanelVentasAdmin> {
  List<Map<String, dynamic>> _ventas = [];
  // NUEVA VARIABLE: Para guardar el catálogo de productos
  List<Map<String, dynamic>> _productosDisponibles = []; 
  bool _cargando = true;

  // Variables de Filtro y Búsqueda
  String _busqueda = '';
  String _filtroDocumento = 'Todos';
  String _filtroPago = 'Todos';

  final List<String> _opcionesDocumento = ['Todos', 'Boleta', 'Factura'];
  final List<String> _opcionesPago = ['Todos', 'Efectivo', 'Tarjeta', 'Transferencia'];

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _cargando = true);
    try {
      // Usamos el método que simula traer todo el historial
      final datosVentas = await MockDatabase.instancia.obtenerVentasDelDia();
      
      // 2. CARGAMOS LOS PRODUCTOS PARA RECONSTRUIR EL TICKET
      final datosProductos = await MockDatabase.instancia.obtenerProductos();
      
      // Ordenamos de la más reciente a la más antigua
      datosVentas.sort((a, b) => (b['hora'] as DateTime).compareTo(a['hora'] as DateTime));

      if (mounted) {
        setState(() {
          _ventas = datosVentas;
          _productosDisponibles = datosProductos;
          _cargando = false;
        });
      }
    } catch (e) {
      print("Error cargando ventas: $e");
    }
  }

  // NUEVA FUNCIÓN: Llama al modal del ticket
  void _mostrarBoletaReconstruida(Map<String, dynamic> venta) {
    showDialog(
      context: context,
      builder: (context) => TicketTermico(
        datosVenta: venta,
        productosDisponibles: _productosDisponibles,
      ),
    );
  }

  // Motor de Filtrado en vivo
  List<Map<String, dynamic>> get _ventasFiltradas {
    List<Map<String, dynamic>> filtrados = List.from(_ventas);

    // 1. Filtro de Búsqueda (Por ID de documento)
    if (_busqueda.isNotEmpty) {
      filtrados = filtrados.where((v) {
        final id = v['id']?.toString() ?? '';
        return id.contains(_busqueda);
      }).toList();
    }

    // 2. Filtro por Documento
    if (_filtroDocumento != 'Todos') {
      filtrados = filtrados.where((v) => v['documento'] == _filtroDocumento).toList();
    }

    // 3. Filtro por Pago (Corregido y robusto)
    if (_filtroPago != 'Todos') {
      filtrados = filtrados.where((v) {
        // En tu mock_database la clave se registra como 'metodo'
        final String metodo = v['metodo'] ?? 'Tarjeta'; 

        if (_filtroPago == 'Efectivo') {
          return metodo == 'Efectivo';
        } else if (_filtroPago == 'Tarjeta') {
          // Si el admin busca "Tarjeta", filtramos por Debito o Credito
          return metodo == 'Debito' || metodo == 'Credito' || metodo == 'Tarjeta';
        }
        return true;
      }).toList();
    }

    return filtrados;
  }

  // WIDGET GENERADOR DE SELECTORES MODERNOS (Reutilizado del Inventario)
  Widget _buildSelectorModerno<T>({
    required String label,
    required T valorSeleccionado,
    required List<T> opciones,
    required ValueChanged<T> onChanged,
    required IconData icono,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      tooltip: 'Filtrar por $label',
      offset: const Offset(0, 48),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 18, color: colorScheme.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                ),
                Text(
                  valorSeleccionado.toString(),
                  style: TextStyle(fontSize: 13, color: colorScheme.secondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return opciones.map((opt) {
          final esActivo = opt == valorSeleccionado;
          return PopupMenuItem<T>(
            value: opt,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                children: [
                  if (esActivo) ...[
                    Icon(Icons.check_circle_rounded, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    opt.toString(),
                    style: TextStyle(
                      fontWeight: esActivo ? FontWeight.bold : FontWeight.normal,
                      color: esActivo ? colorScheme.primary : colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final listaParaMostrar = _ventasFiltradas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==========================================
        // CABECERA
        // ==========================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historial de Ventas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: colorScheme.primary,
              onPressed: _cargarVentas,
              tooltip: 'Actualizar Historial',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ==========================================
        // BARRA DE HERRAMIENTAS (Búsqueda y Filtros)
        // ==========================================
        Row(
          children: [
            // Barra de Búsqueda
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por N° de Documento...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _busqueda.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                onChanged: (valor) => setState(() => _busqueda = valor),
              ),
            ),
            const SizedBox(width: 16),
            
            // Filtro por Documento
            _buildSelectorModerno<String>(
              label: 'Documento',
              valorSeleccionado: _filtroDocumento,
              opciones: _opcionesDocumento,
              icono: Icons.receipt_long_rounded,
              onChanged: (v) => setState(() => _filtroDocumento = v),
            ),
            const SizedBox(width: 12),

            // Filtro por Método de Pago
            _buildSelectorModerno<String>(
              label: 'Método Pago',
              valorSeleccionado: _filtroPago,
              opciones: _opcionesPago,
              icono: Icons.payments_rounded,
              onChanged: (v) => setState(() => _filtroPago = v),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ==========================================
        // TABLA DE VENTAS
        // ==========================================
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: listaParaMostrar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No se encontraron ventas', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.adminSidebar.withOpacity(0.05)),
                    columns: const [
                      DataColumn(label: Text('N° Doc', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Documento', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: listaParaMostrar.map((venta) {
                      final DateTime fecha = venta['hora'];
                      final String fechaFormat = "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}  ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";
                      
                      final esFactura = venta['documento'] == 'Factura';
                      final colorDoc = esFactura ? AppTheme.infoColor : AppTheme.primaryColor;

                      final String metodoPago = venta['metodo'] ?? 'Tarjeta';

                      return DataRow(
                        cells: [
                          DataCell(Text('#${venta['id'] ?? '---'}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
                          DataCell(Text(fechaFormat)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorDoc.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                venta['documento'],
                                style: TextStyle(color: colorDoc, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Icon(
                                  metodoPago == 'Efectivo' ? Icons.payments_rounded : Icons.credit_card_rounded, 
                                  size: 16, 
                                  color: Colors.grey[600]
                                ),
                                const SizedBox(width: 6),
                                Text(metodoPago),
                              ],
                            )
                          ),
                          DataCell(Text('\$${AppFormatters.formatearDinero((venta['total'] as num).toInt())}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.visibility_rounded, color: AppTheme.adminSidebar, size: 20),
                              // 3. REEMPLAZAMOS EL SNACKBAR POR LA LLAMADA AL TICKET
                              onPressed: () => _mostrarBoletaReconstruida(venta),
                              tooltip: 'Ver Detalle',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}