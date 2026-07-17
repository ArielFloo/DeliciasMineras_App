import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class BuscadorProductosDialog extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  const BuscadorProductosDialog({super.key, required this.productos});
  
  @override
  State<BuscadorProductosDialog> createState() => BuscadorProductosDialogState();
}

class BuscadorProductosDialogState extends State<BuscadorProductosDialog> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Filtramos usando la misma lógica robusta para los nombres de la BD
    final productosFiltrados = widget.productos.where((p) {
      final nombreRaw = p['nombreproducto']?.toString() ?? p['nombre']?.toString() ?? '';
      return nombreRaw.toLowerCase().contains(_filtro.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABECERA MODERNA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Catálogo de Productos', 
                      style: TextStyle(
                        color: theme.colorScheme.primary, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                      )
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.pop(context, null),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // --- BARRA DE BÚSQUEDA ---
            TextField(
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
            const SizedBox(height: 16),
            
            // --- LISTA DE RESULTADOS ---
            Expanded(
              child: productosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(color: theme.colorScheme.outline, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                itemCount: productosFiltrados.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prod = productosFiltrados[index];
                  final bool sinStock = prod['stock'] == 0;
                  
                  // 1. Limpieza del nombre (por los guiones bajos en la BD)
                  String nombreRaw = prod['nombreproducto'] ?? prod['nombre'] ?? 'Producto Sin Nombre';
                  final String nombreAMostrar = nombreRaw.startsWith('_') ? nombreRaw.substring(1) : nombreRaw;
                  
                  // 2. Simplificación del SKU (ocultar los 2 millones)
                  final int skuOriginal = prod['sku'];
                  final int skuVisual = skuOriginal >= 2000000 ? skuOriginal - 2000000 : skuOriginal;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    hoverColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
                    title: Text(
                      nombreAMostrar, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        'SKU: $skuVisual  •  Precio: \$${prod['precio']}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sinStock ? AppTheme.errorColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sinStock ? AppTheme.errorColor : AppTheme.successColor,
                          width: 1.5,
                        )
                      ),
                      child: Text(
                        sinStock ? 'Sin Stock' : 'Stock: ${prod['stock']}', 
                        style: TextStyle(
                          color: sinStock ? AppTheme.errorColor : AppTheme.successColor, 
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        )
                      ),
                    ),
                    enabled: !sinStock, 
                    onTap: () => Navigator.pop(context, prod),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}