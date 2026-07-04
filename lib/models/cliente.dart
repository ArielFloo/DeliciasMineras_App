class Cliente {
  final String rut;
  final String nombre;
  final String tipo; // 'Persona' o 'Empresa'

  Cliente({
    required this.rut,
    required this.nombre,
    required this.tipo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      rut: json['rut'] as String,
      nombre: json['nombre_cliente'] as String,
      tipo: json['tipo_cliente'] as String,
    );
  }
}