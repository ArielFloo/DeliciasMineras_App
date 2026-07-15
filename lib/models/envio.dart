/// Resultado de la consulta que cruza:
/// Repartidor -> Conduce -> Vehiculo -> Despacha -> Envio -> Boleta_envio -> Recibe -> Cliente
/// (ver SQL de referencia al final de este archivo).
class EnvioAsignado {
  final int idEnvio;
  final String nombreCliente;
  final String direccionEntrega;
  final String horaEstimada;
  final int precioDespacho;

  const EnvioAsignado({
    required this.idEnvio,
    required this.nombreCliente,
    required this.direccionEntrega,
    required this.horaEstimada,
    required this.precioDespacho,
  });
}