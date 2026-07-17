class SesionUsuario {
  static final SesionUsuario instancia = SesionUsuario._interno();
  SesionUsuario._interno();

  int? idEmpleado;
  String? rut;
  String? nombre;
  String? rol;
  int? idLocal; // 1 para Coronel, 2 para San Pedro, etc.

  void iniciarSesion({
    required empleadoId,
    required String rutUsuario,
    required String nombreUsuario,
    required String rolUsuario,
    required int localId,
  }) {
    idEmpleado = empleadoId;
    rut = rutUsuario;
    nombre = nombreUsuario;
    rol = rolUsuario;
    idLocal = localId;
    print("🔑 Sesión global activa: $nombre ($rol) -> Operando en Local ID: $idLocal");
  }

  void cerrarSesion() {
    idEmpleado = null;
    rut = null;
    nombre = null;
    rol = null;
    idLocal = null;
    print("🔒 Sesión global cerrada.");
  }

  bool get tieneSesion => rut != null;
}