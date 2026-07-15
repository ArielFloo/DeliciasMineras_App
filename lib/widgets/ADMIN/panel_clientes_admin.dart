import 'package:flutter/material.dart';
import '../../data/mock_database.dart';
import '../../core/app_theme.dart';
import '../../utils/app_formatters.dart';

class PanelClientesAdmin extends StatefulWidget {
  const PanelClientesAdmin({super.key});

  @override
  State<PanelClientesAdmin> createState() => _PanelClientesAdminState();
}

class _PanelClientesAdminState extends State<PanelClientesAdmin> {
  bool _cargando = true;
  List<Map<String, dynamic>> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargando = true);
    final data = await MockDatabase.instancia.obtenerClientes();
    setState(() {
      _clientes = data;
      _cargando = false;
    });
  }

  Future<void> _eliminarCliente(String rut) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 28),
            const SizedBox(width: 8),
            Text('¿Eliminar Cliente?', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        content: Text(
          'Estás a punto de eliminar al cliente con RUT $rut.\nEsta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await MockDatabase.instancia.eliminarCliente(rut);
      _cargarClientes();
    }
  }

Future<void> _mostrarFormularioCliente({Map<String, dynamic>? clienteExistente}) async {
    final formKey = GlobalKey<FormState>();
    final rutCtrl = TextEditingController(text: clienteExistente?['rut'] ?? '');
    final nombreCtrl = TextEditingController(text: clienteExistente?['nombre'] ?? '');
    final giroCtrl = TextEditingController(text: clienteExistente?['giro'] ?? '');
    
    final bool esEdicion = clienteExistente != null;
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        backgroundColor: colorScheme.surface,
        child: Container(
          width: 500, // Un poco más ancho para que los TextFields respiren
          padding: const EdgeInsets.all(32),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- CABECERA DEL FORMULARIO ---
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        esEdicion ? Icons.edit_document : Icons.domain_add_rounded, 
                        color: colorScheme.primary, 
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            esEdicion ? 'Editar Cliente' : 'Nuevo Mayorista',
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold, 
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            esEdicion 
                                ? 'Actualiza los datos comerciales del cliente.' 
                                : 'Ingresa la información del nuevo cliente al sistema.',
                            style: TextStyle(
                              fontSize: 14, 
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),

                // --- CAMPOS DE TEXTO ---
                TextFormField(
                  controller: rutCtrl,
                  decoration: InputDecoration(
                    labelText: 'RUT Empresa', 
                    hintText: '12.345.678-9',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  inputFormatters: [RutInputFormatter()],
                  enabled: !esEdicion, 
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'El RUT es obligatorio';
                    if (!AppFormatters.validarRut(value)) return 'El RUT ingresado no es válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Razón Social / Nombre',
                    prefixIcon: const Icon(Icons.business_rounded),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value!.isEmpty ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: giroCtrl,
                  decoration: InputDecoration(
                    labelText: 'Giro Comercial',
                    prefixIcon: const Icon(Icons.storefront_outlined),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value!.isEmpty ? 'El giro es obligatorio' : null,
                ),
                
                const SizedBox(height: 32),

                // --- BOTONES DE ACCIÓN ---
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
                        onPressed: () => Navigator.pop(context), 
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final datos = {
                              'rut': rutCtrl.text,
                              'nombre': nombreCtrl.text,
                              'giro': giroCtrl.text,
                            };

                            if (esEdicion) {
                              await MockDatabase.instancia.actualizarCliente(clienteExistente['rut'], datos);
                            } else {
                              final exito = await MockDatabase.instancia.agregarCliente(datos);
                              if (!exito) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('El RUT ya existe en el sistema'), backgroundColor: AppTheme.errorColor),
                                );
                                return;
                              }
                            }
                            if (context.mounted) Navigator.pop(context);
                            _cargarClientes();
                          }
                        },
                        child: Text(esEdicion ? 'Guardar Cambios' : 'Registrar Cliente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_cargando) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- CABECERA MODERNA TIPO DASHBOARD ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Directorio de Mayoristas', 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colorScheme.secondary)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona la información comercial de tus clientes frecuentes', 
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  elevation: 4,
                  shadowColor: colorScheme.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _mostrarFormularioCliente(),
                icon: const Icon(Icons.domain_add_rounded),
                label: const Text('Nuevo Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // --- LISTA DE CLIENTES PREMIUM ---
        Expanded(
          child: _clientes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.domain_disabled_rounded, size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text('No hay clientes registrados en el sistema.', style: TextStyle(color: colorScheme.outline, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = _clientes[index];
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              // Acento de color en el borde izquierdo
                              border: Border(left: BorderSide(color: colorScheme.primary, width: 6)),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Avatar Moderno
                                Container(
                                  height: 56, 
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.business_rounded, color: colorScheme.primary, size: 28),
                                ),
                                const SizedBox(width: 20),
                                
                                // Información Principal
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente['nombre'], 
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.badge_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Text(
                                            cliente['rut'], 
                                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // "Pill" para el Giro Comercial
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondary.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.storefront_outlined, size: 14, color: colorScheme.secondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  cliente['giro'], 
                                                  style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Botones de Acción Agrupados
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: AppTheme.infoColor),
                                        tooltip: 'Editar Datos',
                                        onPressed: () => _mostrarFormularioCliente(clienteExistente: cliente),
                                      ),
                                      Container(height: 24, width: 1, color: Colors.grey[300]), // Separador
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                                        tooltip: 'Eliminar Cliente',
                                        onPressed: () => _eliminarCliente(cliente['rut']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}