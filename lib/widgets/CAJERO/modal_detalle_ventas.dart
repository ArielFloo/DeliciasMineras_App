// Archivo: lib/widgets/modal_detalle_ventas.dart

import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../core/app_theme.dart';
import 'tarjeta_resumen_caja.dart';
// IMPORTAMOS TU FORMATEADOR (asumiendo que está en la carpeta utils)
import '../../utils/app_formatters.dart'; 

class ModalDetalleVentas extends StatefulWidget {
  final List<Map<String, dynamic>> productosDisponibles;

  const ModalDetalleVentas({super.key, required this.productosDisponibles});

  @override
  State<ModalDetalleVentas> createState() => _ModalDetalleVentasState();
}

class _ModalDetalleVentasState extends State<ModalDetalleVentas> {
  bool _cargando = true;
  List<Map<String, dynamic>> _ventasDB = [];
  int _totalEfectivo = 0;
  int _totalDebito = 0;
  int _totalCredito = 0;
  Map<int, double> _resumenProductos = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final ventas = await DatabaseService.instancia.obtenerVentasDelDia();
    
    int ef = 0; int deb = 0; int cred = 0;
    Map<int, double> prod = {};

    for (var venta in ventas) {
      if (venta['metodo'] == 'Efectivo') ef += (venta['total'] as num).toInt();
      if (venta['metodo'] == 'Debito') deb += (venta['total'] as num).toInt();
      if (venta['metodo'] == 'Credito') cred += (venta['total'] as num).toInt();

      if (venta['carrito'] != null) {
        (venta['carrito'] as Map<dynamic, dynamic>).forEach((sku, cantidad) {
          int skuInt = sku is int ? sku : int.parse(sku.toString());
          double cantDouble = (cantidad as num).toDouble();
          prod[skuInt] = (prod[skuInt] ?? 0.0) + cantDouble;
        });
      }
    }

    if (mounted) {
      setState(() {
        _ventasDB = ventas;
        _totalEfectivo = ef;
        _totalDebito = deb;
        _totalCredito = cred;
        _resumenProductos = prod;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int totalAcumulado = _totalEfectivo + _totalDebito + _totalCredito;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: colorScheme.surface,
      child: SizedBox(
        width: 650,
        height: 700,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- CABECERA ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.analytics_rounded, color: colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Cuadre de Turno',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: colorScheme.onSurfaceVariant,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // --- TARJETAS DE RESUMEN ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Row(
                        children: [
                          TarjetaResumenCaja(titulo: 'Efectivo', monto: _totalEfectivo, color: AppTheme.successColor),
                          const SizedBox(width: 12),
                          TarjetaResumenCaja(titulo: 'Débito', monto: _totalDebito, color: AppTheme.infoColor),
                          const SizedBox(width: 12),
                          TarjetaResumenCaja(titulo: 'Crédito', monto: _totalCredito, color: AppTheme.warningColor),
                        ],
                      ),
                    ),

                    // --- TOTAL ACUMULADO DESTACADO ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL RECAUDADO',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            Text(
                              // APLICACIÓN DEL FORMATO AL TOTAL GENERAL
                              '\$${AppFormatters.formatearDinero(totalAcumulado)}',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- NAVEGACIÓN POR PESTAÑAS ---
                    TabBar(
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      indicatorWeight: 3,
                      dividerColor: colorScheme.outlineVariant,
                      tabs: const [
                        Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos Despachados'),
                        Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Historial de Transacciones'),
                      ],
                    ),

                    // --- CONTENIDO DE LAS PESTAÑAS ---
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Pestaña 1: Productos
                          _resumenProductos.isEmpty
                              ? _ConstruirEstadoVacio(icono: Icons.shopping_bag_outlined, mensaje: 'Aún no hay productos vendidos en este turno.')
                              : ListView.separated(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: _resumenProductos.length,
                                  separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                  itemBuilder: (context, index) {
                                    int sku = _resumenProductos.keys.elementAt(index);
                                    double cantidad = _resumenProductos[sku]!;
                                    
                                    String nombreProducto = 'Producto Desconocido';
                                    try {
                                      nombreProducto = widget.productosDisponibles.firstWhere((p) => p['sku'] == sku)['nombre'];
                                    } catch (_) {}

                                    String cantAVisualizar = cantidad.truncateToDouble() == cantidad 
                                        ? "${cantidad.toInt()} u." 
                                        : "${cantidad.toStringAsFixed(3)} kg";

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: colorScheme.surfaceVariant,
                                        child: Text('${index + 1}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(nombreProducto, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      trailing: Text(cantAVisualizar, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                                    );
                                  },
                                ),

                          // Pestaña 2: Transacciones
                          _ventasDB.isEmpty
                              ? _ConstruirEstadoVacio(icono: Icons.receipt_outlined, mensaje: 'No hay transacciones registradas.')
                              : ListView.builder(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: _ventasDB.length,
                                  itemBuilder: (context, index) {
                                    final venta = _ventasDB[_ventasDB.length - 1 - index];
                                    final hora = venta['hora'] as DateTime;
                                    final String horaStr = "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}";
                                    
                                    return Card(
                                      elevation: 0,
                                      color: colorScheme.surfaceVariant.withOpacity(0.4),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            venta['metodo'] == 'Efectivo' ? Icons.payments_rounded : Icons.credit_card_rounded,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        title: Text('${venta['documento']} - ${venta['metodo']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(horaStr, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                        trailing: Text(
                                          // APLICACIÓN DEL FORMATO AL HISTORIAL INDIVIDUAL
                                          '\$${AppFormatters.formatearDinero((venta['total'] as num).toInt())}', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ConstruirEstadoVacio extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  const _ConstruirEstadoVacio({required this.icono, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(mensaje, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}