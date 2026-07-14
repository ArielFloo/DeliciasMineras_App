import 'package:flutter/material.dart';

class AdminBreadcrumbs extends StatelessWidget {
  final int indiceSeleccionado;
  final VoidCallback onInicioPressed;

  const AdminBreadcrumbs({
    super.key,
    required this.indiceSeleccionado,
    required this.onInicioPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Definimos en qué sección estamos parados
    String seccionActual = 'Tablero Principal';
    if (indiceSeleccionado == 1) seccionActual = 'Productos';
    if (indiceSeleccionado == 2) seccionActual = 'Ventas';
    if (indiceSeleccionado == 3) seccionActual = 'Personal';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enlace al Inicio (Clickeable)
        InkWell(
          onTap: onInicioPressed, // Usamos la función inyectada
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              'Inicio',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '/',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(width: 4),
        // Sección Actual (Estática por ser la última de la ruta)
        Text(
          seccionActual,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}