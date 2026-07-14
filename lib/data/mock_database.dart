import 'dart:async';

class MockDatabase {
  static final MockDatabase instancia = MockDatabase._interno();
  MockDatabase._interno();

  // ==========================================
  // TABLAS EN MEMORIA (El estado global)
  // ==========================================
  final List<Map<String, dynamic>> _productos = [
    {'sku': 1, 'nombre': 'Pan Kilo', 'precio': 2500, 'stock': 50, 'categoria': 'Panadería'},
    {'sku': 2, 'nombre': 'Medialunas', 'precio': 600, 'stock': 20, 'categoria': 'Pastelería'}, 
    {'sku': 3, 'nombre': 'Kuchen de Manzana', 'precio': 8500, 'stock': 13, 'categoria': 'Pastelería'},
    {'sku': 4, 'nombre': 'Baguette', 'precio': 1200, 'stock': 10, 'categoria': 'Panadería'},
    {'sku': 5, 'nombre': 'Donas Glaseadas', 'precio': 1000, 'stock': 0, 'categoria': 'Pastelería'}, 
  ];

  final List<Map<String, dynamic>> _clientesMayoristas = [
    {'rut': '76738555-3', 'nombre': 'Laboratorio Carreño, Mora y Jara Ltda.', 'giro': 'Laboratorio'},
    {'rut': '74498685-0', 'nombre': 'Grupo Díaz y Catalan S.p.A.', 'giro': 'Comercio'},
    {'rut': '78956253-6', 'nombre': 'Becerra, Garrido y Olivares Ltda.', 'giro': 'Distribución'},
  ];

// Lista de ventas con algo de historia falsa
  final List<Map<String, dynamic>> _ventas = [
    {'hora': DateTime.now().subtract(const Duration(days: 4)), 'documento': 'Boleta', 'metodo': 'Efectivo', 'total': 15000},
    {'hora': DateTime.now().subtract(const Duration(days: 3)), 'documento': 'Factura', 'metodo': 'Transferencia', 'total': 45000},
    {'hora': DateTime.now().subtract(const Duration(days: 2)), 'documento': 'Boleta', 'metodo': 'Efectivo', 'total': 22500},
    {'hora': DateTime.now().subtract(const Duration(days: 1)), 'documento': 'Boleta', 'metodo': 'Debito', 'total': 18000},
    {'hora': DateTime.now().subtract(const Duration(days: 1)), 'documento': 'Factura', 'metodo': 'Credito', 'total': 50000},
  ];

  final List<Map<String, dynamic>> _valesInternos = [];

  DateTime? _ultimoReseteo;

  void _verificarReseteoDiario() {
      final ahora = DateTime.now();
      
      if (_ultimoReseteo == null || 
          _ultimoReseteo!.day != ahora.day || 
          _ultimoReseteo!.month != ahora.month || 
          _ultimoReseteo!.year != ahora.year) {
        
      for (var producto in _productos) {
        if (producto['categoria'] == 'Panadería') {
          producto['stock'] = 50.0;
        }
      }
        
        _ultimoReseteo = ahora;
      }
    }

  // Simulador de latencia de red (Medio segundo)
  Future<void> _latenciaRed() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ==========================================
  // MÉTODOS DE LECTURA (GETTERS ASÍNCRONOS)
  // ==========================================
  
  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    await _latenciaRed();
    _verificarReseteoDiario();
    return List<Map<String, dynamic>>.from(_productos.map((p) => Map<String, dynamic>.from(p)));
  }

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    await _latenciaRed();
    return List<Map<String, dynamic>>.from(_clientesMayoristas.map((c) => Map<String, dynamic>.from(c)));
  }

  Future<List<Map<String, dynamic>>> obtenerVentasDelDia() async {
    await _latenciaRed();
    return List<Map<String, dynamic>>.from(_ventas);
  }

  Future<bool> agregarProducto(Map<String, dynamic> nuevoProducto) async {
    await _latenciaRed();
    if (_productos.any((p) => p['sku'] == nuevoProducto['sku'])) {
      return false; 
    }
    _productos.add(nuevoProducto);
    print("DB: Producto agregado con éxito (SKU: ${nuevoProducto['sku']})");
    return true;
  }

  Future<void> actualizarProducto(int skuOriginal, Map<String, dynamic> datosActualizados) async {
    await _latenciaRed();
    final index = _productos.indexWhere((p) => p['sku'] == skuOriginal);
    if (index != -1) {
      _productos[index] = datosActualizados;
      print("DB: Producto actualizado con éxito (SKU: $skuOriginal)");
    }
  }

  Future<void> eliminarProducto(int sku) async {
    await _latenciaRed();
    _productos.removeWhere((p) => p['sku'] == sku);
    print("DB: Producto eliminado con éxito (SKU: $sku)");
  }

  // ==========================================
  // MÉTODOS DE ESCRITURA (TRANSACCIONES)
  // ==========================================

  Future<void> registrarVenta({
    required Map<int, double> carrito, 
    required int total, 
    required String documento, 
    required String metodoPago,
    Map<String, dynamic>? cliente,
  }) async {
    await _latenciaRed();

    // 1. Descontar el stock de la tabla de productos
    for (var sku in carrito.keys) {
      final cantidadComprada = carrito[sku]!;
      final index = _productos.indexWhere((p) => p['sku'] == sku);
      
      // Permitimos que la venta proceda incluso en negativo para Panadería
      if (index != -1) {
        _productos[index]['stock'] -= cantidadComprada;
      }
    }

    // 2. Registrar la venta en el historial integrando el carrito
    _ventas.add({
      'hora': DateTime.now(),
      'documento': documento,
      'metodo': metodoPago,
      'total': total,
      'rutCliente': cliente?['rut'],
      'carrito': Map<int, double>.from(carrito),
    });

    print("DB: Venta $documento guardada y stock descontado.");
  }

  Future<void> registrarValeInterno(Map<int, double> carrito, String motivo) async {
    await _latenciaRed();

    // 1. Descontar el stock
    for (var sku in carrito.keys) {
      final cantidadMovida = carrito[sku]!;
      final index = _productos.indexWhere((p) => p['sku'] == sku);
      
      if (index != -1) {
        _productos[index]['stock'] -= cantidadMovida;
      }
    }

    // 2. Guardar el comprobante interno integrando el carrito
    _valesInternos.add({
      'hora': DateTime.now(),
      'motivo': motivo,
      'items': Map<int, double>.from(carrito),
    });

    print("DB: Vale interno guardado ($motivo) y stock descontado.");
  }
}