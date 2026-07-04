import 'package:flutter/material.dart';

class ModalPagoDialog extends StatelessWidget {
  final int totalAPagar;
  final bool esFactura;

  const ModalPagoDialog({
    super.key, 
    required this.totalAPagar,
    required this.esFactura,
  });

  @override
  Widget build(BuildContext context) {
    // Cálculo matemático del IVA (19%)
    final int neto = (totalAPagar / 1.19).round();
    final int iva = totalAPagar - neto;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(
        child: Text(
          esFactura ? 'Procesar Factura' : 'Procesar Boleta',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    esFactura ? 'Total a Cobrar (Factura)' : 'Total a Cobrar (Boleta)', 
                    style: const TextStyle(fontSize: 16, color: Colors.grey)
                  ),
                  Text(
                    '\$$totalAPagar',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  // Si es factura, mostramos el desglose matemático
                  if (esFactura) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monto Neto:', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        Text('\$$neto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('IVA (19%):', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        Text('\$$iva', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Seleccione el Método de Pago:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MetodoPagoCard(
                  icono: Icons.payments,
                  texto: 'Efectivo',
                  onTap: () => Navigator.pop(context, 'Efectivo'),
                ),
                _MetodoPagoCard(
                  icono: Icons.credit_card,
                  texto: 'Débito',
                  onTap: () => Navigator.pop(context, 'Debito'),
                ),
                _MetodoPagoCard(
                  icono: Icons.credit_score,
                  texto: 'Crédito',
                  onTap: () => Navigator.pop(context, 'Credito'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
      ],
    );
  }
}

class _MetodoPagoCard extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _MetodoPagoCard({required this.icono, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 12),
            Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}