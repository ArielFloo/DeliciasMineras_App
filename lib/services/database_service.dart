// ignore_for_file: unnecessary_cast

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sesion_usuario.dart';
import '../models/empleado.dart';

class DatabaseService {
  static final DatabaseService instancia = DatabaseService._interno();
  DatabaseService._interno();

  // Cliente oficial de Supabase
  final _supabase = Supabase.instance.client;

  // Constante para el RUT genérico de boletas sin nominación (Reemplázalo por el RUT "comodín" real de tu BD)
  final String rutGenericoBoleta = '11111111-1';

  // ==========================================
  // MÉTODOS DE LECTURA (GETTERS A SUPABASE)
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    try {
      final productosResponse = await _supabase
          .schema('deliciasmineras')
          .from('producto')
          .select();

      // Capturamos el local de la sesión activa
      final int localActual = SesionUsuario.instancia.idLocal ?? 1;

      // Filtramos dinámicamente por la sucursal del usuario
      final stockResponse = await _supabase
          .schema('deliciasmineras')
          .from('ofrece')
          .select()
          .eq('idlocal', localActual);

      List<Map<String, dynamic>> catalogo = [];

      for (var prod in productosResponse) {
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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    try {
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
            'giro': row['empresa'] != null && row['empresa'].isNotEmpty
                ? row['empresa'][0]['razónsocial']
                : 'Mayorista',
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
      final response = await _supabase
          .schema('deliciasmineras')
          .from('compra')
          .select(
            'idcompra, rutcliente, metodopago, boletacompra(sku, cantidad, diacompra, mescompra, anocompra, producto(precio))',
          );

      List<Map<String, dynamic>> ventasEstructuradas = [];

      for (var venta in response) {
        final List boletas = venta['boletacompra'] as List;
        if (boletas.isEmpty) continue;

        int totalCalculado = 0;
        Map<int, double> carrito = {};

        for (var b in boletas) {
          int sku = b['sku'];
          double cant = (b['cantidad'] as num).toDouble();
          carrito[sku] = cant;

          int precioProducto = 0;
          if (b['producto'] != null && b['producto']['precio'] != null) {
            precioProducto = (b['producto']['precio'] as num).toInt();
          }
          totalCalculado += (precioProducto * cant).toInt();
        }

        // LÓGICA DE DETECCIÓN DE DOCUMENTO:
        // Si el RUT no es el genérico de boleta (y no es nulo), entonces es Factura.
        bool esFactura =
            (venta['rutcliente'] != null &&
            venta['rutcliente'] != rutGenericoBoleta);

        ventasEstructuradas.add({
          'hora': DateTime(
            boletas[0]['anocompra'],
            boletas[0]['mescompra'],
            boletas[0]['diacompra'],
          ),
          'documento': esFactura ? 'Factura' : 'Boleta',
          'metodo': venta['metodopago'],
          'total': totalCalculado,
          'carrito': carrito,
          'id': venta['idcompra'],
          'rutCliente': venta['rutcliente'],
        });
      }

      return ventasEstructuradas;
    } catch (e) {
      print("Error leyendo ventas de Supabase: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> obtenerEnviosRepartidor() async {
    try {
      final int idRepartidor = SesionUsuario.instancia.idEmpleado ?? 0;

      if (idRepartidor == 0) {
        throw Exception(
          "No hay un ID de repartidor válido en la sesión activa.",
        );
      }

      final response = await _supabase
          .schema('deliciasmineras')
          .from('envio')
          .select(
            'idenvio, rutcliente, horaestimada, direccionenvio, precioenvio, cliente(nombrecliente, empresa(razónsocial))',
          )
          .eq('idrepartidor', idRepartidor)
          .eq('entregado', 0); // Solo recupera pendientes

      return List<Map<String, dynamic>>.from(
        response.map((row) {
          // Extraemos razón social si es empresa, si no usamos el nombre del cliente
          final clienteData = row['cliente'];
          final empresaList = clienteData?['empresa'] as List?;
          final razonSocial = (empresaList != null && empresaList.isNotEmpty)
              ? empresaList[0]['razónsocial']
              : clienteData?['nombrecliente'] ?? 'Cliente';

          final int precio = (row['precioenvio'] as num).toInt();

          return {
            'idEnvio': row['idenvio'] ?? 0,
            'razonSocial': razonSocial,
            'rutCliente': row['rutcliente'],
            'direccionEntrega': row['direccionenvio'],
            'horaEstimada': row['horaestimada'],
            'precioFormateado':
                '\$${precio.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
          };
        }),
      );
    } catch (e) {
      print("Error cargando envíos del repartidor: $e");
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
      // 1. Lógica Pragmática de Documentos (Blindada a prueba de nulos)
      String rutAInsertar;

      if (documento == 'Factura') {
        if (cliente != null &&
            cliente['rut'] != null &&
            cliente['rut'].toString().trim().isNotEmpty) {
          rutAInsertar = cliente['rut']; // Usamos el RUT real y validado
        } else {
          throw Exception(
            "Error: Se requiere un Cliente Mayorista válido para emitir Factura.",
          );
        }
      } else {
        // Es Boleta. Mandamos al Consumidor Final de forma directa y limpia
        rutAInsertar = rutGenericoBoleta;
      }

      // 2. Extracción dinámica del Cajero y Local desde la sesión REAL
      final int idCajeroActual = SesionUsuario.instancia.idEmpleado ?? 0;
      final int localDelCajero = SesionUsuario.instancia.idLocal ?? 1;

      if (idCajeroActual == 0) {
        throw Exception(
          "Error: No hay un ID de cajero válido en la sesión activa.",
        );
      }

      // 3. Registrar en tabla `compra` DEJANDO QUE POSTGRESQL GENERE EL ID
      // Usamos .select('idcompra').single() para que la BD nos devuelva el ID recién creado
      final respuestaCompra = await _supabase
          .schema('deliciasmineras')
          .from('compra')
          .insert({
            'rutcliente': rutAInsertar,
            'idcajero': idCajeroActual,
            'metodopago': metodoPago.toLowerCase(),
          })
          .select('idcompra')
          .single();

      // Extraemos el ID oficial real y auto-incremental generado por Supabase
      final int nuevoIdCompra = respuestaCompra['idcompra'] as int;

      // 4. Registrar cada producto en `boletacompra`
      final ahora = DateTime.now();
      for (var sku in carrito.keys) {
        final cantidadComprada = carrito[sku]!;

        await _supabase.schema('deliciasmineras').from('boletacompra').insert({
          'idcompra':
              nuevoIdCompra, // Usamos el ID oficial que nos devolvió la tabla compra
          'sku': sku,
          'cantidad': cantidadComprada,
          'lugar': localDelCajero
              .toString(), // Convertido a String por si acaso
          'diacompra': ahora.day,
          'mescompra': ahora.month,
          'anocompra': ahora.year,
        });

        // 5. Descontar el stock en `ofrece`
        final stockResultList = await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .select('stock')
            .eq('idlocal', localDelCajero)
            .eq('sku', sku)
            .limit(1);

        if (stockResultList.isNotEmpty) {
          final int stockActual = stockResultList[0]['stock'] as int;

          await _supabase
              .schema('deliciasmineras')
              .from('ofrece')
              .update({'stock': stockActual - cantidadComprada.toInt()})
              .eq('idlocal', localDelCajero)
              .eq('sku', sku);
        } else {
          print(
            'ADVERTENCIA: No se encontró stock para el SKU $sku en el local $localDelCajero para descontar.',
          );
        }
      }

      print("DB REAL: Venta guardada y stock descontado en Supabase.");
    } catch (e) {
      print("Error fatal guardando venta en Supabase: $e");
      rethrow;
    }
  }

  // ==========================================
  // GESTIÓN DE CAJA (Local)
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

  Future<void> sincronizarCarrito(
    String turnoId,
    Map<int, double> carrito,
  ) async {
    final index = _turnos.indexWhere((t) => t['id'] == turnoId);
    if (index != -1) {
      _turnos[index]['carrito_guardado'] = Map<int, double>.from(carrito);
    }
  }

  // ==========================================
  // VALES INTERNOS (Mitad Local / Mitad Nube)
  // ==========================================
  final List<Map<String, dynamic>> _valesInternos = [];

  Future<void> registrarValeInterno(
    Map<int, double> carrito,
    String motivo,
  ) async {
    try {
      final int localDelCajero = SesionUsuario.instancia.idLocal ?? 1;

      for (var sku in carrito.keys) {
        final int cantidadMovida = carrito[sku]!.toInt();

        final stockResultList = await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .select('stock')
            .eq('idlocal', localDelCajero)
            .eq('sku', sku)
            .limit(1);

        if (stockResultList.isNotEmpty) {
          final int stockActual = stockResultList[0]['stock'] as int;

          await _supabase
              .schema('deliciasmineras')
              .from('ofrece')
              .update({'stock': stockActual - cantidadMovida})
              .eq('idlocal', localDelCajero)
              .eq('sku', sku);
        }
      }

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
      final existe = await _supabase
          .schema('deliciasmineras')
          .from('producto')
          .select('sku')
          .eq('sku', nuevoProducto['sku']);
      if (existe.isNotEmpty) return false;

      await _supabase.schema('deliciasmineras').from('producto').insert({
        'sku': nuevoProducto['sku'],
        'nombreproducto': nuevoProducto['nombre'],
        'categoria': nuevoProducto['categoria'],
        'precio': nuevoProducto['precio'],
      });

      final int localActual = SesionUsuario.instancia.idLocal ?? 1;

      await _supabase.schema('deliciasmineras').from('ofrece').insert({
        'idlocal': localActual, // <-- DINÁMICO
        'sku': nuevoProducto['sku'],
        'stock': nuevoProducto['stock'] ?? 0,
      });

      return true;
    } catch (e) {
      print("Error agregando producto: $e");
      return false;
    }
  }

  Future<void> actualizarProducto(
    int skuOriginal,
    Map<String, dynamic> datosActualizados,
  ) async {
    try {
      final int localActual = SesionUsuario.instancia.idLocal ?? 1;

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

      if (datosProducto.isNotEmpty) {
        await _supabase
            .schema('deliciasmineras')
            .from('producto')
            .update(datosProducto)
            .eq('sku', skuOriginal);
      }

      if (datosActualizados.containsKey('stock')) {
        int skuSeguro = int.parse(skuOriginal.toString());

        final respuesta = await _supabase
            .schema('deliciasmineras')
            .from('ofrece')
            .update({'stock': datosActualizados['stock']})
            .eq('idlocal', localActual)
            .eq('sku', skuSeguro)
            .select();

        if (respuesta.isEmpty) {
          print(
            "🚨 ALERTA: No se encontró el SKU $skuSeguro en tu local actual ($localActual).",
          );
        } else {
          print(
            "✅ Stock modificado con éxito para local $localActual: $respuesta",
          );
        }
      }
    } catch (e) {
      print("Error actualizando producto: $e");
    }
  }

  Future<void> eliminarProducto(int sku) async {
    try {
      await _supabase
          .schema('deliciasmineras')
          .from('ofrece')
          .delete()
          .eq('sku', sku);
      await _supabase
          .schema('deliciasmineras')
          .from('producto')
          .delete()
          .eq('sku', sku);
    } catch (e) {
      print("Error eliminando producto: $e");
    }
  }

  // ==========================================
  // CRUD DE CLIENTES MAYORISTAS EN SUPABASE
  // ==========================================

  Future<bool> agregarCliente(Map<String, dynamic> nuevoCliente) async {
    try {
      final existe = await _supabase
          .schema('deliciasmineras')
          .from('cliente')
          .select('rut')
          .eq('rut', nuevoCliente['rut']);
      if (existe.isNotEmpty) return false;

      await _supabase.schema('deliciasmineras').from('cliente').insert({
        'rut': nuevoCliente['rut'],
        'nombrecliente': nuevoCliente['nombre'],
        'tipocliente': 'empresa',
      });

      await _supabase.schema('deliciasmineras').from('empresa').insert({
        'rut': nuevoCliente['rut'],
        'razónsocial': nuevoCliente['giro'],
        'correocliente': 'contacto@empresas.com',
      });

      return true;
    } catch (e) {
      print("Error agregando cliente: $e");
      return false;
    }
  }

  Future<void> actualizarCliente(
    String rutOriginal,
    Map<String, dynamic> datosActualizados,
  ) async {
    try {
      await _supabase
          .schema('deliciasmineras')
          .from('cliente')
          .update({'nombrecliente': datosActualizados['nombre']})
          .eq('rut', rutOriginal);

      await _supabase
          .schema('deliciasmineras')
          .from('empresa')
          .update({'razónsocial': datosActualizados['giro']})
          .eq('rut', rutOriginal);
    } catch (e) {
      print("Error actualizando cliente: $e");
    }
  }

  Future<void> eliminarCliente(String rut) async {
    try {
      await _supabase
          .schema('deliciasmineras')
          .from('empresa')
          .delete()
          .eq('rut', rut);
      await _supabase
          .schema('deliciasmineras')
          .from('cliente')
          .delete()
          .eq('rut', rut);
    } catch (e) {
      print("Error eliminando cliente: $e");
    }
  }

  // ==========================================
  // GESTIÓN DE PERSONAL (Inserción Relacional Real)
  // ==========================================
  // ==========================================
  // PANEL ADMIN: Obtener empleados reales + locales
  // ==========================================
  // ==========================================
  // OBTENER EMPLEADOS (Panel de Administración)
  // ==========================================
  Future<List<Empleado>> obtenerEmpleados() async {
    // 1. Iniciamos con una lista completamente vacía
    List<Empleado> listaFinal = [];

    try {
      final response = await _supabase
          .schema('deliciasmineras')
          .from('empleado')
          .select();

      for (var row in response) {
        final rol = row['tipoempleado'].toString().toLowerCase();
        final idStr = row['idempleado'].toString();

        if (rol == 'cajero') {
          listaFinal.add(
            Cajero(
              id: idStr,
              rut: row['rut'], // <-- Lee el RUT real
              nombre: row['nombreempleado'],
              password: row['contrasena'], // <-- Lee la contraseña real
              idLocal: row['idlocal'] != null
                  ? (row['idlocal'] as num).toInt()
                  : 1,
              estado: 'Disponible',
              detalleEstado: 'Operando desde Supabase',
              activo: true,
            ),
          );
        } else if (rol == 'repartidor') {
          listaFinal.add(
            Repartidor(
              id: idStr,
              rut: row['rut'], // <-- Lee el RUT real
              nombre: row['nombreempleado'],
              password: row['contrasena'], // <-- Lee la contraseña real
              patenteVehiculoAsignado:
                  'Sin asignar', // O trae la patente si cruzas tablas
              estado: 'En Ruta',
              detalleEstado: 'Conectado a Supabase',
              activo: true,
            ),
          );
        } else if (rol == 'administrador' || rol == 'admin') {
          // Opcional: Si tienes administradores en la BD, también los cargamos
          listaFinal.add(
            Administrador(
              id: idStr,
              rut: row['rut'],
              nombre: row['nombreempleado'],
              password: row['contrasena'],
              nivelAcceso: 5,
              estado: 'Disponible',
              detalleEstado: 'Monitoreando la plataforma',
              activo: true,
            ),
          );
        }
      }
    } catch (e) {
      print("Error cargando empleados de Supabase para el panel: $e");
    }

    return listaFinal;
  }

  Future<bool> registrarNuevoEmpleado(Empleado nuevoEmpleado) async {
    try {
      // 1. Verificar si el RUT ya existe en Supabase para evitar colisiones
      final existe = await _supabase
          .schema('deliciasmineras')
          .from('empleado')
          .select('rut')
          .eq('rut', nuevoEmpleado.rut)
          .maybeSingle();

      if (existe != null) return false; // RUT ya registrado

      // Procesamos el nombre para generar un correo corporativo limpio (ej: benjamin.lopez@deliciasmineras.cl)
      List<String> partesNombre = nuevoEmpleado.nombre
          .trim()
          .toLowerCase()
          .split(' ');
      String nombreParaCorreo = partesNombre.isNotEmpty
          ? partesNombre.first
          : 'empleado';
      String apellidoParaCorreo = partesNombre.length > 1
          ? partesNombre[1]
          : '';

      String correoCorporativo = apellidoParaCorreo.isNotEmpty
          ? '$nombreParaCorreo.$apellidoParaCorreo@deliciasmineras.cl'
          : '$nombreParaCorreo@deliciasmineras.cl';

      // 2. Mapear los datos comunes para la tabla padre
      // ¡Declaramos explícitamente <String, dynamic> para que acepte el INT del local!
      final Map<String, dynamic> datosEmpleado = {
        'rut': nuevoEmpleado.rut,
        'nombreempleado': nuevoEmpleado.nombre,
        'tipoempleado': nuevoEmpleado.rol.toLowerCase(),
        'contrasena': nuevoEmpleado.password,
        'correoempleado': correoCorporativo,
      };

      // Ahora sí podemos pasarle el INT limpiamente sin casteos raros
      if (nuevoEmpleado is Cajero) {
        datosEmpleado['idlocal'] = nuevoEmpleado.idLocal;
      }

      // 3. Insertar en tabla 'empleado' y recuperar el SERIAL autogenerado
      final respuesta = await _supabase
          .schema('deliciasmineras')
          .from('empleado')
          .insert(datosEmpleado)
          .select('idempleado')
          .single();

      final int idGenerado = respuesta['idempleado'] as int;

      // 4. Mantener la integridad referencial insertando en la tabla hija con TODOS sus atributos
      if (nuevoEmpleado is Cajero) {
        await _supabase.schema('deliciasmineras').from('cajero').insert({
          'idempleado': idGenerado,
        });
      } else if (nuevoEmpleado is Repartidor) {
        await _supabase.schema('deliciasmineras').from('repartidor').insert({
          'idempleado': idGenerado,
          // Asumo que tu columna en BD se llama patentevehiculo, ajusta si es necesario
          'patentevehiculo': nuevoEmpleado.patenteVehiculoAsignado,
        });
      } else if (nuevoEmpleado is Administrador) {
        await _supabase.schema('deliciasmineras').from('administrador').insert({
          'idempleado': idGenerado,
          // Asumo que tu columna en BD se llama nivelacceso, ajusta si es necesario
          'nivelacceso': nuevoEmpleado.nivelAcceso,
        });
      }

      print(
        "DB REAL: Registro exitoso en PostgreSQL para ${nuevoEmpleado.nombre} (ID: $idGenerado).",
      );
      return true;
    } catch (e) {
      print("Error ejecutando transacciones de personal en Supabase: $e");
      return false;
    }
  }

  Future<bool> actualizarEmpleado(Empleado emp) async {
    try {
      await _supabase
          .schema('deliciasmineras')
          .from('empleado')
          .update({
            'nombreempleado': emp.nombre,
            'rut': emp.rut,
            'contrasena': emp.password,
          })
          .eq('idempleado', int.parse(emp.id));

      // 2. Si es Cajero, actualizamos sucursal en la tabla hija
      if (emp is Cajero) {
        await _supabase
            .from('cajero')
            .update({'idlocal': emp.idLocal})
            .eq('idempleado', emp.id);
      }
      // 3. Si es Repartidor, actualizamos patente en su tabla hija
      else if (emp is Repartidor) {
        await _supabase
            .from('repartidor')
            .update({'patente_vehiculo': emp.patenteVehiculoAsignado})
            .eq('idempleado', emp.id);
      }

      return true;
    } catch (e) {
      print("Error actualizando datos: $e");
      return false;
    }
  }

  // ==========================================
  // OBTENER LOCALES DISPONIBLES
  // ==========================================
  Future<List<Map<String, dynamic>>> obtenerLocales() async {
    try {
      final response = await _supabase
          .schema('deliciasmineras')
          .from('local')
          .select('idlocal, callelocal, numerolocal, ciudadlocal')
          .order('idlocal');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error leyendo locales de Supabase: $e");
      return [];
    }
  }

  // ==========================================
  // MARCAR ENVIO COMO COMPLETADO
  // ==========================================

  Future<void> marcarEnvioEntregado(int idEnvio) async {
    try {
      await _supabase
          .schema('deliciasmineras')
          .from('envio')
          .update({'entregado': 1})
          .eq('idenvio', idEnvio);

      print("Envío #$idEnvio marcado como entregado.");
    } catch (e) {
      print("Error marcando envío como entregado: $e");
      rethrow;
    }
  }
}
