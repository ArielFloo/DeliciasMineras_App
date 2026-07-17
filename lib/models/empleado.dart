// lib/models/empleado.dart

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