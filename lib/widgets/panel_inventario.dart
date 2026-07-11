import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class PanelInventarioAdmin extends StatefulWidget {
  const PanelInventarioAdmin({super.key});

  @override
  State<PanelInventarioAdmin> createState() => _PanelInventarioAdminState();
}

class _PanelInventarioAdminState extends State<PanelInventarioAdmin> {
  // Simulación de la base de datos de productos en el administrador
  final List<Map<String, dynamic>> _productos = [
    {'sku': 1, 'nombre': 'Pan de Molde Integral', 'precio': 2500, 'stock': 2, 'categoria': 'Panadería'},
    {'sku': 2, 'nombre': 'Medialunas', 'precio': 600, 'stock': 20, 'categoria': 'Pastelería'}, 
    {'sku': 3, 'nombre': 'Kuchen de Manzana', 'precio': 8500, 'stock': 13, 'categoria': 'Pastelería'},
    {'sku': 4, 'nombre': 'Baguette', 'precio': 1200, 'stock': 10, 'categoria': 'Panadería'},
    {'sku': 5, 'nombre': 'Donas Glaseadas', 'precio': 1000, 'stock': 0, 'categoria': 'Pastelería'}, 
  ];

  void _editarProducto(Map<String, dynamic> producto) {
    // Aquí puedes abrir un diálogo en el futuro para editar precio o stock
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar: ${producto['nombre']} (Próximamente)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera con botón de agregar producto nuevo
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Lógica futura para añadir un nuevo SKU
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tabla de Productos
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
                  
                  // Definimos etiquetas dinámicas de stock usando tus colores semánticos
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
                      DataCell(Text('$stock uds')),
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