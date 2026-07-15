import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockDatabase { // Mantenemos el nombre MockDatabase para no romper tus imports en las otras pantallas
  static final MockDatabase instancia = MockDatabase._interno();
  MockDatabase._interno();

  // Cliente oficial de Supabase
  final _supabase = Supabase.instance.client;

  // ==========================================
  // MÉTODOS DE LECTURA (GETTERS A SUPABASE)
  // ==========================================
  
  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    try {
      // Dentro de obtenerProductos()
      final productosResponse = await _supabase.schema('deliciasmineras').from('producto').select();
      final stockResponse = await _supabase.schema('deliciasmineras').from('ofrece').select().eq('idlocal', 1);

      // Combinamos ambas tablas como si fuera un JOIN en SQL
      List<Map<String, dynamic>> catalogo = [];
      
      for (var prod in productosResponse) {
        // Buscamos el stock correspondiente a este SKU
        final stockData = stockResponse.firstWhere(
          (s) => s['sku'] == prod['sku'],
          orElse: () => {'stock': 0},
        );

        catalogo.add({
          'sku': prod['sku'],
          'nombre': prod['nombreproducto'],
          'precio': prod['precio'],
          'categoria': prod['categoria'],
          'stock': stockData['stock'],
        });
      }
      
      return catalogo;
    } catch (e) {
      print("Error leyendo productos de Supabase: $e");
      return []; // En caso de error (sin internet), devuelve lista vacía
    }
  }

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    try {
      // Hacemos un JOIN directo usando las herramientas de Supabase
      // Traemos clientes empresa
      // Dentro de obtenerClientes()
      final response = await _supabase
          .schema('deliciasmineras')
          .from('cliente')
          .select('rut, nombrecliente, tipocliente, empresa(razónsocial)');
          
      List<Map<String, dynamic>> clientes = [];
      for (var row in response) {
        if (row['tipocliente'] == 'empresa') {
           clientes.add({
             'rut': row['rut'],
             'nombre': row['nombrecliente'],
             // Si la relación trae el campo razónsocial, lo usamos, si no ponemos genérico
             'giro': row['empresa'] != null && row['empresa'].isNotEmpty ? row['empresa'][0]['razónsocial'] : 'Mayorista',
           });
        }
      }
      return clientes;
    } catch (e) {
      print("Error leyendo clientes de Supabase: $e");
      return [];
    }
  }

Future<List<Map<String, dynamic>>> obtenerVentasDelDia() async {
    try {
      final hoy = DateTime.now();
      
      // 1. EL JOIN MÁGICO: Agregamos "producto(precio)" a la consulta
      final response = await _supabase
          .schema('deliciasmineras')
          .from('compra')
          .select('idcompra, rutcliente, metodopago, boletacompra(sku, cantidad, diacompra, mescompra, anocompra, producto(precio))');
          
      List<Map<String, dynamic>> ventasEstructuradas = [];
      
      for (var venta in response) {
        final List boletas = venta['boletacompra'] as List;
        
        if (boletas.isEmpty) continue;
        
        int totalCalculado = 0; 
        Map<int, double> carrito = {};
        
        // 2. LA MATEMÁTICA: Calculamos el total por cada boleta
        for (var b in boletas) {
           int sku = b['sku'];
           double cant = (b['cantidad'] as num).toDouble();
           carrito[sku] = cant;

           // Rescatamos el precio que trajo el JOIN desde la tabla producto
           int precioProducto = 0;
           if (b['producto'] != null && b['producto']['precio'] != null) {
             precioProducto = (b['producto']['precio'] as num).toInt();
           }

           // Multiplicamos cantidad * precio y lo sumamos al total de la compra
           totalCalculado += (precioProducto * cant).toInt();
        }

        ventasEstructuradas.add({
          'hora': DateTime(boletas[0]['anocompra'], boletas[0]['mescompra'], boletas[0]['diacompra']), 
          'documento': venta['rutcliente'] != null ? 'Factura' : 'Boleta', 
          'metodo': venta['metodopago'],
          'total': totalCalculado, // 3. ¡ADIÓS AL CERO! Pasamos el total real
          'carrito': carrito,
          'id': venta['idcompra'],
        });
      }
      
      return ventasEstructuradas;
    } catch (e) {
      print("Error leyendo ventas de Supabase: $e");
      return [];
    }
  }

  // ==========================================
  // MÉTODOS DE ESCRITURA (TRANSACCIONES A SUPABASE)
  // ==========================================

  Future<void> registrarVenta({
    required Map<int, double> carrito, 
    required int total, 
    required String documento, 
    required String metodoPago,
    Map<String, dynamic>? cliente,
  }) async {
    try {
      // Generamos un ID de compra único o dejamos que PostgreSQL use un SERIAL si está configurado
      // En este ejemplo usamos un timestamp para asegurar un int único si la DB no auto-incrementa bien por defecto
      final int nuevoIdCompra = DateTime.now().millisecondsSinceEpoch % 10000000; 

      // 1. Registrar en tabla `compra`
      await _supabase.schema('deliciasmineras').from('compra').insert({
        'idcompra': nuevoIdCompra,
        'rutcliente': cliente?['rut'] ?? '71180745-9', // Usa un cliente por defecto
        'idcajero': 1012195, // Usa tu ID de cajero del dump
        'metodopago': metodoPago.toLowerCase(),
      });

      // 2. Registrar cada producto en `boletacompra`
      final ahora = DateTime.now();
      for (var sku in carrito.keys) {
        final cantidadComprada = carrito[sku]!;
        
        await _supabase.schema('deliciasmineras').from('boletacompra').insert({
          'idcompra': nuevoIdCompra,
          'sku': sku,
          'cantidad': cantidadComprada,
          'lugar': 1, // Local de Coronel
          'diacompra': ahora.day,
          'mescompra': ahora.month,
          'anocompra': ahora.year,
        });

        // 3. Descontar el stock en `ofrece` (¡Lógica Real!)
        // Obtenemos el stock actual
        final stockResult = await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .select('stock')
            .eq('idlocal', 1)
            .eq('sku', sku)
            .single();
            
        final int stockActual = stockResult['stock'] as int;
        
        // Actualizamos (PostgreSQL ejecutará el trigger de seguridad automáticamente)
        await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .update({'stock': stockActual - cantidadComprada.toInt()})
            .eq('idlocal', 1)
            .eq('sku', sku);
      }

      print("DB REAL: Venta guardada y stock descontado en Supabase.");
    } catch (e) {
      print("Error fatal guardando venta en Supabase: $e");
      rethrow;
    }
  }

  // Los métodos de Turnos (Local Storage) y Vales Internos los dejamos comentados o simulados
  // por ahora hasta que decidas si quieres hacerles una tabla en Supabase.
  
  // ==========================================
  // GESTIÓN DE CAJA (Sigue siendo RAM/Local por ahora)
  // ==========================================
  final List<Map<String, dynamic>> _turnos = [];

  Future<String> abrirTurno(String empleadoId) async {
    final String nuevoTurnoId = 'TRN-${DateTime.now().millisecondsSinceEpoch}';
    _turnos.add({
      'id': nuevoTurnoId,
      'empleadoId': empleadoId,
      'fecha_apertura': DateTime.now(),
      'fecha_cierre': null,
      'estado': 'ABIERTA',
      'carrito_guardado': <int, double>{},
    });
    return nuevoTurnoId;
  }

  Future<void> cerrarTurno(String turnoId) async {
    final index = _turnos.indexWhere((t) => t['id'] == turnoId);
    if (index != -1) {
      _turnos[index]['estado'] = 'CERRADA';
    }
  }

  Future<void> sincronizarCarrito(String turnoId, Map<int, double> carrito) async {
    final index = _turnos.indexWhere((t) => t['id'] == turnoId);
    if (index != -1) {
      _turnos[index]['carrito_guardado'] = Map<int, double>.from(carrito);
    }
  }

  // ==========================================
  // VALES INTERNOS (Mitad Local / Mitad Nube)
  // ==========================================
  final List<Map<String, dynamic>> _valesInternos = [];

  Future<void> registrarValeInterno(Map<int, double> carrito, String motivo) async {
    try {
      // 1. Descontar el stock real en Supabase
      for (var sku in carrito.keys) {
        final int cantidadMovida = carrito[sku]!.toInt();
        
        final stockResult = await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .select('stock')
            .eq('idlocal', 1)
            .eq('sku', sku)
            .single();
            
        final int stockActual = stockResult['stock'] as int;
        
        await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .update({'stock': stockActual - cantidadMovida})
            .eq('idlocal', 1)
            .eq('sku', sku);
      }

      // 2. Guardar el registro localmente (ya que no modelaron tabla para esto en BD)
      _valesInternos.add({
        'hora': DateTime.now(),
        'motivo': motivo,
        'items': Map<int, double>.from(carrito),
      });

      print("DB REAL: Vale interno procesado y stock actualizado.");
    } catch (e) {
      print("Error procesando vale interno: $e");
    }
  }

  // ==========================================
  // CRUD DE PRODUCTOS EN SUPABASE
  // ==========================================

  Future<bool> agregarProducto(Map<String, dynamic> nuevoProducto) async {
    try {
      // Validar si existe
      final existe = await _supabase.schema('deliciasmineras').from('producto').select('sku').eq('sku', nuevoProducto['sku']);
      if (existe.isNotEmpty) return false;

      // 1. Insertar en tabla producto
      await _supabase.schema('deliciasmineras').from('producto').insert({
        'sku': nuevoProducto['sku'],
        'nombreproducto': nuevoProducto['nombre'],
        'categoria': nuevoProducto['categoria'],
        'precio': nuevoProducto['precio']
      });

      // 2. Asignar stock en el local 1 (Coronel) usando la tabla ofrece
      await _supabase.schema('deliciasmineras').from('ofrece').insert({
        'idlocal': 1,
        'sku': nuevoProducto['sku'],
        'stock': nuevoProducto['stock'] ?? 0
      });

      return true;
    } catch (e) {
      print("Error agregando producto: $e");
      return false;
    }
  }

Future<void> actualizarProducto(int skuOriginal, Map<String, dynamic> datosActualizados) async {
    try {
      // 1. Preparamos SOLO los datos que pertenecen a la tabla 'producto' y que vienen en el mapa
      Map<String, dynamic> datosProducto = {};
      
      if (datosActualizados.containsKey('nombre')) {
        datosProducto['nombreproducto'] = datosActualizados['nombre'];
      }
      if (datosActualizados.containsKey('categoria')) {
        datosProducto['categoria'] = datosActualizados['categoria'];
      }
      if (datosActualizados.containsKey('precio')) {
        datosProducto['precio'] = datosActualizados['precio'];
      }

      // Solo tocamos la tabla producto si realmente hay algo que cambiarle
      if (datosProducto.isNotEmpty) {
        await _supabase
            .schema('deliciasmineras')
            .from('producto')
            .update(datosProducto)
            .eq('sku', skuOriginal);
      }

      // 2. Tocamos la tabla 'ofrece' de forma independiente si viene un cambio de stock
      if (datosActualizados.containsKey('stock')) {
        // 1. Forzamos a que el SKU sea un int para evitar rechazos de PostgreSQL
        int skuSeguro = int.parse(skuOriginal.toString());
        
        final respuesta = await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .update({'stock': datosActualizados['stock']})
            .eq('idlocal', 1)
            .eq('sku', skuSeguro)
            .select(); 
            
        if (respuesta.isEmpty) {
          print("🚨 ALERTA: No se encontró el SKU $skuSeguro en el Local 1.");
          print("👉 Revisa en el Table Editor de Supabase si este producto existe en la tabla 'ofrece'.");
        } else {
           print("✅ Stock modificado con éxito: $respuesta");
        }
      }
      
      print("¡Stock/Producto actualizado con éxito!");
      
    } catch (e) {
      print("Error actualizando producto: $e");
    }
  }

  Future<void> eliminarProducto(int sku) async {
    try {
      // Eliminar dependencias primero por llaves foráneas
      await _supabase.schema('deliciasmineras').from('ofrece').delete().eq('sku', sku);
      await _supabase.schema('deliciasmineras').from('producto').delete().eq('sku', sku);
    } catch (e) {
      print("Error eliminando producto: $e");
    }
  }

  // ==========================================
  // CRUD DE CLIENTES MAYORISTAS EN SUPABASE
  // ==========================================

  Future<bool> agregarCliente(Map<String, dynamic> nuevoCliente) async {
    try {
      final existe = await _supabase.schema('deliciasmineras').from('cliente').select('rut').eq('rut', nuevoCliente['rut']);
      if (existe.isNotEmpty) return false;

      // 1. Insertar en la tabla base cliente
      await _supabase.schema('deliciasmineras').from('cliente').insert({
        'rut': nuevoCliente['rut'],
        'nombrecliente': nuevoCliente['nombre'],
        'tipocliente': 'empresa'
      });

      // 2. Insertar en la tabla hija empresa
      await _supabase.schema('deliciasmineras').from('empresa').insert({
        'rut': nuevoCliente['rut'],
        'razónsocial': nuevoCliente['giro'], 
        'correocliente': 'contacto@empresas.com' // Dato genérico para no romper el insert
      });

      return true;
    } catch (e) {
      print("Error agregando cliente: $e");
      return false;
    }
  }

  Future<void> actualizarCliente(String rutOriginal, Map<String, dynamic> datosActualizados) async {
    try {
      await _supabase.schema('deliciasmineras').from('cliente').update({
        'nombrecliente': datosActualizados['nombre']
      }).eq('rut', rutOriginal);

      await _supabase.schema('deliciasmineras').from('empresa').update({
        'razónsocial': datosActualizados['giro']
      }).eq('rut', rutOriginal);
    } catch (e) {
      print("Error actualizando cliente: $e");
    }
  }

  Future<void> eliminarCliente(String rut) async {
    try {
      // Eliminar dependencias primero
      await _supabase.schema('deliciasmineras').from('empresa').delete().eq('rut', rut);
      await _supabase.schema('deliciasmineras').from('cliente').delete().eq('rut', rut);
    } catch (e) {
      print("Error eliminando cliente: $e");
    }
  }
}