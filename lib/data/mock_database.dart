import 'dart:async';

class MockDatabase {
  static final MockDatabase instancia = MockDatabase._interno();
  MockDatabase._interno();

  // ==========================================
  // TABLAS EN MEMORIA (El estado global)
  // ==========================================
  final List<Map<String, dynamic>> _productos = [
    {'sku': 1, 'nombre': 'Pan de Molde Integral', 'precio': 2500, 'stock': 2, 'categoria': 'Panadería'},
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

  final List<Map<String, dynamic>> _ventas = [];
  final List<Map<String, dynamic>> _valesInternos = [];

  // Simulador de latencia de red (Medio segundo)
  Future<void> _latenciaRed() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ==========================================
  // MÉTODOS DE LECTURA (GETTERS ASÍNCRONOS)
  // ==========================================
  
  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    await _latenciaRed();
    // Devolvemos una copia profunda de la lista para evitar mutaciones directas
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

  // ==========================================
  // MÉTODOS DE ESCRITURA (TRANSACCIONES)
  // ==========================================

  /// Registra una venta oficial, descuenta el stock y guarda el registro
  Future<void> registrarVenta({
    required Map<int, int> carrito, 
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
      
      if (index != -1 && _productos[index]['stock'] >= cantidadComprada) {
        _productos[index]['stock'] -= cantidadComprada;
      }
    }

    // 2. Registrar la venta en el historial
    _ventas.add({
      'hora': DateTime.now(),
      'documento': documento,
      'metodo': metodoPago,
      'total': total,
      'rutCliente': cliente?['rut'],
    });

    print("DB: Venta $documento guardada y stock descontado.");
  }

  /// Registra un movimiento sin valor fiscal (merma, fiado) y descuenta stock
  Future<void> registrarValeInterno(Map<int, int> carrito, String motivo) async {
    await _latenciaRed();

    // 1. Descontar el stock
    for (var sku in carrito.keys) {
      final cantidadMovida = carrito[sku]!;
      final index = _productos.indexWhere((p) => p['sku'] == sku);
      
      if (index != -1 && _productos[index]['stock'] >= cantidadMovida) {
        _productos[index]['stock'] -= cantidadMovida;
      }
    }

    // 2. Guardar el comprobante interno
    _valesInternos.add({
      'hora': DateTime.now(),
      'motivo': motivo,
      'items': Map<int, int>.from(carrito),
    });

    print("DB: Vale interno guardado ($motivo) y stock descontado.");
  }
}