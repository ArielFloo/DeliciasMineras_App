import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/database_service.dart';
import 'modal_formulario_producto.dart';

class PanelInventarioAdmin extends StatefulWidget {
  final String filtroInicialOrden;

  const PanelInventarioAdmin({
    super.key, 
    this.filtroInicialOrden = 'Predeterminado', // Por defecto, carga normal
  });

  @override
  State<PanelInventarioAdmin> createState() => _PanelInventarioAdminState();
}

class _PanelInventarioAdminState extends State<PanelInventarioAdmin> {
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = true;

  // Variables de Filtro y Búsqueda
  String _busqueda = '';
  String _categoriaFiltro = 'Todas';
  late String _ordenStock;

  final List<String> _categorias = ['Todas', 'Panadería', 'Pastelería', 'Bebidas', 'Abarrotes'];
  final List<String> _opcionesOrden = ['Predeterminado', 'Menor Stock (Crítico)', 'Mayor Stock'];

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // NUEVO: Asignamos el valor que viene desde el parámetro al iniciar
    _ordenStock = widget.filtroInicialOrden; 
    _cargarInventario();
  }

  Future<void> _cargarInventario() async {
    setState(() => _cargando = true);
    try {
      final datos = await DatabaseService.instancia.obtenerProductos();
      if (mounted) {
        setState(() {
          _productos = datos;
          _cargando = false;
        });
      }
    } catch (e) {
      print("Error cargando inventario: $e");
    }
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? producto}) async {
    final bool? recargar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalFormularioProducto(productoAEditar: producto),
    );

    if (recargar == true) {
      _cargarInventario(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventario actualizado correctamente.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _eliminarProductoSeguro(Map<String, dynamic> producto) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono de Peligro Estilizado (Rojo Soft)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppTheme.errorColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                '¿Eliminar Producto?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Contenido con el texto destacado
              Text.rich(
                TextSpan(
                  text: 'Estás a punto de borrar del catálogo a ',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, height: 1.4),
                  children: [
                    TextSpan(
                      text: '"${producto['nombre']}"',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary),
                    ),
                    const TextSpan(
                      text: '.\nEsta acción es irreversible y afectará los reportes de stock.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Botones de Acción Modernos
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text(
                        'Sí, Eliminar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      await DatabaseService.instancia.eliminarProducto(producto['sku']);
      _cargarInventario();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${producto['nombre']}" eliminado correctamente.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  // Motor de Filtrado en vivo
  List<Map<String, dynamic>> get _productosFiltrados {
    List<Map<String, dynamic>> filtrados = List.from(_productos);

    if (_busqueda.isNotEmpty) {
      final query = _busqueda.toLowerCase();
      filtrados = filtrados.where((p) {
        final nombre = p['nombre'].toString().toLowerCase();
        final sku = p['sku'].toString();
        return nombre.contains(query) || sku.contains(query);
      }).toList();
    }

    if (_categoriaFiltro != 'Todas') {
      filtrados = filtrados.where((p) => p['categoria'] == _categoriaFiltro).toList();
    }

    if (_ordenStock == 'Menor Stock (Crítico)') {
      filtrados.sort((a, b) => (a['stock'] as num).compareTo(b['stock'] as num));
    } else if (_ordenStock == 'Mayor Stock') {
      filtrados.sort((a, b) => (b['stock'] as num).compareTo(a['stock'] as num));
    }

    return filtrados;
  }

  // WIDGET GENERADOR DE SELECTORES MODERNOS (Reemplaza al feo Dropdown)
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
      offset: const Offset(0, 48), // Desplaza el menú justo abajo del botón
      elevation: 8,
      // Redondeamos las esquinas de la tarjeta flotante
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando inventario desde la base de datos...'),
          ],
        ),
      );
    }

    final listaParaMostrar = _productosFiltrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CABECERA Y BOTÓN NUEVO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Control de Inventario',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: colorScheme.primary,
                  onPressed: _cargarInventario,
                  tooltip: 'Actualizar Stock desde BD',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _abrirFormulario(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // BARRA DE HERRAMIENTAS (Búsqueda y Filtros con diseño SaaS premium)
        Row(
          children: [
            // Barra de Búsqueda redondeada
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o SKU...',
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
            
            // Filtro de Categoría Rediseñado
            _buildSelectorModerno<String>(
              label: 'Categoría',
              valorSeleccionado: _categoriaFiltro,
              opciones: _categorias,
              icono: Icons.category_outlined,
              onChanged: (v) => setState(() => _categoriaFiltro = v),
            ),
            const SizedBox(width: 12),

            // Filtro de Orden de Stock Rediseñado
            _buildSelectorModerno<String>(
              label: 'Ordenar por',
              valorSeleccionado: _ordenStock,
              opciones: _opcionesOrden,
              icono: Icons.swap_vert_rounded,
              onChanged: (v) => setState(() => _ordenStock = v),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // TABLA DE PRODUCTOS
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
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No se encontraron productos', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.adminSidebar.withValues(alpha: 0.05)),
                    columns: const [
                      DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: listaParaMostrar.map((prod) {
                      final num stock = prod['stock'];
                      
                      Color estadoColor;
                      String estadoTexto;
                      if (stock == 0) {
                        estadoColor = AppTheme.errorColor;
                        estadoTexto = 'Sin Stock';
                      } else if (stock <= 5) {
                        estadoColor = AppTheme.warningColor;
                        estadoTexto = 'Stock Crítico';
                      } else {
                        estadoColor = AppTheme.successColor;
                        estadoTexto = 'Disponible';
                      }

                      return DataRow(
                        cells: [
                          DataCell(Text('#${prod['sku']}')),
                          DataCell(Text(prod['nombre'], style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(prod['categoria'])),
                          DataCell(Text('\$${prod['precio']}')),
                          DataCell(Text('$stock uds', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: estadoColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                estadoTexto,
                                style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.infoColor, size: 20),
                                  onPressed: () => _abrirFormulario(producto: prod),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                                  onPressed: () => _eliminarProductoSeguro(prod),
                                  tooltip: 'Eliminar',
                                ),
                              ],
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