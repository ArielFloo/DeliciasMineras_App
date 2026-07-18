import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/database_service.dart';

class ModalFormularioProducto extends StatefulWidget {
  final Map<String, dynamic>? productoAEditar;

  const ModalFormularioProducto({super.key, this.productoAEditar});

  @override
  State<ModalFormularioProducto> createState() => _ModalFormularioProductoState();
}

class _ModalFormularioProductoState extends State<ModalFormularioProducto> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _skuCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _stockCtrl;
  String _categoriaSeleccionada = 'Panadería';
  
  bool _guardando = false;

  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Panadería', 'icono': Icons.bakery_dining_outlined},
    {'nombre': 'Pastelería', 'icono': Icons.cake_outlined},
    {'nombre': 'Bebidas', 'icono': Icons.local_cafe_outlined},
    {'nombre': 'Abarrotes', 'icono': Icons.breakfast_dining_outlined},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productoAEditar;
    _skuCtrl = TextEditingController(text: p != null ? p['sku'].toString() : '');
    _nombreCtrl = TextEditingController(text: p != null ? p['nombre'] : '');
    _precioCtrl = TextEditingController(text: p != null ? p['precio'].toString() : '');
    _stockCtrl = TextEditingController(text: p != null ? p['stock'].toString() : '0');
    if (p != null && _categorias.any((c) => c['nombre'] == p['categoria'])) {
      _categoriaSeleccionada = p['categoria'];
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final productoArmado = {
      'sku': int.parse(_skuCtrl.text.trim()),
      'nombre': _nombreCtrl.text.trim(),
      'precio': int.parse(_precioCtrl.text.trim()),
      'stock': int.parse(_stockCtrl.text.trim()),
      'categoria': _categoriaSeleccionada,
    };

    if (widget.productoAEditar == null) {
      bool exito = await DatabaseService.instancia.agregarProducto(productoArmado);
      if (!exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: El SKU ingresado ya existe en la base de datos.'), 
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _guardando = false);
        return;
      }
    } else {
      await DatabaseService.instancia.actualizarProducto(widget.productoAEditar!['sku'], productoArmado);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.productoAEditar != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera Moderna
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: esEdicion ? AppTheme.infoColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        esEdicion ? Icons.edit_note_rounded : Icons.add_to_photos_rounded,
                        color: esEdicion ? AppTheme.infoColor : AppTheme.successColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                        Text(
                          esEdicion ? 'Actualiza los parámetros del catálogo' : 'Registra un nuevo SKU en el inventario',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Selector de Categoría Moderno (Chips Horizontales)
                Text(
                  'Categoría',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _categorias.map((cat) {
                    final esActivo = _categoriaSeleccionada == cat['nombre'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () => setState(() => _categoriaSeleccionada = cat['nombre']),
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
                                  cat['icono'],
                                  color: esActivo ? AppTheme.primaryColor : colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat['nombre'],
                                  style: TextStyle(
                                    fontSize: 11,
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

                // Campo: SKU (Sencillo y Limpio)
                TextFormField(
                  controller: _skuCtrl,
                  keyboardType: TextInputType.number,
                  readOnly: esEdicion,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'SKU del Producto',
                    prefixIcon: const Icon(Icons.qr_code_rounded),
                    filled: esEdicion,
                    fillColor: esEdicion ? Colors.grey[100] : Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Por favor ingrese el SKU' : null,
                ),
                const SizedBox(height: 16),

                // Campo: Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre Comercial',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Ingrese un nombre descriptivo' : null,
                ),
                const SizedBox(height: 16),

                // Fila: Precio y Stock
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Precio Público',
                          prefixText: '\$ ',
                          prefixIcon: const Icon(Icons.monetization_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Stock Inicial',
                          prefixIcon: const Icon(Icons.warehouse_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Acciones Inferiores (Grandes y Espaciadas)
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
                          backgroundColor: esEdicion ? AppTheme.infoColor : AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Icon(esEdicion ? Icons.edit_rounded : Icons.add_circle_outline_rounded),
                        label: Text(
                          _guardando ? 'Procesando...' : (esEdicion ? 'Actualizar Cambios' : 'Registrar Producto'), 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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