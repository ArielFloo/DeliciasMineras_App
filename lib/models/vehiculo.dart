class Vehiculo {
  final String patente;
  final bool estaDisponible;
  final TipoVehiculo tipo;

  Vehiculo({
    required this.patente,
    required this.estaDisponible,
    required this.tipo,
  });

  // Mapeo desde el JSON
  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      patente: json['patente'] as String,
      estaDisponible: json['esta_disponible'] as bool,
      // Nota: Si el JSON trae el enum como String, deberías mapearlo.
      // Aquí asumo que ya viene como el tipo de dato correcto o lo manejas externamente.
      tipo: json['tipo'] is String
          ? TipoVehiculo.values.byName(json['tipo'])
          : json['tipo'] as TipoVehiculo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patente': patente,
      'esta_disponible': estaDisponible,
      'tipo': tipo.name, // Es mejor guardar el nombre del enum en el JSON
    };
  }
}

enum TipoVehiculo {
  particular,
  empresarial,
}