import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/mock_database.dart'; // NUEVA IMPORTACIÓN

class PanelInventarioAdmin extends StatefulWidget {
  const PanelInventarioAdmin({super.key});

  @override
  State<PanelInventarioAdmin> createState() => _PanelInventarioAdminState();
}

class _PanelInventarioAdminState extends State<PanelInventarioAdmin> {
  // Ahora la lista arranca vacía
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  // Función que va a la base de datos a buscar el stock actual
  Future<void> _cargarInventario() async {
    setState(() => _cargando = true);
    try {
      final datos = await MockDatabase.instancia.obtenerProductos();
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

  void _editarProducto(Map<String, dynamic> producto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar: ${producto['nombre']} (Próximamente)')),
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                // Agregamos un botón para refrescar la tabla manualmente
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: colorScheme.primary,
                  onPressed: _cargarInventario,
                  tooltip: 'Actualizar Stock',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.adminSidebar.withOpacity(0.05)),
                columns: const [
                  DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _productos.map((prod) {
                  final int stock = prod['stock'];
                  
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
                            color: estadoColor.withOpacity(0.1),
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
                              icon: Icon(Icons.edit, color: AppTheme.infoColor, size: 20),
                              onPressed: () => _editarProducto(prod),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                              onPressed: () {},
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