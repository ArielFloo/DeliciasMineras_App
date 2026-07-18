import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sesion_usuario.dart';
import '../models/empleado.dart';

class AuthService {
  static final AuthService _instancia = AuthService._interno();
  factory AuthService() => _instancia;
  AuthService._interno();

  final _supabase = Supabase.instance.client;
  Empleado? currentUser;

  // En lugar de una lista, dejamos solo el objeto del Admin de pruebas
  final Administrador _adminMock = Administrador(
    id: 'EMP-003',
    rut: '33333333-3', 
    nombre: 'Kurt Koserak Admin',
    password: '1234',
    nivelAcceso: 5,
    estado: 'Disponible',
    detalleEstado: 'Monitoreando la plataforma',
    activo: true,
  );

  // ==========================================
  // LOGIN INTELIGENTE 
  // ==========================================
  Future<Empleado?> login(String rut, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 1. INTENTO DE LOGIN LOCAL: Validamos directo contra las credenciales del Admin Mock
      if (rut == _adminMock.rut && password == _adminMock.password) {
        currentUser = _adminMock; 
        
        SesionUsuario.instancia.iniciarSesion(
          empleadoId: 9999, 
          rutUsuario: _adminMock.rut,
          nombreUsuario: _adminMock.nombre,
          rolUsuario: _adminMock.rol,
          localId: 1, 
        );

        print("Login exitoso (Local): Bienvenido ${_adminMock.nombre}");
        return _adminMock;
      }
      
      // Si el RUT/Contraseña no coinciden con el admin, forzamos ir al catch para evaluar Supabase
      throw Exception("No es el usuario administrador");
      
    } catch (_) {
      // 2. LOGIN EN SUPABASE (Se mantiene exactamente igual)
      try {
        final response = await _supabase
            .schema('deliciasmineras')
            .from('empleado')
            .select('idempleado, nombreempleado, tipoempleado, rut, contrasena, idlocal')
            .eq('rut', rut)               
            .eq('contrasena', password)   
            .single();                    

        final String rol = response['tipoempleado'].toString().toLowerCase();
        final int localDeEmpleado = response['idlocal'] != null ? (response['idlocal'] as num).toInt() : 1;

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