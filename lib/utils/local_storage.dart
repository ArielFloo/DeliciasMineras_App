import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyTurno = 'turno_activo';
  static const String _keyCarrito = 'carrito_activo';
  static const String _keyHora = 'hora_inicio';
  // Nuevas llaves para guardar al Cajero
  static const String _keyCajeroId = 'cajero_id';
  static const String _keyCajeroNombre = 'cajero_nombre';
  static const String _keyCajeroRut = 'cajero_rut';
  static const String _keyIdLocal = 'id_local';

  // Guardar datos de sesión de caja
  static Future<void> guardarSesionCaja({
    required String turnoId,
    required DateTime horaInicio,
    required Map<int, double> carrito,
    // Agregamos los parámetros obligatorios del Cajero
    required String cajeroId,
    required String cajeroNombre,
    required String cajeroRut,
    required int idLocal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTurno, turnoId);
    await prefs.setString(_keyHora, horaInicio.toIso8601String());
    
    // Guardamos físicamente los datos del cajero
    await prefs.setString(_keyCajeroId, cajeroId);
    await prefs.setString(_keyCajeroNombre, cajeroNombre);
    await prefs.setString(_keyCajeroRut, cajeroRut);
    await prefs.setInt(_keyIdLocal, idLocal);
    
    // Convertimos el mapa de carrito <int, double> a un JSON string
    final Map<String, double> carritoStringKeys = carrito.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    await prefs.setString(_keyCarrito, jsonEncode(carritoStringKeys));
  }

  // Leer la sesión si existe
  static Future<Map<String, dynamic>?> obtenerSesionCaja() async {
    final prefs = await SharedPreferences.getInstance();
    final String? turnoId = prefs.getString(_keyTurno);
    final String? horaStr = prefs.getString(_keyHora);
    final String? carritoJson = prefs.getString(_keyCarrito);

    if (turnoId == null || horaStr == null) return null;

    Map<int, double> carrito = {};
    if (carritoJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(carritoJson);
      carrito = decoded.map(
        (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
      );
    }

    // Retornamos también los datos del cajero (o nulos si por alguna razón no existían)
    return {
      'turnoId': turnoId,
      'horaInicio': DateTime.parse(horaStr),
      'carrito': carrito,
      'cajeroId': prefs.getString(_keyCajeroId),
      'cajeroNombre': prefs.getString(_keyCajeroNombre),
      'cajeroRut': prefs.getString(_keyCajeroRut),
      'idLocal': prefs.getInt(_keyIdLocal),
    };
  }

  // Limpiar todo al cerrar caja definitivamente
  static Future<void> borrarSesionCaja() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTurno);
    await prefs.remove(_keyHora);
    await prefs.remove(_keyCarrito);
    
    // Limpiamos también la data del empleado
    await prefs.remove(_keyCajeroId);
    await prefs.remove(_keyCajeroNombre);
    await prefs.remove(_keyCajeroRut);
    await prefs.remove(_keyIdLocal);
  }
}