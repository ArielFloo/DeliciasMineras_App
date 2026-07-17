// Archivo: lib/widgets/modal_validacion_identidad.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/empleado.dart';

class ModalValidacionIdentidad extends StatefulWidget {
  final Empleado cajeroActual; // Cambiamos de recibir un String a recibir el objeto Empleado completo

  const ModalValidacionIdentidad({
    super.key,
    required this.cajeroActual,
  });

  @override
  State<ModalValidacionIdentidad> createState() => _ModalValidacionIdentidadState();
}

class _ModalValidacionIdentidadState extends State<ModalValidacionIdentidad> {
  final TextEditingController _passController = TextEditingController();
  bool _ocultarTexto = true;
  String? _mensajeError;

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

Future<void> _intentarDesbloquear() async {
    final pass = _passController.text.trim();
    
    if (pass.isEmpty) {
      setState(() => _mensajeError = 'Debes ingresar una contraseña');
      return;
    }

    // Ponemos un pequeño mensaje de carga para que el usuario sepa que está pensando
    setState(() => _mensajeError = 'Validando credenciales...');
    final rutCajero = widget.cajeroActual.rut;
    final empleadoValidado = await AuthService().login(rutCajero, pass);

    if (empleadoValidado != null) {
      if (mounted) {
        Navigator.pop(context, true); // ¡Éxito!
      }
    } else {
      setState(() {
        _mensajeError = 'Contraseña incorrecta para ${widget.cajeroActual.nombre}.';
        _passController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ÍCONO HERO DE SEGURIDAD
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 44,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. TEXTOS Y USUARIO DESTACADO
            Text(
              'Validar Identidad',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Por seguridad, confirma tu contraseña para reanudar la sesión de:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, 
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            
            // Tarjeta sutil para el nombre del cajero
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
              ),
              child: Text(
                widget.cajeroActual.nombre, // Usamos dinámicamente el nombre del objeto
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 3. CAMPO DE CONTRASEÑA ESTILIZADO
            TextFormField(
              controller: _passController,
              obscureText: _ocultarTexto,
              autofocus: true,
              style: const TextStyle(fontSize: 18, letterSpacing: 3.0),
              decoration: InputDecoration(
                labelText: 'Contraseña de Acceso',
                labelStyle: const TextStyle(letterSpacing: 0),
                errorText: _mensajeError,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _ocultarTexto ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _ocultarTexto = !_ocultarTexto;
                    });
                  },
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              onFieldSubmitted: (_) => _intentarDesbloquear(),
            ),
            const SizedBox(height: 32),

            // 4. BOTONES DE ACCIÓN SIMÉTRICOS
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
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _intentarDesbloquear,
                    child: const Text('Desbloquear', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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