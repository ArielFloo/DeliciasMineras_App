// ==========================================
// 1. MODELOS DE USUARIO (Jerarquía)
// ==========================================
abstract class Empleado {
  final String id;
  final String rut;
  final String nombre;
  final String password;
  final String rol;
  
  // NUEVAS PROPIEDADES OPERATIVAS (Para el panel del Administrador)
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
// 2. SERVICIO DE AUTENTICACIÓN Y MOCK DB

class AuthService {
  // Patrón Singleton
  static final AuthService _instancia = AuthService._interno();
  factory AuthService() => _instancia;
  AuthService._interno();

  Empleado? currentUser;

  // --- BASE DE DATOS UNIFICADA DE EMPLEADOS ---
  final List<Empleado> _usuariosDB = [
    Cajero(
      id: 'EMP-001',
      rut: '21.936.615-9',
      nombre: 'Kurt Koserak',
      password: '123',
      idLocal: 1, // Local de Coronel
      estado: 'Caja Abierta',
      detalleEstado: 'Operando Caja Central desde las 08:30 AM',
      activo: true,
    ),
    Repartidor(
      id: 'EMP-002',
      rut: '22.222.222-2',
      nombre: 'Roberto Repartidor',
      password: '123',
      patenteVehiculoAsignado: 'AB-CD-12',
      estado: 'En Ruta',
      detalleEstado: 'Despachando Pedido #1024 - 3 entregas pendientes',
      activo: true,
    ),
    Administrador(
      id: 'EMP-003',
      rut: '33.333.333-3',
      nombre: 'Ana Admin',
      password: '123',
      nivelAcceso: 5,
      estado: 'Disponible',
      detalleEstado: 'Monitoreando la plataforma',
      activo: true,
    ),
    // Agregamos una cajera de tarde para hacer más rico el catálogo
    Cajero(
      id: 'EMP-004',
      rut: '19.234.567-8',
      nombre: 'María José Fuentes',
      password: '123',
      idLocal: 1,
      estado: 'Inactivo',
      detalleEstado: 'Turno de tarde (Inicia 14:00 PM)',
      activo: false,
    ),
  ];

  // NUEVO MÉTODO: Para que el panel de administración consulte los empleados reales
  Future<List<Empleado>> obtenerEmpleados() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_usuariosDB);
  }

  // Función de login, busca usuario en bd simulada
  Future<Empleado?> login(String rut, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final usuarioEncontrado = _usuariosDB.firstWhere(
        (u) => u.rut == rut && u.password == password,
      );
      
      currentUser = usuarioEncontrado; 
      return usuarioEncontrado;
    } catch (e) {
      return null;
    }
  }

  void logout() {
    currentUser = null;
  }

  // Registrar un empleado verificando que el RUT no exista
  Future<bool> registrarEmpleado(Empleado nuevoEmpleado) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Verificamos si el RUT ya está registrado
    if (_usuariosDB.any((u) => u.rut == nuevoEmpleado.rut)) {
      return false; // Retorna falso si hay choque de RUT
    }
    
    _usuariosDB.add(nuevoEmpleado);
    return true; // Éxito
  }
}