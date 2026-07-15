import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class BuscadorClientesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> clientes;
  const BuscadorClientesDialog({required this.clientes});
  @override
  State<BuscadorClientesDialog> createState() => BuscadorClientesDialogState();
}

class BuscadorClientesDialogState extends State<BuscadorClientesDialog> {
  String _filtro = '';
  @override
  Widget build(BuildContext context) {
    final clientesFiltrados = widget.clientes.where((c) => c['nombre'].toString().toLowerCase().contains(_filtro.toLowerCase()) || c['rut'].toString().toLowerCase().contains(_filtro.toLowerCase())).toList();
    return AlertDialog(
      title: Text('Asignar Cliente Mayorista', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600, height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Buscar por Nombre o RUT...', prefixIcon: Icon(Icons.business, color: Theme.of(context).colorScheme.primary)),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: clientesFiltrados.length,
                itemBuilder: (context, index) {
                  final cliente = clientesFiltrados[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), child: Icon(Icons.domain, color: Theme.of(context).colorScheme.primary)),
                      title: Text(cliente['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('RUT: ${cliente['rut']} | Giro: ${cliente['giro']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pop(context, cliente),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.secondary)))],
    );
  }
}