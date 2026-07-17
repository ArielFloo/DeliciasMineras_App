import 'package:flutter/material.dart';
import '../utils/app_formatters.dart';
import '../services/sesion_usuario.dart';
import '../services/database_service.dart'; // <-- Importamos la BD para buscar el local real

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
    // Envolvemos el Dialog en un FutureBuilder para consultar Supabase en vivo
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MockDatabase.instancia.obtenerLocales(),
      builder: (context, snapshot) {
        
        // Mientras carga, mostramos un indicador discreto
        if (!snapshot.hasData) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final localesBD = snapshot.data!;
        final colorScheme = Theme.of(context).colorScheme;

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

        // --- RECONSTRUCCIÓN DINÁMICA DE DATOS DE LA VENTA ---
        final DateTime fecha = datosVenta['hora'] is DateTime 
            ? datosVenta['hora'] 
            : DateTime.parse(datosVenta['hora'].toString());
            
        final String fechaStr = "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
        final String horaStr = "${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";
        
        final String tipoDocumento = datosVenta['documento'] ?? 'Boleta';
        final String metodoPago = datosVenta['metodo'] ?? 'Efectivo';
        final int total = (datosVenta['total'] as num).toInt();
        final Map<dynamic, dynamic> carrito = datosVenta['carrito'] ?? {};

        // ==========================================
        // LÓGICA DE SUCURSAL 100% CONECTADA A LA BD
        // ==========================================
        // Intentamos obtener el local desde los datos de la venta, si no, usamos el del cajero en sesión
        final int idLocalInt = datosVenta['lugar'] != null 
            ? int.tryParse(datosVenta['lugar'].toString()) ?? SesionUsuario.instancia.idLocal ?? 1
            : SesionUsuario.instancia.idLocal ?? 1;

        // Buscamos el local en la lista obtenida de Supabase
        final localReal = localesBD.firstWhere(
          (l) => l['idlocal'] == idLocalInt,
          orElse: () => {
            'ciudadlocal': 'MATRIZ',
            'callelocal': 'Dirección no registrada',
            'numerolocal': ''
          },
        );

        final String nombreSucursal = 'SUCURSAL ${localReal['ciudadlocal'].toString().toUpperCase()}';
        final String direccionSucursal = '${localReal['callelocal']} ${localReal['numerolocal']}, ${localReal['ciudadlocal']}';
        const String rutEmpresa = '76.123.456-K'; // RUT genérico de la empresa matriz
        // ==========================================

        return Dialog(
          backgroundColor: Colors.transparent, 
          child: Container(
            width: 320, 
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFCF9), 
              borderRadius: BorderRadius.circular(4), 
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
                // --- ENCABEZADO DINÁMICO ---
                const Text(
                  'DELICIAS MINERAS', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                Text(nombreSucursal, textAlign: TextAlign.center, style: estiloTermicoBold),
                const SizedBox(height: 6),
                Text('RUT: $rutEmpresa', textAlign: TextAlign.center, style: estiloTermico),
                Text(direccionSucursal, textAlign: TextAlign.center, style: estiloTermico), 
                const Text('Giro: Panadería y Pastelería', textAlign: TextAlign.center, style: estiloTermico),
                const SizedBox(height: 12),
                
                _LineaPunteada(),
                const SizedBox(height: 8),
                
                Text('${tipoDocumento.toUpperCase()} ELECTRÓNICA', textAlign: TextAlign.center, style: estiloTermicoBold),
                const SizedBox(height: 4),
                Text('Fecha: $fechaStr  Hora: $horaStr', textAlign: TextAlign.center, style: estiloTermico), 
                Text('Método de Pago: $metodoPago', textAlign: TextAlign.center, style: estiloTermico),
                
                if (tipoDocumento.toLowerCase() == 'factura' && datosVenta['rutCliente'] != null) ...[
                  const SizedBox(height: 8),
                  const Text('DATOS DEL RECEPTOR', textAlign: TextAlign.center, style: estiloTermicoBold),
                  Text('RUT: ${AppFormatters.formatearRut(datosVenta['rutCliente'].toString())}', textAlign: TextAlign.center, style: estiloTermico),
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
                    final int sku = entry.key is int ? entry.key : int.parse(entry.key.toString());
                    final double cantidad = (entry.value as num).toDouble();
                    
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