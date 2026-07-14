import 'package:flutter/material.dart';
import '../../core/app_theme.dart';


class BuscadorProductosDialog extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  const BuscadorProductosDialog({required this.productos});
  @override
  State<BuscadorProductosDialog> createState() => BuscadorProductosDialogState();
}

class BuscadorProductosDialogState extends State<BuscadorProductosDialog> {
  String _filtro = '';
  @override
  Widget build(BuildContext context) {
    final productosFiltrados = widget.productos.where((p) => p['nombre'].toString().toLowerCase().contains(_filtro.toLowerCase())).toList();
    return AlertDialog(
      title: Text('Buscar Producto', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500, height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Escribe el nombre del producto...', prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary)),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: productosFiltrados.length,
                itemBuilder: (context, index) {
                  final prod = productosFiltrados[index];
                  final bool sinStock = prod['stock'] == 0;
                  return ListTile(
                    title: Text(prod['nombre']),
                    subtitle: Text('SKU: ${prod['sku']} | Precio: \$${prod['precio']}'),
                    trailing: Text('Stock: ${prod['stock']}', style: TextStyle(color: sinStock ? AppTheme.errorColor : AppTheme.successColor, fontWeight: FontWeight.bold)),
                    enabled: !sinStock, 
                    onTap: () => Navigator.pop(context, prod),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cerrar', style: TextStyle(color: Theme.of(context).colorScheme.secondary)))],
    );
  }
}

