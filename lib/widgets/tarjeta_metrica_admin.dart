import 'package:flutter/material.dart';

class TarjetaMetricaAdmin extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;
  final VoidCallback onMasInfo;

  const TarjetaMetricaAdmin({
    super.key,
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
    required this.onMasInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        height: 120, 
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1), // Sombra dinámica
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 10,
              child: Icon(
                icono,
                size: 80,
                color: colorScheme.onPrimary.withOpacity(0.2), // Blanco/Claro dinámico
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          valor,
                          style: TextStyle(
                            color: colorScheme.onPrimary, // Texto principal dinámico
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titulo,
                          style: TextStyle(
                            color: colorScheme.onPrimary, // Texto secundario dinámico
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                InkWell(
                  onTap: onMasInfo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.shadow.withOpacity(0.15), // Franja oscura dinámica
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Más Info', style: TextStyle(color: colorScheme.onPrimary, fontSize: 12)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_circle_right, color: colorScheme.onPrimary, size: 14),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}