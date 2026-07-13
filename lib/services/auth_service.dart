// ==========================================
// 1. MODELOS DE USUARIO (Jerarquía)
// ==========================================
abstract class Empleado {
  final String id;
  final String rut;
  final String nombre;
  final String password;
  final String rol;

  Empleado({
    required this.id,
    required this.rut,
    required this.nombre,
    required this.password,
    required this.rol,
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
  });
}

// ==========================================
// 2. SERVICIO DE AUTENTICACIÓN Y MOCK DB

class AuthService {
  // Patrón Singleton
  static final AuthService _instancia = AuthService._interno();
  factory AuthService() => _instancia;
  AuthService._interno();

  // El usuario que está actualmente usando la app
  Empleado? currentUser;

  // --- MOCK DATABASE ---
  final List<Empleado> _usuariosDB = [
    Cajero(
      id: 'EMP-001',
      rut: '21.936.615-9',
      nombre: 'Kurt Koserak',
      password: '123',
      idLocal: 1, // Local de Coronel
    ),
    Repartidor(
      id: 'EMP-002',
      rut: '22.222.222-2',
      nombre: 'Roberto Repartidor',
      password: '123',
      patenteVehiculoAsignado: 'AB-CD-12',
    ),
    Administrador(
      id: 'EMP-003',
      rut: '33.333.333-3',
      nombre: 'Ana Admin',
      password: '123',
      nivelAcceso: 5,
    ),
  ];
//Funcion de login, busca usuario en bd simulada
Future<Empleado?> login(String rut, String password) async {
  await Future.delayed(const Duration(milliseconds: 800));

  try {
    // Fíjate que aquí también quitamos la validación del rol
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
}