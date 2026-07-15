import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabase {
  static final _supabase = Supabase.instance.client;

  // RECONSTRUIMOS: Obtener productos directo de la tabla de PostgreSQL en Supabase
  static Future<List<Map<String, dynamic>>> obtenerProductos() async {
    try {
      // Supabase traduce esta línea automáticamente a un SELECT * FROM deliciasmineras.producto
      final response = await _supabase
          .from('producto')
          .select();
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error al traer productos de Supabase: $e");
      return [];
    }
  }

  // RECONSTRUIMOS: Registrar una compra real en PostgreSQL
  static Future<void> registrarVenta({
    required Map<int, double> carrito,
    required int total,
    required String documento,
    required String metodoPago,
    required String? rutCliente,
  }) async {
    try {
      // 1. Insertar la compra principal
      final compraInsertada = await _supabase.from('compra').insert({
        'rutcliente': rutCliente ?? '71180745-9', // Usa un RUT por defecto del dump si es cliente genérico
        'idcajero': 1548860, // Tu ID de cajero del dump de pruebas
        'metodopago': metodoPago.toLowerCase(), // 'debito', 'credito' o 'efectivo'
      }).select().single();

      final int idCompra = compraInsertada['idcompra'];

      // 2. Insertar cada producto del carrito en la tabla intermedia boletacompra
      for (var entry in carrito.entries) {
        final DateTime ahora = DateTime.now();
        await _supabase.from('boletacompra').insert({
          'idcompra': idCompra,
          'sku': entry.key,
          'cantidad': entry.value,
          'lugar': 1, // Local de Coronel por defecto
          'diacompra': ahora.day,
          'mescompra': ahora.month,
          'anocompra': ahora.year,
        });
      }
    } catch (e) {
      print("Error al registrar compra en Supabase: $e");
      rethrow;
    }
  }
}