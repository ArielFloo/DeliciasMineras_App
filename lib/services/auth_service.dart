// Archivo: lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. MODELOS DE USUARIO (Jerarquía Intacta)
// ==========================================
abstract class Empleado {
  final String id;
  final String rut;
  final String nombre;
  final String password;
  final String rol;
  
  String estado;
  String detalleEstado;
  bool activo;

  Empleado({
    required this.id,
    required this.rut,
    required this.nombre,
    required this.password,
    required this.rol,
    this.estado = 'Inactivo',
    this.detalleEstado = 'Sin turno asignado',
    this.activo = false,
  });
}

class Cajero extends Empleado {
  final int idLocal;

  Cajero({
    required super.id,
    required super.rut,
    required super.nombre,
    required super.password,
    super.rol = 'Cajero',
    required this.idLocal,
    super.estado,
    super.detalleEstado,
    super.activo,
  });
}

class Repartidor extends Empleado {
  final String patenteVehiculoAsignado;

  Repartidor({
    required super.id,
    required super.rut,
    required super.nombre,
    required super.password,
    super.rol = 'Repartidor',
    required this.patenteVehiculoAsignado,
    super.estado,
    super.detalleEstado,
    super.activo,
  });
}

class Administrador extends Empleado {
  final int nivelAcceso;

  Administrador({
    required super.id,
    required super.rut,
    required super.nombre,
    required super.password,
    super.rol = 'Administrador',
    required this.nivelAcceso,
    super.estado,
    super.detalleEstado,
    super.activo,
  });
}

// ==========================================
// 2. SERVICIO DE AUTENTICACIÓN (FUSIONADO)
// ==========================================

class AuthService {
  // Patrón Singleton
  static final AuthService _instancia = AuthService._interno();
  factory AuthService() => _instancia;
  AuthService._interno();

  // Cliente de Supabase inyectado de forma segura
  final _supabase = Supabase.instance.client;
  
  Empleado? currentUser;

  // --- BASE DE DATOS LOCAL (Fallback) ---
  final List<Empleado> _usuariosDB = [
    Administrador(
      id: 'EMP-003',
      rut: '33333333-3', // RUT para entrar como administrador
      nombre: 'Kurt Koserak Admin',
      password: '1234',
      nivelAcceso: 5,
      estado: 'Disponible',
      detalleEstado: 'Monitoreando la plataforma',
      activo: true,
    ),
  ];

  // ==========================================
  // PANEL ADMIN: Obtener empleados reales + locales
  // ==========================================
  Future<List<Empleado>> obtenerEmpleados() async {
    List<Empleado> listaFinal = List.from(_usuariosDB);

    try {
      // Traemos a los empleados reales de Supabase para que el Admin los vea
      final response = await _supabase.schema('deliciasmineras').from('empleado').select();
      
      for (var row in response) {
        final rol = row['tipoempleado'].toString().toLowerCase();
        final idStr = row['idempleado'].toString();
        
        // Creamos un RUT falso visual para que la interfaz no colapse (Ej: 10.121.954-K)
        final String rutSimulado = "${idStr.substring(0,2)}.${idStr.substring(2,5)}.${idStr.substring(5,7)}-K";

        if (rol == 'cajero') {
          listaFinal.add(Cajero(
            id: idStr,
            rut: rutSimulado,
            nombre: row['nombreempleado'],
            password: '***',
            idLocal: 1,
          ));
        } else if (rol == 'repartidor') {
          listaFinal.add(Repartidor(
            id: idStr,
            rut: rutSimulado,
            nombre: row['nombreempleado'],
            password: '***',
            patenteVehiculoAsignado: 'Sin asignar',
          ));
        }
      }
    } catch (e) {
      print("Error cargando empleados de Supabase para el panel: $e");
    }

    return listaFinal;
  }

  // ==========================================
  // LOGIN INTELIGENTE (Prioriza Mocks, luego Supabase)
  // ==========================================
  Future<Empleado?> login(String rut, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 1. INTENTO DE LOGIN LOCAL (Ideal para que Ana Admin siga entrando)
      final usuarioLocal = _usuariosDB.firstWhere(
        (u) => u.rut == rut && u.password == password,
      );
      
      currentUser = usuarioLocal; 
      print("Login exitoso (Local): Bienvenido ${usuarioLocal.nombre}");
      return usuarioLocal;
      
    } catch (_) {
      // 2. SI FALLA LOCAL, VAMOS A SUPABASE CON LAS COLUMNAS NUEVAS
      try {
        // Hacemos la consulta directa preguntando por RUT y CONTRASEÑA
        // Asegúrate de usar el schema 'deliciasmineras' tal como lo hiciste más arriba
        final response = await _supabase
            .schema('deliciasmineras') 
            .from('empleado')
            .select('idempleado, nombreempleado, tipoempleado, rut, contrasena')
            .eq('rut', rut)               // Filtramos por el RUT exacto
            .eq('contrasena', password)   // Filtramos por la contraseña ('1234')
            .single();                    // Esperamos 1 solo resultado

        // Si llega a esta línea, es porque encontró al empleado.
        final String rol = response['tipoempleado'].toString().toLowerCase();
        Empleado usuarioReal;

        // "Fabricamos" el objeto específico según el rol
        if (rol == 'cajero') {
          usuarioReal = Cajero(
            id: response['idempleado'].toString(),
            rut: response['rut'], 
            nombre: response['nombreempleado'],
            password: response['contrasena'], 
            idLocal: 1, 
            estado: 'Caja Abierta',
            detalleEstado: 'Operando desde Supabase',
            activo: true,
          );
        } else if (rol == 'repartidor') {
          usuarioReal = Repartidor(
            id: response['idempleado'].toString(),
            rut: response['rut'],
            nombre: response['nombreempleado'],
            password: response['contrasena'],
            patenteVehiculoAsignado: 'Sin asignar',
            estado: 'En Ruta',
            detalleEstado: 'Conectado a Supabase',
            activo: true,
          );
        } else {
          // Si por algún motivo tiene otro rol no mapeado
          return null; 
        }

        currentUser = usuarioReal;
        print("Login exitoso (Supabase): Bienvenido ${usuarioReal.nombre}");
        return usuarioReal;

      } catch (e) {
        // Si Supabase tira error (ej. .single() no encuentra nada), el login falla
        print("Login Supabase fallido (Credenciales incorrectas o error DB): $e");
        return null;
      }
    }
  }

  void logout() {
    currentUser = null;
  }

  Future<bool> registrarEmpleado(Empleado nuevoEmpleado) async {
    // Lo mantenemos operando localmente para no romper tus flujos actuales
    if (_usuariosDB.any((u) => u.rut == nuevoEmpleado.rut)) return false;
    _usuariosDB.add(nuevoEmpleado);
    return true; 
  }
}