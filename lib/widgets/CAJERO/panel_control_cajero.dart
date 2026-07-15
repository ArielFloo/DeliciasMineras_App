import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

class PanelControlCajero extends StatelessWidget {
  final Map<String, dynamic>? clienteSeleccionado;
  final String? tipoPedido;
  final bool carritoVacio;
  final VoidCallback onAsignarMayorista;
  final VoidCallback onConfigurarPedido;
  final VoidCallback onCobrarBoleta;
  final VoidCallback onEmitirFactura;
  final VoidCallback onEmitirValeInterno;
  final VoidCallback onVerDetalleVenta;
  final VoidCallback onCierreCaja;
  final Empleado? cajeroActual;
  final String tiempoTranscurrido;
  final VoidCallback onQuitarCliente;

  const PanelControlCajero({
    super.key,
    required this.clienteSeleccionado,
    required this.tipoPedido,
    required this.carritoVacio,
    required this.onAsignarMayorista,
    required this.onConfigurarPedido,
    required this.onCobrarBoleta,
    required this.onEmitirFactura,
    required this.onEmitirValeInterno,
    required this.onVerDetalleVenta,
    required this.onCierreCaja,
    required this.cajeroActual,
    required this.tiempoTranscurrido,
    required this.onQuitarCliente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (clienteSeleccionado == null) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppTheme.businessColor,
                side: const BorderSide(color: AppTheme.businessColor),
              ),
              onPressed: onAsignarMayorista,
              icon: const Icon(Icons.business),
              label: const Text('Asignar Venta Mayorista', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            Card(
              color: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified, color: AppTheme.warningColor, size: 20),
                            SizedBox(width: 8),
                            Text('CLIENTE EMPRESA', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        GestureDetector(
                          onTap: onQuitarCliente,
                          child: Icon(Icons.close, color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.7), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      clienteSeleccionado!['nombre'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('RUT: ${clienteSeleccionado!['rut']}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.7))),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppTheme.warningColor,
              side: const BorderSide(color: AppTheme.warningColor),
            ),
            onPressed: onConfigurarPedido,
            icon: const Icon(Icons.inventory_2),
            label: const Text('Programar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 24),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: carritoVacio ? null : onCobrarBoleta,
            icon: const Icon(Icons.receipt, size: 28),
            label: const Text('COBRAR BOLETA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          (!carritoVacio && clienteSeleccionado != null)
              ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: AppTheme.highlightColor,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: AppTheme.highlightColor.withOpacity(0.5),
                  ),
                  onPressed: onEmitirFactura,
                  icon: const Icon(Icons.receipt_long, size: 28),
                  label: const Text('EMITIR FACTURA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.grey, // Dejaremos este fijo porque indica deshabilitado
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: null,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('EMITIR FACTURA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppTheme.infoColor,
              side: const BorderSide(color: AppTheme.infoColor),
            ),
            onPressed: onEmitirValeInterno,
            icon: const Icon(Icons.assignment),
            label: const Text('VENTA MANUAL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: onVerDetalleVenta,
            icon: const Icon(Icons.assessment),
            label: const Text('Detalle Venta del Día'),
          ),

          if (cajeroActual != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        radius: 20,
                        child: Text(cajeroActual!.nombre[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cajeroActual!.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'RUT: ${cajeroActual!.rut}',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiempo de turno:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        tiempoTranscurrido,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
            ),
            onPressed: onCierreCaja,
            icon: const Icon(Icons.lock_clock),
            label: const Text('Cierre de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    )
    );
  }
}