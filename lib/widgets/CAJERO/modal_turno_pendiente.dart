import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ModalTurnoPendiente extends StatelessWidget {
  final DateTime horaInicio;
  final int cantidadProductos;

  const ModalTurnoPendiente({
    super.key,
    required this.horaInicio,
    required this.cantidadProductos,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Formateamos la fecha y hora para que se vea mucho más profesional
    final String fechaStr = "${horaInicio.day.toString().padLeft(2, '0')}/${horaInicio.month.toString().padLeft(2, '0')}/${horaInicio.year}";
    final String horaStr = "${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Bordes mucho más redondeados
      elevation: 12,
      backgroundColor: colorScheme.surface,
      child: Container(
        width: 420, // Ancho controlado para que no se estire demasiado en pantallas grandes
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ÍCONO HERO SUPERIOR
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restore_page_rounded, 
                color: AppTheme.warningColor, 
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. TÍTULO Y DESCRIPCIÓN
            Text(
              'Turno Pendiente',
              style: TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.bold, 
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Se detectó una caja en memoria que no fue cerrada correctamente.\n¿Deseas retomarla o limpiar la caja?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, 
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            
            // 3. TARJETA DE DATOS (En vez de texto plano)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
              ),
              child: Column(
                children: [
                  _FilaDato(
                    icono: Icons.calendar_today_rounded, 
                    titulo: 'Iniciado el:', 
                    valor: '$fechaStr a las $horaStr',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _FilaDato(
                    icono: Icons.shopping_basket_rounded, 
                    titulo: 'Artículos en espera:', 
                    valor: '$cantidadProductos unidades',
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
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context, 'CERRAR_ANTIGUO'),
                    child: const Text('Empezar de cero', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, 'REANUDAR'),
                    child: const Text('Reanudar Venta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

// Widget auxiliar para mantener las filas de datos ordenadas
class _FilaDato extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _FilaDato({required this.icono, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          titulo, 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
        ),
        const Spacer(),
        Text(
          valor, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}