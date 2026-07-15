// Archivo: lib/widgets/modal_cierre_caja.dart

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ModalCierreCaja extends StatelessWidget {
  final String tiempoTranscurrido;

  const ModalCierreCaja({
    super.key,
    required this.tiempoTranscurrido,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: colorScheme.surface,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ÍCONO HERO SUPERIOR
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: AppTheme.errorColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // 2. TÍTULO Y DESCRIPCIÓN
            Text(
              'Cierre de Caja',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Estás seguro de que deseas cerrar la caja y finalizar tu turno?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // 3. TARJETA DE DATOS (Tiempo transcurrido)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Tiempo total:',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    tiempoTranscurrido,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                      fontFamily: 'monospace', // Mantiene el estilo digital del reloj
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. BOTONES DE ACCIÓN
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context, false), // Devuelve false para cancelar
                    child: const Text('Volver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, true), // Devuelve true para confirmar
                    child: const Text('Sí, Cerrar Caja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}