import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/modal_pago_dialog.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'dart:async';
import '../widgets/tarjeta_resumen_caja.dart';

class CajeroHomeScreen extends StatefulWidget {
  const CajeroHomeScreen({super.key});

  @override
  State<CajeroHomeScreen> createState() => _CajeroHomeScreenState();
}

class _CajeroHomeScreenState extends State<CajeroHomeScreen> {

  // ESTADO DEL USUARIO Y SESIÓN
  late DateTime _horaInicioTurno;
  Timer? _timer;
  String _tiempoTranscurrido = "00:00:00";
  // Obtenemos al usuario que inició sesión
  final Empleado? _cajeroActual = AuthService().currentUser;

  // Lista para almacenar ventas concretadas (aunque no se persistan en la base de datos aún)
  final List<Map<String, dynamic>> _ventasDelDia = [];


  @override
  void initState() {
    super.initState();
    // Guardamos la hora exacta en la que entró a esta pantalla
    // (En un futuro, aquí podremos leer la hora desde la base de datos o SharedPreferences)
    _horaInicioTurno = DateTime.now();
    
    // Reloj que se actualiza cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _actualizarTiempoSesion();
    });
  }

  void _actualizarTiempoSesion() {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(_horaInicioTurno);

    // Formateamos la diferencia para que se vea como HH:MM:SS
    String dosDigitos(int n) => n.toString().padLeft(2, "0");
    String horas = dosDigitos(diferencia.inHours);
    String minutos = dosDigitos(diferencia.inMinutes.remainder(60));
    String segundos = dosDigitos(diferencia.inSeconds.remainder(60));

    setState(() {
      _tiempoTranscurrido = "$horas:$minutos:$segundos";
    });
  }

  final TextEditingController _skuController = TextEditingController();

  final List<Map<String, dynamic>> _productosDisponibles = [
    {'sku': 1, 'nombre': 'Pan de Molde Integral', 'precio': 2500, 'stock': 2},
    {'sku': 2, 'nombre': 'Medialunas', 'precio': 600, 'stock': 20}, 
    {'sku': 3, 'nombre': 'Kuchen de Manzana', 'precio': 8500, 'stock': 13},
    {'sku': 4, 'nombre': 'Baguette', 'precio': 1200, 'stock': 10},
    {'sku': 5, 'nombre': 'Donas Glaseadas', 'precio': 1000, 'stock': 0}, 
  ];

  final List<Map<String, dynamic>> _clientesMayoristas = [
    {'rut': '76738555-3', 'nombre': 'Laboratorio Carreño, Mora y Jara Ltda.', 'giro': 'Laboratorio'},
    {'rut': '74498685-0', 'nombre': 'Grupo Díaz y Catalan S.p.A.', 'giro': 'Comercio'},
    {'rut': '78956253-6', 'nombre': 'Becerra, Garrido y Olivares Ltda.', 'giro': 'Distribución'},
  ];

  final Map<int, int> _carrito = {};
  Map<String, dynamic>? _clienteSeleccionado;
  
  String? _tipoPedido; 
  final int _tarifaDespachoFija = 3500;

  int _multiplicador = 1;

  void _agregarAlCarrito(Map<String, dynamic> producto, {int cantidad = 1}) {
    setState(() {
      int sku = producto['sku'];
      int stockActual = producto['stock'];
      int cantidadEnCarrito = _carrito[sku] ?? 0;

      if (cantidadEnCarrito + cantidad <= stockActual) {
        _carrito[sku] = cantidadEnCarrito + cantidad;
        _multiplicador = 1; 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock insuficiente. Solo quedan $stockActual unidades de ${producto['nombre']} en total.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });
  }

  void _removerDelCarrito(int sku) {
    setState(() {
      if (_carrito.containsKey(sku) && _carrito[sku]! > 1) {
        _carrito[sku] = _carrito[sku]! - 1;
      } else {
        _carrito.remove(sku);
      }
    });
  }

  void _buscarYAgregarPorSKU(String input) {
    if (input.isEmpty) return;
    final int? skuBuscado = int.tryParse(input);
    
    if (skuBuscado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un SKU numérico válido.')),
      );
      return;
    }

    final index = _productosDisponibles.indexWhere((p) => p['sku'] == skuBuscado);
    if (index != -1) {
      _agregarAlCarrito(_productosDisponibles[index], cantidad: _multiplicador);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SKU $skuBuscado no encontrado en el sistema.')),
      );
    }
    _skuController.clear();
  }

  Future<void> _abrirBuscadorAvanzado() async {
    final Map<String, dynamic>? productoSeleccionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BuscadorProductosDialog(productos: _productosDisponibles),
    );
    if (productoSeleccionado != null) {
      _agregarAlCarrito(productoSeleccionado, cantidad: _multiplicador);
    }
  }

  Future<void> _configurarMultiplicador() async {
    final TextEditingController multCtrl = TextEditingController();
    
    final int? nuevoMultiplicador = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Multiplicador de Cantidad', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        content: TextField(
          controller: multCtrl,
          keyboardType: TextInputType.number,
          autofocus: true, 
          decoration: const InputDecoration(
            labelText: 'Ingrese cantidad a sumar',
            hintText: 'Ej: 5',
            prefixIcon: Icon(Icons.close),
          ),
          onSubmitted: (valor) {
            Navigator.pop(context, int.tryParse(valor));
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(multCtrl.text)),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (nuevoMultiplicador != null && nuevoMultiplicador > 0) {
      setState(() {
        _multiplicador = nuevoMultiplicador;
      });
    }
  }

  Future<void> _abrirBuscadorMayoristas() async {
    final Map<String, dynamic>? clienteEncontrado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BuscadorClientesDialog(clientes: _clientesMayoristas),
    );
    if (clienteEncontrado != null) {
      setState(() {
        _clienteSeleccionado = clienteEncontrado;
      });
    }
  }

  Future<void> _configurarPedido() async {
    final String? seleccion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Programar Pedido',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
        ),
        content: const Text('¿Este pedido es para retiro en local o requiere despacho al cliente?'),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'retiro'),
            icon: const Icon(Icons.storefront),
            label: const Text('Retiro en Local'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'despacho'),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Despacho'),
          ),
        ],
      ),
    );

    if (seleccion != null) {
      if (seleccion == 'despacho' && _clienteSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text('Error: El despacho es exclusivo para clientes Empresa. Asigne un cliente mayorista primero.'),
          ),
        );
        return; 
      }
      setState(() {
        _tipoPedido = seleccion;
      });
    }
  }

  // NUEVA FUNCIÓN: Muestra el reporte de ventas de la sesión actual
  void _mostrarDetalleVentas() {
    int totalEfectivo = 0;
    int totalDebito = 0;
    int totalCredito = 0;

    // Calculamos los totales recorriendo nuestra lista en memoria
    for (var venta in _ventasDelDia) {
      if (venta['metodo'] == 'Efectivo') totalEfectivo += venta['total'] as int;
      if (venta['metodo'] == 'Debito') totalDebito += venta['total'] as int;
      if (venta['metodo'] == 'Credito') totalCredito += venta['total'] as int;
    }

    final int totalAcumulado = totalEfectivo + totalDebito + totalCredito;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Detalle de Ventas del Turno', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cuadros de resumen
              Row(
                children: [
                  TarjetaResumenCaja(titulo: 'Efectivo', monto: totalEfectivo, color: Colors.green),
                  const SizedBox(width: 8),
                  TarjetaResumenCaja(titulo: 'Débito', monto: totalDebito, color: Colors.blue),
                  const SizedBox(width: 8),
                  TarjetaResumenCaja(titulo: 'Crédito', monto: totalCredito, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              Text('Total Ingresos: \$$totalAcumulado', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              const Divider(height: 32),
              const Text('Últimas Transacciones:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Lista de transacciones
              Expanded(
                child: _ventasDelDia.isEmpty
                    ? const Center(child: Text('No hay ventas registradas en este turno.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _ventasDelDia.length,
                        itemBuilder: (context, index) {
                          // Invertimos la lista para ver la más reciente arriba
                          final venta = _ventasDelDia[_ventasDelDia.length - 1 - index];
                          final hora = venta['hora'] as DateTime;
                          final String horaStr = "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}";
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                venta['metodo'] == 'Efectivo' ? Icons.payments : Icons.credit_card,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 18,
                              ),
                            ),
                            title: Text('${venta['documento']} - ${venta['metodo']}'),
                            subtitle: Text(horaStr),
                            trailing: Text('\$${venta['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarPago(bool esFactura) async {
    final String? metodoPago = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalPagoDialog(
        totalAPagar: _totalCompra,
        esFactura: esFactura, 
      ),
    );

    if (metodoPago != null) {
      String tipoDoc = esFactura ? "Factura" : "Boleta";
      print("Venta registrada. Documento: $tipoDoc | Método: $metodoPago");

      //Registramos la venta en nuestra lista temporal de ventas del día (aunque no se persista en la base de datos aún)
      _ventasDelDia.add({
        'hora': DateTime.now(),
        'documento': tipoDoc,
        'metodo': metodoPago,
        'total': _totalCompra,
      });

      setState(() {
        _carrito.clear();
        _clienteSeleccionado = null;
        _tipoPedido = null;
        _multiplicador = 1; 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta completada con éxito ($metodoPago)'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _intentarCobrarBoleta() async {
    if (_clienteSeleccionado != null) {
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 32),
              const SizedBox(width: 8),
              Text(
                '¿Emitir Boleta?',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ],
          ),
          content: const Text(
            'Tiene un Cliente Empresa asignado a esta venta.\n\n'
            '¿Está seguro de que el cliente desea una BOLETA y no una FACTURA?\n'
            '(Recuerde que este cambio es difícil de revertir en el SII).',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, emitir Boleta', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }
    _procesarPago(false); 
  }
// Venta manual: Procesa el carrito como un Vale Interno (sin valor tributario)
  Future<void> _procesarValeInterno() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío. Agregue productos primero.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final TextEditingController motivoCtrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emitir Vale Interno', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta operación descuenta el stock de los productos pero NO genera una Boleta ni Factura.', 
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoCtrl,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Motivo del Vale', 
                hintText: 'Ej: Fiado, Merma, Consumo personal...'
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), 
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.infoColor, // Usamos el color azul de info
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final motivo = motivoCtrl.text.trim();
              if (motivo.isNotEmpty) {
                Navigator.pop(context, motivo);
              }
            },
            child: const Text('Registrar Vale', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      // Aquí el sistema enviaría el registro a la base de datos (Tabla ComprobantesInternos)
      print("Vale Interno emitido. Total: $_totalCompra. Motivo: $result");

      setState(() {
        _carrito.clear();
        _clienteSeleccionado = null;
        _tipoPedido = null;
        _multiplicador = 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vale Interno registrado con éxito: $result'),
            backgroundColor: AppTheme.infoColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // NUEVA FUNCIÓN: Finaliza el turno y cierra la sesión del cajero
  Future<void> _cerrarCaja() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Obliga a elegir una opción
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_clock, color: AppTheme.errorColor, size: 32),
            const SizedBox(width: 8),
            Text('Cierre de Caja', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas cerrar la caja y finalizar tu turno?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiempo total del turno:'),
                  Text(
                    _tiempoTranscurrido,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Cerrar Caja', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // 1. Aquí iría la lógica de base de datos para guardar el turno
      print("Turno finalizado. Tiempo total: $_tiempoTranscurrido");

      // 2. Destruimos el temporizador para limpiar la memoria
      _timer?.cancel();

      // 3. Redirigimos al Login
      if (mounted) {
        context.go('/');
      }
    }
  }
  // Función Anular la venta completa
  Future<void> _anularVenta() async {
    // Si la caja ya está vacía, el botón no hace nada
    if (_carrito.isEmpty && _clienteSeleccionado == null && _tipoPedido == null) return;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppTheme.errorColor, size: 32),
            const SizedBox(width: 8),
            Text('¿Anular toda la venta?', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        content: const Text(
          'Se eliminarán todos los productos escaneados, el cliente asignado y la configuración del pedido.\n\n¿Estás seguro de que deseas limpiar la caja?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Anular Venta', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Si el cajero confirma, limpiamos todas las variables
    if (confirmar == true) {
      setState(() {
        _carrito.clear();
        _clienteSeleccionado = null;
        _tipoPedido = null;
        _multiplicador = 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta anulada y caja limpiada.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int get _totalCompra {
    int total = 0;
    _carrito.forEach((sku, cantidad) {
      final producto = _productosDisponibles.firstWhere((p) => p['sku'] == sku);
      total += (producto['precio'] as int) * cantidad;
    });
    if (_tipoPedido == 'despacho') {
      total += _tarifaDespachoFija;
    }
    return total;
  }

  @override
  void dispose() {
    _skuController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Image.asset(
          'assets/banner.png', 
          height: 80, // Limitamos la altura para que no desborde la barra superior
          fit: BoxFit.contain, 
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Row(
        children: [
          // LADO IZQUIERDO: Boleta Gigante y Buscador Principal
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CABECERA DE BÚSQUEDA
                  Row(
                    children: [
                      SizedBox(
                        height: 60,
                        child: Tooltip(
                          message: 'Cambiar cantidad a multiplicar',
                          waitDuration: const Duration(milliseconds: 500), 
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _multiplicador > 1 
                                  ? AppTheme.warningColor 
                                  : Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: _multiplicador > 1 
                                  ? Colors.white 
                                  : Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _configurarMultiplicador,
                            child: Text(
                              'x$_multiplicador',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: TextField(
                          controller: _skuController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 20),
                          decoration: InputDecoration(
                            labelText: 'Pistolear o Ingresar SKU',
                            hintText: 'Ej: 1, 2, 3...',
                            prefixIcon: const Icon(Icons.qr_code_scanner, size: 32),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.keyboard_return, color: Theme.of(context).colorScheme.primary),
                              onPressed: () => _buscarYAgregarPorSKU(_skuController.text),
                            ),
                          ),
                          onSubmitted: _buscarYAgregarPorSKU,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _abrirBuscadorAvanzado,
                          icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                          label: const Text('Buscar por Nombre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalle de la Transacción',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      // Agrupamos el Chip y el nuevo botón en un Row
                      Row(
                        children: [
                          if (_tipoPedido != null)
                            Chip(
                              backgroundColor: _tipoPedido == 'despacho' ? AppTheme.warningColor.withOpacity(0.2) : AppTheme.infoColor.withOpacity(0.2),
                              label: Text(
                                _tipoPedido == 'despacho' ? '🚚 DESPACHO' : '🛍️ RETIRO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _tipoPedido == 'despacho' ? AppTheme.warningColor : AppTheme.infoColor,
                                ),
                              ),
                              onDeleted: () => setState(() => _tipoPedido = null),
                            ),
                          
                          const SizedBox(width: 16),
                          
                          // Botón de Anular Venta
                          if (_carrito.isNotEmpty || _clienteSeleccionado != null)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: _anularVenta,
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Anular Venta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(thickness: 2),
                  
                  if (_carrito.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Cant.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Precio Unit.', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 48), 
                        ],
                      ),
                    ),
                  
                  if (_carrito.isNotEmpty) const SizedBox(height: 8),

                  Expanded(
                    child: _carrito.isEmpty
                        ? Center(
                            child: Text(
                              'Escanea un producto para comenzar',
                              style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.outline),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _carrito.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final sku = _carrito.keys.elementAt(index);
                              final cantidad = _carrito[sku]!;
                              final prod = _productosDisponibles.firstWhere((p) => p['sku'] == sku);
                              final subtotal = (prod['precio'] as int) * cantidad;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(prod['nombre'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          Text('SKU: ${prod['sku']}', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '$cantidad', 
                                        textAlign: TextAlign.center, 
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '\$${prod['precio']}', 
                                        textAlign: TextAlign.right, 
                                        style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant)
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '\$$subtotal', 
                                        textAlign: TextAlign.right, 
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                                      ),
                                    ),
                                    SizedBox(
                                      width: 48,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                          onPressed: () => _removerDelCarrito(sku),
                                          tooltip: 'Eliminar unidad',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  
                  if (_tipoPedido == 'despacho') ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_shipping, color: AppTheme.warningColor),
                      title: const Text('Costo de Envío Fijo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      trailing: Text('\$$_tarifaDespachoFija', style: const TextStyle(fontSize: 18)),
                    ),
                  ],

                  const Divider(thickness: 2),
                  Text(
                    'Total a Pagar: \$$_totalCompra',
                    style: TextStyle(
                      fontSize: 40, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),

          // LADO DERECHO: Panel de Control
          Container(
            width: 320, 
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_clienteSeleccionado == null) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppTheme.businessColor,
                      side: const BorderSide(color: AppTheme.businessColor),
                    ),
                    onPressed: _abrirBuscadorMayoristas,
                    icon: const Icon(Icons.business),
                    label: const Text('Asignar Venta Mayorista', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  Card(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.verified, color: AppTheme.warningColor, size: 20),
                                  SizedBox(width: 8),
                                  Text('CLIENTE EMPRESA', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _clienteSeleccionado = null;
                                    if (_tipoPedido == 'despacho') _tipoPedido = null;
                                  });
                                },
                                child:  Icon(Icons.close,color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.7), size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _clienteSeleccionado!['nombre'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text('RUT: ${_clienteSeleccionado!['rut']}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppTheme.warningColor,
                    side: const BorderSide(color: AppTheme.warningColor),
                  ),
                  onPressed: _configurarPedido,
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Programar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carrito.isEmpty ? null : _intentarCobrarBoleta, 
                  icon: const Icon(Icons.receipt, size: 28),
                  label: const Text('COBRAR BOLETA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                (_carrito.isNotEmpty && _clienteSeleccionado != null)
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24), 
                          backgroundColor: AppTheme.highlightColor, 
                          foregroundColor: Colors.white,
                          elevation: 6, 
                          shadowColor: AppTheme.highlightColor.withOpacity(0.5),
                        ),
                        onPressed: () => _procesarPago(true), 
                        icon: const Icon(Icons.receipt_long, size: 28),
                        label: const Text('EMITIR FACTURA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.grey, 
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: null, 
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('EMITIR FACTURA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppTheme.infoColor,
                    side: const BorderSide(color: AppTheme.infoColor),
                  ),
                  onPressed: _procesarValeInterno,
                  icon: const Icon(Icons.assignment), // Ícono de documento interno
                  label: const Text('VENTA MANUAL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed:_mostrarDetalleVentas,
                  icon: const Icon(Icons.assessment),
                  label: const Text('Detalle Venta del Día'),
                ),
                
                const Spacer(), 

                // TARJETA DE INFORMACIÓN DEL CAJERO
                if (_cajeroActual != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              radius: 20,
                              // Inicial del nombre
                              child: Text(_cajeroActual!.nombre[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _cajeroActual!.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'RUT: ${_cajeroActual!.rut}',
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tiempo de turno:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(
                              _tiempoTranscurrido,
                              style: TextStyle(
                                fontSize: 14, 
                                fontWeight: FontWeight.bold, 
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'monospace', // Para que los números no salten
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  onPressed: _cerrarCaja,
                  icon: const Icon(Icons.lock_clock),
                  label: const Text('Cierre de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGETS DE BÚSQUEDA

class _BuscadorProductosDialog extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  const _BuscadorProductosDialog({required this.productos});
  @override
  State<_BuscadorProductosDialog> createState() => _BuscadorProductosDialogState();
}

class _BuscadorProductosDialogState extends State<_BuscadorProductosDialog> {
  String _filtro = '';
  @override
  Widget build(BuildContext context) {
    final productosFiltrados = widget.productos.where((p) => p['nombre'].toString().toLowerCase().contains(_filtro.toLowerCase())).toList();
    return AlertDialog(
      title: Text('Buscar Producto', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500, height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Escribe el nombre del producto...', prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary)),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: productosFiltrados.length,
                itemBuilder: (context, index) {
                  final prod = productosFiltrados[index];
                  final bool sinStock = prod['stock'] == 0;
                  return ListTile(
                    title: Text(prod['nombre']),
                    subtitle: Text('SKU: ${prod['sku']} | Precio: \$${prod['precio']}'),
                    trailing: Text('Stock: ${prod['stock']}', style: TextStyle(color: sinStock ? AppTheme.errorColor : AppTheme.successColor, fontWeight: FontWeight.bold)),
                    enabled: !sinStock, 
                    onTap: () => Navigator.pop(context, prod),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cerrar', style: TextStyle(color: Theme.of(context).colorScheme.secondary)))],
    );
  }
}

class _BuscadorClientesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> clientes;
  const _BuscadorClientesDialog({required this.clientes});
  @override
  State<_BuscadorClientesDialog> createState() => _BuscadorClientesDialogState();
}

class _BuscadorClientesDialogState extends State<_BuscadorClientesDialog> {
  String _filtro = '';
  @override
  Widget build(BuildContext context) {
    final clientesFiltrados = widget.clientes.where((c) => c['nombre'].toString().toLowerCase().contains(_filtro.toLowerCase()) || c['rut'].toString().toLowerCase().contains(_filtro.toLowerCase())).toList();
    return AlertDialog(
      title: Text('Asignar Cliente Mayorista', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600, height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Buscar por Nombre o RUT...', prefixIcon: Icon(Icons.business, color: Theme.of(context).colorScheme.primary)),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: clientesFiltrados.length,
                itemBuilder: (context, index) {
                  final cliente = clientesFiltrados[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), child: Icon(Icons.domain, color: Theme.of(context).colorScheme.primary)),
                      title: Text(cliente['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('RUT: ${cliente['rut']} | Giro: ${cliente['giro']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pop(context, cliente),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.secondary)))],
    );
  }
}