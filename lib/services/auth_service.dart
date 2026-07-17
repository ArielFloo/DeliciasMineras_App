import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sesion_usuario.dart';
import '../models/empleado.dart';

// ==========================================
// 1. SERVICIO DE AUTENTICACIÓN (FUSIONADO)
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
      // 1. INTENTO DE LOGIN LOCAL (Administrador Hardcodeado)
      final usuarioLocal = _usuariosDB.firstWhere(
        (u) => u.rut == rut && u.password == password,
      );
      
      currentUser = usuarioLocal; 
      
      // Iniciamos sesión local apuntando por defecto al local 1 para pruebas
      // Le pasamos un ID entero temporal (9999) para que no falle el tipo de dato en SesionUsuario
      SesionUsuario.instancia.iniciarSesion(
        empleadoId: 9999, 
        rutUsuario: usuarioLocal.rut,
        nombreUsuario: usuarioLocal.nombre,
        rolUsuario: usuarioLocal.rol,
        localId: 1, 
      );

      print("Login exitoso (Local): Bienvenido ${usuarioLocal.nombre}");
      return usuarioLocal;
      
    } catch (_) {
      // 2. LOGIN EN SUPABASE (Cajeros y Repartidores Reales)
      try {
        final response = await _supabase
            .schema('deliciasmineras')
            .from('empleado')
            .select('idempleado, nombreempleado, tipoempleado, rut, contrasena, idlocal')
            .eq('rut', rut)               
            .eq('contrasena', password)   
            .single();                    

        final String rol = response['tipoempleado'].toString().toLowerCase();
        
        final int localDeEmpleado = response['idlocal'] != null 
            ? (response['idlocal'] as num).toInt() 
            : 1;

        Empleado usuarioReal;

        if (rol == 'cajero') {
          usuarioReal = Cajero(
            id: response['idempleado'].toString(),
            rut: response['rut'], 
            nombre: response['nombreempleado'],
            password: response['contrasena'], 
            idLocal: localDeEmpleado, 
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
          return null; 
        }

        currentUser = usuarioReal;

        // Guardamos la sesión con el ID numérico real obtenido de Supabase
        SesionUsuario.instancia.iniciarSesion(
          empleadoId: response['idempleado'] as int, 
          rutUsuario: usuarioReal.rut,
          nombreUsuario: usuarioReal.nombre,
          rolUsuario: usuarioReal.rol,
          localId: localDeEmpleado,
        );

        print("Login exitoso (Supabase): Bienvenido ${usuarioReal.nombre}");
        return usuarioReal;

      } catch (e) {
        print("Login Supabase fallido: $e");
        return null;
      }
    }
  }

  void logout() {
    currentUser = null;
  }

}