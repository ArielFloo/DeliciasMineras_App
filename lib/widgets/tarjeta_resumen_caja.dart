import 'package:flutter/material.dart';
import '../utils/app_formatters.dart';

class TarjetaResumenCaja extends StatelessWidget {
  final String titulo;
  final int monto;
  final Color color;

  const TarjetaResumenCaja({
    super.key,
    required this.titulo,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              titulo, 
              style: TextStyle(color: color, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 4),
            Text(
              // 2. Aplicamos el formato aquí
              '\$${AppFormatters.formatearDinero(monto)}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ],
        ),
      ),
    );
  }
}