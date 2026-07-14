import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../utils/app_formatters.dart';

class ModalFormularioEmpleado extends StatefulWidget {
  const ModalFormularioEmpleado({super.key});

  @override
  State<ModalFormularioEmpleado> createState() => _ModalFormularioEmpleadoState();
}

class _ModalFormularioEmpleadoState extends State<ModalFormularioEmpleado> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _rutCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _extraCtrl = TextEditingController(); 
  
  String _rolSeleccionado = 'Cajero';
  bool _guardando = false;

  // Definimos los roles con sus respectivos íconos para las tarjetas
  final List<Map<String, dynamic>> _roles = [
    {'nombre': 'Cajero', 'icono': Icons.point_of_sale_rounded},
    {'nombre': 'Repartidor', 'icono': Icons.local_shipping_rounded},
    {'nombre': 'Administrador', 'icono': Icons.admin_panel_settings_rounded},
  ];

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!AppFormatters.validarRut(_rutCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El RUT ingresado no es válido.'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _guardando = true);

    Empleado nuevoUsuario;
    
    if (_rolSeleccionado == 'Repartidor') {
      nuevoUsuario = Repartidor(
        id: 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        rut: _rutCtrl.text,
        nombre: _nombreCtrl.text.trim(),
        password: _passwordCtrl.text,
        patenteVehiculoAsignado: _extraCtrl.text.trim().isEmpty ? 'Sin Asignar' : _extraCtrl.text.trim().toUpperCase(),
      );
    } else if (_rolSeleccionado == 'Administrador') {
      nuevoUsuario = Administrador(
        id: 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        rut: _rutCtrl.text,
        nombre: _nombreCtrl.text.trim(),
        password: _passwordCtrl.text,
        nivelAcceso: int.tryParse(_extraCtrl.text) ?? 1,
      );
    } else {
      nuevoUsuario = Cajero(
        id: 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        rut: _rutCtrl.text,
        nombre: _nombreCtrl.text.trim(),
        password: _passwordCtrl.text,
        idLocal: int.tryParse(_extraCtrl.text) ?? 1,
      );
    }

    bool exito = await AuthService().registrarEmpleado(nuevoUsuario);

    if (!exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Este RUT ya está registrado en el sistema.'), backgroundColor: AppTheme.errorColor),
      );
      setState(() => _guardando = false);
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _rutCtrl.dispose();
    _nombreCtrl.dispose();
    _passwordCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.successColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Registrar Personal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                        Text('Dar de alta a un nuevo colaborador', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Selector de Rol Moderno (Chips Interactivos)
                Text(
                  'Rol en la empresa',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _roles.map((rolData) {
                    final esActivo = _rolSeleccionado == rolData['nombre'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () => setState(() {
                            _rolSeleccionado = rolData['nombre'];
                            _extraCtrl.clear();
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: esActivo ? AppTheme.primaryColor.withOpacity(0.08) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: esActivo ? AppTheme.primaryColor : Colors.grey[300]!,
                                width: esActivo ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  rolData['icono'],
                                  color: esActivo ? AppTheme.primaryColor : colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rolData['nombre'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: esActivo ? FontWeight.bold : FontWeight.normal,
                                    color: esActivo ? AppTheme.primaryColor : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // RUT con formateador automático en vivo
                TextFormField(
                  controller: _rutCtrl,
                  inputFormatters: [RutInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'RUT',
                    hintText: '12.345.678-9',
                    prefixIcon: const Icon(Icons.credit_card_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Nombre y Apellido
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Campo Condicional según el rol
                if (_rolSeleccionado == 'Repartidor')
                  TextFormField(
                    controller: _extraCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Patente del Vehículo (Opcional)',
                      prefixIcon: const Icon(Icons.directions_car_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else if (_rolSeleccionado == 'Cajero')
                  TextFormField(
                    controller: _extraCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ID del Local Asignado',
                      prefixIcon: const Icon(Icons.storefront_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const SizedBox(height: 16),

                // Contraseña provisoria
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña de Acceso',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.length < 3 ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 32),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _guardando ? null : () => Navigator.pop(context, false),
                      child: Text('Cancelar', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(_guardando ? 'Guardando...' : 'Crear Usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}