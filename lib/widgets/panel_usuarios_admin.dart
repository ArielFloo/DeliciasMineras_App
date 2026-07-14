import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/modal_formulario_empleado.dart';

class PanelUsuariosAdmin extends StatefulWidget {
  const PanelUsuariosAdmin({super.key});

  @override
  State<PanelUsuariosAdmin> createState() => _PanelUsuariosAdminState();
}

class _PanelUsuariosAdminState extends State<PanelUsuariosAdmin> {
  List<Empleado> _usuarios = []; // Ahora maneja la clase Empleado nativa de tu auth_service
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      // Consumimos directamente desde tu AuthService Singleton
      final datos = await AuthService().obtenerEmpleados();
      if (mounted) {
        setState(() {
          _usuarios = datos;
          _cargando = false;
        });
      }
    } catch (e) {
      print("Error cargando personal: $e");
    }
  }

  Future<void> _abrirFormularioRegistro() async {
    final bool? recargar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ModalFormularioEmpleado(),
    );

    if (recargar == true) {
      _cargarUsuarios(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario registrado y habilitado exitosamente.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personal & Operación',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: colorScheme.primary,
                  onPressed: _cargarUsuarios,
                  tooltip: 'Actualizar Estados',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _abrirFormularioRegistro,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Empleado', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 180,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _usuarios.length,
            itemBuilder: (context, index) {
              final user = _usuarios[index];
              final String rol = user.rol;
              final String estado = user.estado;

              Color ledColor = Colors.grey;
              IconData estadoIcon = Icons.power_settings_new_rounded;

              if (estado == 'Caja Abierta') {
                ledColor = AppTheme.successColor;
                estadoIcon = Icons.point_of_sale_rounded;
              } else if (estado == 'En Ruta') {
                ledColor = AppTheme.infoColor;
                estadoIcon = Icons.local_shipping_rounded;
              } else if (estado == 'Disponible') {
                ledColor = Colors.purple;
                estadoIcon = Icons.person_pin_rounded;
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            user.nombre[0],
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nombre,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.secondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'RUT: ${user.rut}',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rol,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: ledColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: ledColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                estado,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.secondary),
                              ),
                              Text(
                                user.detalleEstado,
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(estadoIcon, color: ledColor.withOpacity(0.5), size: 20),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}