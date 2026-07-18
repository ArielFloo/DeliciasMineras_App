import 'package:flutter/material.dart';
import '/screens/REPARTIDOR/detalle_envio_screen.dart';
import '../../core/app_theme.dart';

class TarjetaEnvio extends StatelessWidget {
  final Map<String, dynamic> envio; // Usamos Map temporal por el prototipo
  final String precioFormateado;
  final Function(Map<String, dynamic>) onEntregado;

  const TarjetaEnvio({
    super.key,
    required this.envio,
    required this.precioFormateado,
    required this.onEntregado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            // Navegamos a la pantalla de detalle esperando el resultado de la entrega
            final fueEntregado = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleEnvioScreen(envio: {
                  ...envio,
                  'precioFormateado': precioFormateado,
                }),
              ),
            );

            // Si volvió con un 'true', significa que se confirmó la entrega
            if (fueEntregado == true) {
              onEntregado(envio);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        envio['razonSocial'],
                        // Se reemplazó el color duro por el secondaryColor de tu tema
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondaryColor), 
                      ),
                      const SizedBox(height: 4),
                      Text('Envío #${envio['idEnvio']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Se reemplazó el rojo (Colors.redAccent) por tu primaryColor
                          const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18), 
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              envio['direccionEntrega'],
                              // Usando secondaryColor con opacidad para textos secundarios en lugar de gris quemado
                              style: TextStyle(color: AppTheme.secondaryColor.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500), 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // La flecha ahora resalta usando el primaryColor de tu paleta
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor), 
              ],
            ),
          ),
        ),
      ),
    );
  }
}