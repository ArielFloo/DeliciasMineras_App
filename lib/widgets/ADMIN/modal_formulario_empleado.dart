import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/database_service.dart';
import '../../utils/app_formatters.dart';
import '../../models/empleado.dart';

class ModalFormularioEmpleado extends StatefulWidget {
  // Recibe opcionalmente al empleado para activar el modo edición
  final Empleado? empleadoAEditar;

  const ModalFormularioEmpleado({super.key, this.empleadoAEditar});

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
  bool _esEdicion = false; // Bandera de control

  List<Map<String, dynamic>> _localesBD = [];
  int? _localSeleccionado;
  bool _cargandoLocales = true;

  final List<Map<String, dynamic>> _roles = [
    {'nombre': 'Cajero', 'icono': Icons.point_of_sale_rounded},
    {'nombre': 'Repartidor', 'icono': Icons.local_shipping_rounded},
    {'nombre': 'Administrador', 'icono': Icons.admin_panel_settings_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.empleadoAEditar != null;
    _cargarLocales();
    
    // Si viene un empleado, pre-llenamos sus campos históricos
    if (_esEdicion) {
      final emp = widget.empleadoAEditar!;
      _rutCtrl.text = emp.rut;
      _nombreCtrl.text = emp.nombre;
      _passwordCtrl.text = emp.password;
      _rolSeleccionado = emp.rol;
      
      // Control de datos extendidos según la herencia del modelo
      if (emp is Repartidor) {
        _extraCtrl.text = emp.patenteVehiculoAsignado;
      } else if (emp is Administrador) {
        _extraCtrl.text = emp.nivelAcceso.toString();
      } else if (emp is Cajero) {
        _localSeleccionado = emp.idLocal;
      }
    }
  }

  Future<void> _cargarLocales() async {
    final data = await DatabaseService.instancia.obtenerLocales();
    if (mounted) {
      setState(() {
        _localesBD = data;
        // Solo asigna el primero por defecto si no venimos arrastrando el local en edición
        if (_localesBD.isNotEmpty && _localSeleccionado == null) {
          _localSeleccionado = _localesBD.first['idlocal'];
        }
        _cargandoLocales = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!AppFormatters.validarRut(_rutCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El RUT ingresado no es válido.'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _guardando = true);
    String rutLimpioParaBD = _rutCtrl.text.replaceAll('.', '').toUpperCase();
    
    // Mantenemos el ID original si es edición, o generamos uno nuevo si es un registro
    String idEmpleadoFinal = _esEdicion 
        ? widget.empleadoAEditar!.id 
        : 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

    Empleado usuarioProcesado;
    
    if (_rolSeleccionado == 'Repartidor') {
      usuarioProcesado = Repartidor(
        id: idEmpleadoFinal,
        rut: rutLimpioParaBD, 
        nombre: _nombreCtrl.text.trim(),
        password: _passwordCtrl.text,
        patenteVehiculoAsignado: _extraCtrl.text.trim().isEmpty ? 'Sin Asignar' : _extraCtrl.text.trim().toUpperCase(),
      );
    } else if (_rolSeleccionado == 'Administrador') {
      usuarioProcesado = Administrador(
        id: idEmpleadoFinal,
        rut: rutLimpioParaBD, 
        nombre: _nombreCtrl.text.trim(),
        password: _passwordCtrl.text,
        nivelAcceso: int.tryParse(_extraCtrl.text) ?? 1,
      );
    } else {
      usuarioProcesado = Cajero(
        id: idEmpleadoFinal,
        rut: rutLimpioParaBD, 
        nombre: _nombreCtrl.text.trim(),
        password: _passwordCtrl.text,
        idLocal: _localSeleccionado ?? 1, 
      );
    }

    bool exito;
    if (_esEdicion) {
      // LLAMADA AL BACKEND PARA ACTUALIZAR (puedes estructurar este método en tu DB Service)
      exito = await DatabaseService.instancia.actualizarEmpleado(usuarioProcesado);
    } else {
      exito = await DatabaseService.instancia.registrarNuevoEmpleado(usuarioProcesado);
    }

    if (!exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion ? 'Error al actualizar el registro.' : 'Error: Este RUT ya está registrado en el sistema.'), 
          backgroundColor: AppTheme.errorColor
        ),
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
                // Cabecera Dinámica según la acción
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_esEdicion ? AppTheme.primaryColor : AppTheme.successColor).withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Icon(
                        _esEdicion ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, 
                        color: _esEdicion ? AppTheme.primaryColor : AppTheme.successColor, 
                        size: 28
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_esEdicion ? 'Editar Perfil' : 'Registrar Personal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                        Text(_esEdicion ? 'Modificando los parámetros del colaborador' : 'Formulario de ingreso a nuevo colaborador', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Selector de Rol Moderno (Se bloquea el cambio si es Edición)
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
                          onTap: _esEdicion ? null : () => setState(() {
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
                            child: Opacity(
                              opacity: (_esEdicion && !esActivo) ? 0.4 : 1.0, // Atenúa los roles inactivos en la edición
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
                  _cargandoLocales 
                    ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                    : DropdownButtonFormField<int>(
                        value: _localSeleccionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Asignar a Sucursal',
                          prefixIcon: const Icon(Icons.storefront_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _localesBD.map((local) {
                          return DropdownMenuItem<int>(
                            value: local['idlocal'],
                            child: Text(
                              '${local['callelocal']} ${local['numerolocal']}, ${local['ciudadlocal']}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1, 
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _localSeleccionado = val);
                        },
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

                // Botones de salida e Inserción/Actualización
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
                          backgroundColor: _esEdicion ? AppTheme.primaryColor : AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Icon(_esEdicion ? Icons.save_rounded : Icons.check_circle_outline_rounded),
                        label: Text(
                          _guardando 
                              ? 'Guardando...' 
                              : (_esEdicion ? 'Actualizar Cambios' : 'Crear Usuario'), 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                        ),
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