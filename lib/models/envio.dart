class EnvioAsignado {
  final int idEnvio;
  final String razonSocial;
  final String direccionEntrega;
  final String horaEstimada;
  final int precioDespacho;
  final String patenteVehiculo;

  const EnvioAsignado({
    required this.idEnvio,
    required this.razonSocial,
    required this.direccionEntrega,
    required this.horaEstimada,
    required this.precioDespacho,
    required this.patenteVehiculo,
  });

  // TODO: Cuando conectemos Supabase, solo decomentaremos el siguiente factory:
  /*
  factory EnvioAsignado.fromJson(Map<String, dynamic> json) {
    return EnvioAsignado(
      idEnvio: json['id_envio'],
      razonSocial: json['razon_social'],
      direccionEntrega: json['direccionenvio'],
      horaEstimada: json['horaestimada'],
      precioDespacho: json['precioenvio'],
      patenteVehiculo: json['patente'],
    );
  }
  */
}