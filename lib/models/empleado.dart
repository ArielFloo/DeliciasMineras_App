
abstract class Empleado {
  final String id;
  final String nombre;
  final String rut;
  final String tipo; // 'Cajero', 'Repartidor', 'Administrador'

  Empleado({required this.id, required this.nombre, required this.rut, required this.tipo});
}

class Cajero extends Empleado {
  final int idLocal; // El cajero está atado a un local específico

  Cajero({required super.id, required super.nombre, required super.rut, required super.tipo, required this.idLocal});
}

class Repartidor extends Empleado {
  final String patenteVehiculo;

  Repartidor({required super.id, required super.nombre, required super.rut, required super.tipo, required this.patenteVehiculo});
}

class Administrador extends Empleado {
  final int nivelAcceso; // Un admin puede tener acceso total

  Administrador({required super.id, required super.nombre, required super.rut, required super.tipo, required this.nivelAcceso});
}