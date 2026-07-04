import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CajeroHomeScreen extends StatefulWidget {
  const CajeroHomeScreen({super.key});

  @override
  State<CajeroHomeScreen> createState() => _CajeroHomeScreenState();
}

class _CajeroHomeScreenState extends State<CajeroHomeScreen> {
  final TextEditingController _skuController = TextEditingController();

  final List<Map<String, dynamic>> _productosDisponibles = [
    {'sku': 1, 'nombre': 'Pan de Molde Integral', 'precio': 2500, 'stock': 2},
    {'sku': 2, 'nombre': 'Medialunas', 'precio': 600, 'stock': 3},
    {'sku': 3, 'nombre': 'Kuchen de Manzana', 'precio': 8500, 'stock': 13},
    {'sku': 4, 'nombre': 'Baguette', 'precio': 1200, 'stock': 10},
    {'sku': 5, 'nombre': 'Donas Glaseadas', 'precio': 1000, 'stock': 0}, 
  ];

  final List<Map<String, dynamic>> _clientesMayoristas = [
    {'rut': '76738555-3', 'nombre': 'Laboratorio Carreño, Mora y Jara Ltda.', 'giro': 'Laboratorio'},
    {'rut': '74498685-0', 'nombre': 'Grupo Díaz y Catalan S.p.A.', 'giro': 'Comercio'},
    {'rut': '78956253-6', 'nombre': 'Becerra, Garrido y Olivares Ltda.', 'giro': 'Distribución'},
  ];

  final Map<int, int> _carrito = {};
  Map<String, dynamic>? _clienteSeleccionado;
  
  // ESTADOS NUEVOS PARA EL PEDIDO Y DESPACHO
  String? _tipoPedido; // Puede ser 'retiro' o 'despacho'
  final int _tarifaDespachoFija = 3500;

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      int sku = producto['sku'];
      int stockActual = producto['stock'];
      int cantidadEnCarrito = _carrito[sku] ?? 0;

      if (cantidadEnCarrito < stockActual) {
        _carrito[sku] = cantidadEnCarrito + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay más stock de ${producto['nombre']}')),
        );
      }
    });
  }

  void _removerDelCarrito(int sku) {
    setState(() {
      if (_carrito.containsKey(sku) && _carrito[sku]! > 1) {
        _carrito[sku] = _carrito[sku]! - 1;
      } else {
        _carrito.remove(sku);
      }
    });
  }

  void _buscarYAgregarPorSKU(String input) {
    if (input.isEmpty) return;
    final int? skuBuscado = int.tryParse(input);
    
    if (skuBuscado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un SKU numérico válido.')),
      );
      return;
    }

    final index = _productosDisponibles.indexWhere((p) => p['sku'] == skuBuscado);
    if (index != -1) {
      _agregarAlCarrito(_productosDisponibles[index]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SKU $skuBuscado no encontrado en el sistema.')),
      );
    }
    _skuController.clear();
  }

  Future<void> _abrirBuscadorAvanzado() async {
    final Map<String, dynamic>? productoSeleccionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BuscadorProductosDialog(productos: _productosDisponibles),
    );
    if (productoSeleccionado != null) {
      _agregarAlCarrito(productoSeleccionado);
    }
  }

  Future<void> _abrirBuscadorMayoristas() async {
    final Map<String, dynamic>? clienteEncontrado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BuscadorClientesDialog(clientes: _clientesMayoristas),
    );
    if (clienteEncontrado != null) {
      setState(() {
        _clienteSeleccionado = clienteEncontrado;
      });
    }
  }

  // NUEVA FUNCIÓN: Lógica para configurar el tipo de pedido
  Future<void> _configurarPedido() async {
    final String? seleccion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Programar Pedido',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
        ),
        content: const Text('¿Este pedido es para retiro en local o requiere despacho al cliente?'),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'retiro'),
            icon: const Icon(Icons.storefront),
            label: const Text('Retiro en Local'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'despacho'),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Despacho'),
          ),
        ],
      ),
    );

    if (seleccion != null) {
      // Validamos la regla de negocio de la base de datos
      if (seleccion == 'despacho' && _clienteSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: El despacho es exclusivo para clientes Empresa. Asigne un cliente mayorista primero.'),
          ),
        );
        return; // Bloqueamos la acción
      }
      setState(() {
        _tipoPedido = seleccion;
      });
    }
  }

  int get _totalCompra {
    int total = 0;
    _carrito.forEach((sku, cantidad) {
      final producto = _productosDisponibles.firstWhere((p) => p['sku'] == sku);
      total += (producto['precio'] as int) * cantidad;
    });
    // Sumamos el despacho si corresponde
    if (_tipoPedido == 'despacho') {
      total += _tarifaDespachoFija;
    }
    return total;
  }

  @override
  void dispose() {
    _skuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delicias Mineras - Terminal de Caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Row(
        children: [
          // LADO IZQUIERDO: Boleta Gigante y Buscador Principal
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skuController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 20),
                          decoration: InputDecoration(
                            labelText: 'Pistolear o Ingresar SKU',
                            hintText: 'Ej: 1, 2, 3...',
                            prefixIcon: const Icon(Icons.qr_code_scanner, size: 32),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.keyboard_return, color: Theme.of(context).colorScheme.primary),
                              onPressed: () => _buscarYAgregarPorSKU(_skuController.text),
                            ),
                          ),
                          onSubmitted: _buscarYAgregarPorSKU,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _abrirBuscadorAvanzado,
                          icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                          label: const Text('Buscar por Nombre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalle de la Transacción',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      // Mostrar etiqueta si es pedido especial
                      if (_tipoPedido != null)
                        Chip(
                          backgroundColor: _tipoPedido == 'despacho' ? Colors.orange[100] : Colors.blue[100],
                          label: Text(
                            _tipoPedido == 'despacho' ? '🚚 DESPACHO' : '🛍️ RETIRO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _tipoPedido == 'despacho' ? Colors.orange[900] : Colors.blue[900],
                            ),
                          ),
                          onDeleted: () => setState(() => _tipoPedido = null),
                        ),
                    ],
                  ),
                  const Divider(thickness: 2),
                  
                  Expanded(
                    child: _carrito.isEmpty
                        ? const Center(
                            child: Text(
                              'Escanea un producto para comenzar',
                              style: TextStyle(fontSize: 20, color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _carrito.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final sku = _carrito.keys.elementAt(index);
                              final cantidad = _carrito[sku]!;
                              final prod = _productosDisponibles.firstWhere((p) => p['sku'] == sku);
                              final subtotal = (prod['precio'] as int) * cantidad;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(prod['nombre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                subtitle: Text('SKU: ${prod['sku']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$cantidad x \$${prod['precio']} = \$$subtotal', style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removerDelCarrito(sku),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // NUEVO: Fila del costo de despacho en la boleta
                  if (_tipoPedido == 'despacho') ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_shipping, color: Colors.orange),
                      title: const Text('Costo de Envío Fijo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      trailing: Text('\$$_tarifaDespachoFija', style: const TextStyle(fontSize: 18)),
                    ),
                  ],

                  const Divider(thickness: 2),
                  Text(
                    'Total a Pagar: \$$_totalCompra',
                    style: TextStyle(
                      fontSize: 40, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),

          // LADO DERECHO: Panel de Control
          Container(
            width: 320, 
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_clienteSeleccionado == null) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.teal[700],
                      side: BorderSide(color: Colors.teal[700]!),
                    ),
                    onPressed: _abrirBuscadorMayoristas,
                    icon: const Icon(Icons.business),
                    label: const Text('Asignar Venta Mayorista', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  Card(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.verified, color: Colors.amber, size: 20),
                                  SizedBox(width: 8),
                                  Text('CLIENTE EMPRESA', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _clienteSeleccionado = null;
                                    // Si quitamos el cliente empresa, anulamos el despacho si estaba activo
                                    if (_tipoPedido == 'despacho') _tipoPedido = null;
                                  });
                                },
                                child: const Icon(Icons.close, color: Colors.white70, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _clienteSeleccionado!['nombre'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text('RUT: ${_clienteSeleccionado!['rut']}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                
                // NUEVO BOTÓN: A Pedido
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.orange[800],
                    side: BorderSide(color: Colors.orange[800]!),
                  ),
                  onPressed: _configurarPedido,
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Programar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carrito.isEmpty ? null : () {
                    print("Procediendo al pago...");
                  },
                  icon: const Icon(Icons.payment, size: 28),
                  label: const Text('COBRAR BOLETA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Emitir Factura'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.pan_tool),
                  label: const Text('Venta Manual'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.assessment),
                  label: const Text('Detalle Venta del Día'),
                ),
                
                const Spacer(), 
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.lock_clock),
                  label: const Text('Cierre de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... Mantienes los widgets _BuscadorProductosDialog y _BuscadorClientesDialog intactos al final
class _BuscadorProductosDialog extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  const _BuscadorProductosDialog({required this.productos});
  @override
  State<_BuscadorProductosDialog> createState() => _BuscadorProductosDialogState();
}

class _BuscadorProductosDialogState extends State<_BuscadorProductosDialog> {
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
                    trailing: Text('Stock: ${prod['stock']}', style: TextStyle(color: sinStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
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

class _BuscadorClientesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> clientes;
  const _BuscadorClientesDialog({required this.clientes});
  @override
  State<_BuscadorClientesDialog> createState() => _BuscadorClientesDialogState();
}

class _BuscadorClientesDialogState extends State<_BuscadorClientesDialog> {
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