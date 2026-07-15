import 'package:flutter/material.dart';
import '../utils/app_formatters.dart';

class TicketTermico extends StatelessWidget {
  final Map<String, dynamic> datosVenta;
  final List<Map<String, dynamic>> productosDisponibles;

  const TicketTermico({
    super.key,
    required this.datosVenta,
    required this.productosDisponibles,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Estilo base para simular impresora térmica de 80mm
    const TextStyle estiloTermico = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: Colors.black,
      fontWeight: FontWeight.w600,
    );

    const TextStyle estiloTermicoBold = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    // --- RECONSTRUCCIÓN DINÁMICA DE DATOS ---
    final DateTime fecha = datosVenta['hora'] is DateTime 
        ? datosVenta['hora'] 
        : DateTime.parse(datosVenta['hora'].toString());
        
    final String fechaStr = "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
    final String horaStr = "${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";
    
    final String tipoDocumento = datosVenta['documento'] ?? 'Boleta';
    final String metodoPago = datosVenta['metodo'] ?? 'Efectivo';
    final int total = (datosVenta['total'] as num).toInt();
    
    // Recuperamos el mapa del carrito guardado en el historial de la BD 
    final Map<dynamic, dynamic> carrito = datosVenta['carrito'] ?? {};

    return Dialog(
      backgroundColor: Colors.transparent, // Fondo transparente para que flote el papel
      child: Container(
        width: 320, // Ancho estándar de papel térmico
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCF9), // Tono papel hueso/térmico
          borderRadius: BorderRadius.circular(4), // Los tickets reales se cortan rectos
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- ENCABEZADO ---
            const Text(
              'DELICIAS MINERAS', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)
            ),
            const SizedBox(height: 6),
            const Text('RUT: 76.123.456-K', textAlign: TextAlign.center, style: estiloTermico),
            const Text('Av. Vicente Huidobro 1601, Coronel', textAlign: TextAlign.center, style: estiloTermico),
            const Text('Giro: Panadería y Pastelería', textAlign: TextAlign.center, style: estiloTermico),
            const SizedBox(height: 12),
            
            _LineaPunteada(),
            const SizedBox(height: 8),
            
            Text('${tipoDocumento.toUpperCase()} ELECTRÓNICA', textAlign: TextAlign.center, style: estiloTermicoBold),
            const SizedBox(height: 4),
            Text('Fecha: $fechaStr  Hora: hourStr', textAlign: TextAlign.center, style: estiloTermico),
            Text('Método de Pago: $metodoPago', textAlign: TextAlign.center, style: estiloTermico),
            if (datosVenta['rutCliente'] != null) ...[
              Text('Cliente RUT: ${datosVenta['rutCliente']}', textAlign: TextAlign.center, style: estiloTermico),
            ],
            
            const SizedBox(height: 8),
            _LineaPunteada(),
            const SizedBox(height: 12),

            // --- DETALLES DE PRODUCTOS ---
            const Row(
              children: [
                Expanded(flex: 2, child: Text('CANT', style: estiloTermicoBold)),
                Expanded(flex: 5, child: Text('DESCRIPCIÓN', style: estiloTermicoBold)),
                Expanded(flex: 3, child: Text('TOTAL', textAlign: TextAlign.right, style: estiloTermicoBold)),
              ],
            ),
            const SizedBox(height: 6),

            if (carrito.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('SIN DETALLE DE PRODUCTOS', textAlign: TextAlign.center, style: estiloTermico),
              )
            else
              ...carrito.entries.map((entry) {
                // Reconstruimos dinámicamente usando el SKU almacenado en la BD 
                final int sku = entry.key is int ? entry.key : int.parse(entry.key.toString());
                final double cantidad = (entry.value as num).toDouble();
                
                // Buscamos el producto en la lista del sistema [cite: 139]
                final producto = productosDisponibles.firstWhere(
                  (p) => p['sku'] == sku,
                  orElse: () => {'nombre': 'PRODUCTO SKU $sku', 'precio': 0},
                );
                
                final int subtotal = ((producto['precio'] as num) * cantidad).round();

                String cantStr = cantidad.truncateToDouble() == cantidad 
                    ? "${cantidad.toInt()} u" 
                    : "${cantidad.toStringAsFixed(3).replaceAll('.', ',')} kg";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: Text(cantStr, style: estiloTermico)),
                      Expanded(
                        flex: 5, 
                        child: Text(
                          producto['nombre'].toString().toUpperCase(), 
                          style: estiloTermico,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3, 
                        child: Text(
                          '\$${AppFormatters.formatearDinero(subtotal)}', 
                          textAlign: TextAlign.right, 
                          style: estiloTermico,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 12),
            _LineaPunteada(),
            const SizedBox(height: 12),

            // --- TOTAL ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL:', style: TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('\$${AppFormatters.formatearDinero(total)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text('¡Gracias por preferirnos!', textAlign: TextAlign.center, style: estiloTermico),
            const SizedBox(height: 12),
            
            // Efecto de código de barras
            const Center(
              child: Text(
                '||||| |||| ||||| ||||||| |||', 
                style: TextStyle(fontFamily: 'monospace', fontSize: 20, letterSpacing: 2, color: Colors.black, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón para cerrar la vista previa del ticket
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar Comprobante', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaPunteada extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54)),
            );
          }),
        );
      },
    );
  }
}