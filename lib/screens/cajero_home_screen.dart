import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/modal_pago_dialog.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'dart:async';
import '../widgets/tarjeta_resumen_caja.dart';
import '../widgets/panel_control_cajero.dart';
import '../widgets/buscador_productos_dialog.dart';
import '../widgets/buscador_clientes_dialog.dart';
import '../widgets/modal_detalle_ventas.dart';
import '../data/mock_database.dart';
import '../utils/app_formatters.dart'; 
import '../utils/local_storage.dart';
import '../widgets/modal_turno_pendiente.dart';
import '../widgets/modal_cierre_caja.dart';

class CajeroHomeScreen extends StatefulWidget {
  const CajeroHomeScreen({super.key});

  @override
  State<CajeroHomeScreen> createState() => _CajeroHomeScreenState();
}

class _CajeroHomeScreenState extends State<CajeroHomeScreen> {
  late DateTime _horaInicioTurno;
  String? _turnoId;
  Timer? _timer;
  String _tiempoTranscurrido = "00:00:00";
  Empleado? _cajeroActual;

  List<Map<String, dynamic>> _productosDisponibles = [];
  List<Map<String, dynamic>> _clientesMayoristas = [];
  bool _cargandoDatos = true; 

  final TextEditingController _skuController = TextEditingController();
  
  final Map<int, double> _carrito = {};
  
  String _bufferEscaner = '';
  final FocusNode _focusNodeGlobal = FocusNode();
  final FocusNode _focusNodeTextField = FocusNode();

  Map<String, dynamic>? _clienteSeleccionado;
  String? _tipoPedido; 
  final int _tarifaDespachoFija = 3500;
  int _multiplicador = 1;

  @override
  void initState() {
    super.initState();
    _inicializarCaja();
    _focusNodeGlobal.requestFocus(); 
    _cargarDatosDeServidor();
  }

  Future<void> _cargarDatosDeServidor() async {
    try {
      final prods = await MockDatabase.instancia.obtenerProductos();
      final clients = await MockDatabase.instancia.obtenerClientes();
      setState(() {
        _productosDisponibles = prods;
        _clientesMayoristas = clients;
        _cargandoDatos = false;
      });
    } catch (e) {
      print("Error al cargar datos: $e");
    }
  }

  void _actualizarTiempoSesion() {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(_horaInicioTurno);

    String dosDigitos(int n) => n.toString().padLeft(2, "0");
    String horas = dosDigitos(diferencia.inHours);
    String minutos = dosDigitos(diferencia.inMinutes.remainder(60));
    String segundos = dosDigitos(diferencia.inSeconds.remainder(60));

    setState(() {
      _tiempoTranscurrido = "$horas:$minutos:$segundos";
    });
  }

  void _agregarAlCarrito(Map<String, dynamic> producto, {double cantidad = 1.0}) {
    setState(() {
      int sku = producto['sku'];
      num stockActual = producto['stock'] as num; 
      double cantidadEnCarrito = _carrito[sku] ?? 0.0;

      // Validación limpia usando la categoría de tu base de datos
      bool esGranel = producto['categoria'] == 'Panadería';

      if (cantidadEnCarrito + cantidad <= stockActual || esGranel) {
        _carrito[sku] = cantidadEnCarrito + cantidad;
        _multiplicador = 1; 

        if (cantidadEnCarrito + cantidad > stockActual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aviso: Vendiendo ${producto['nombre']} en negativo.'),
              backgroundColor: AppTheme.warningColor, 
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock insuficiente. Solo quedan $stockActual de ${producto['nombre']}.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      _sincronizarEstadoCarrito();
    });
  }

  void _removerDelCarrito(int sku) {
    setState(() {
      if (_carrito.containsKey(sku) && _carrito[sku]! > 1.0) {
        _carrito[sku] = _carrito[sku]! - 1.0;
      } else {
        _carrito.remove(sku);
      }
    });
    _sincronizarEstadoCarrito();
  }

  void _procesarCodigoEscaneado(String input) {
    if (input.isEmpty) return;
    input = input.trim();

    if (input.length == 13 && input.startsWith('20')) {

      String skuString = input.substring(2, 6); 
      String pesoGramosString = input.substring(6, 12); 

      int skuBuscado = int.parse(skuString); 
      double pesoEnKilos = int.parse(pesoGramosString) / 1000.0; 

      final index = _productosDisponibles.indexWhere((p) => p['sku'] == skuBuscado);
      if (index != -1) {
        _agregarAlCarrito(_productosDisponibles[index], cantidad: pesoEnKilos);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_productosDisponibles[index]['nombre']} pesado: $pesoEnKilos kg'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Producto de balanza no encontrado.'), backgroundColor: AppTheme.errorColor),
        );
      }
    } else {
      _buscarYAgregarPorSKU(input);
    }
    
    _skuController.clear();
  }

  void _buscarYAgregarPorSKU(String input) {
    final int? skuBuscado = int.tryParse(input);
    if (skuBuscado == null) return;

    final index = _productosDisponibles.indexWhere((p) => p['sku'] == skuBuscado);
    if (index != -1) {
      _agregarAlCarrito(_productosDisponibles[index], cantidad: _multiplicador.toDouble());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SKU $skuBuscado no encontrado en el sistema.')),
      );
    }
  }

  Future<void> _abrirBuscadorAvanzado() async {
    final Map<String, dynamic>? productoSeleccionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BuscadorProductosDialog(productos: _productosDisponibles),
    );
    if (productoSeleccionado != null) {
      _agregarAlCarrito(productoSeleccionado, cantidad: _multiplicador.toDouble());
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
      builder: (context) => BuscadorClientesDialog(clientes: _clientesMayoristas),
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

  Future<void> _mostrarDetalleVentas() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModalDetalleVentas(
        productosDisponibles: _productosDisponibles,
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
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await MockDatabase.instancia.registrarVenta(
        carrito: _carrito,
        total: _totalCompra,
        documento: tipoDoc,
        metodoPago: metodoPago,
        cliente: _clienteSeleccionado,
      );

      await _cargarDatosDeServidor();

      if (mounted) Navigator.pop(context); 

      setState(() {
        _carrito.clear();
        _clienteSeleccionado = null;
        _tipoPedido = null;
        _multiplicador = 1; 
        
      });

      _sincronizarEstadoCarrito();

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
              backgroundColor: AppTheme.infoColor, 
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await MockDatabase.instancia.registrarValeInterno(_carrito, result);
      await _cargarDatosDeServidor(); 

      if (mounted) Navigator.pop(context); 

      setState(() {
        _carrito.clear();
        _clienteSeleccionado = null;
        _tipoPedido = null;
        _multiplicador = 1;
      });

      _sincronizarEstadoCarrito();

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

Future<void> _cerrarCaja() async {
    // Invocamos el nuevo modal limpio
    final bool? confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false, 
      builder: (context) => ModalCierreCaja(
        tiempoTranscurrido: _tiempoTranscurrido,
      ),
    );

    // Mantenemos intacta la lógica de cierre original
    if (confirmar == true) {
      _timer?.cancel();

      if (_turnoId != null) {
        await MockDatabase.instancia.cerrarTurno(_turnoId!); 
      }

      if (mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _anularVenta() async {
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
      total += ((producto['precio'] as num) * cantidad).round();
    });
    if (_tipoPedido == 'despacho') {
      total += _tarifaDespachoFija;
    }
    return total;
  }

Future<void> _inicializarCaja() async {
    // 0. Leemos la RAM al inicio por si el login acaba de ocurrir
    _cajeroActual = AuthService().currentUser;

    // 1. Cargamos productos y clientes para poder renderizar
    await _cargarDatosDeServidor();

    // 2. Revisamos si hay una sesión guardada físicamente en el equipo
    final sesionLocal = await LocalStorage.obtenerSesionCaja();

    if (sesionLocal != null) {
      if (!mounted) return;
      
      // LLAMADA LIMPIA AL NUEVO WIDGET
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false, 
        builder: (context) => ModalTurnoPendiente(
          horaInicio: sesionLocal['horaInicio'],
          cantidadProductos: (sesionLocal['carrito'] as Map).length,
        ),
      );

      // Evaluamos la decisión del cajero
      if (result == 'REANUDAR') {
        setState(() {
          _turnoId = sesionLocal['turnoId'];
          _horaInicioTurno = sesionLocal['horaInicio'];
          
      // ¡RESTAURAMOS AL CAJERO CON TU MODELO REAL!
      _cajeroActual ??= Cajero(
        id: sesionLocal['cajeroId'] ?? 'EMP-DEFAULT',
        nombre: sesionLocal['cajeroNombre'] ?? 'Cajero',
        rut: sesionLocal['cajeroRut'] ?? '', // Campo requerido por la clase Empleado
        rol: 'Cajero', // Usamos 'tipo' en lugar de 'rol' según tu modelo
        idLocal: sesionLocal['idLocal'] ?? 1, password: '', // ¡El ID del local que nos faltaba!
      );
          
          final Map<int, double> carritoGuardado = sesionLocal['carrito'];
          if (carritoGuardado.isNotEmpty) {
            _carrito.addAll(carritoGuardado);
          }
        });
        _iniciarContadorTiempo();
        
      } else if (result == 'CERRAR_ANTIGUO') {
        await MockDatabase.instancia.cerrarTurno(sesionLocal['turnoId']);
        await LocalStorage.borrarSesionCaja();
        
        final String empleadoId = _cajeroActual?.id ?? 'EMP-DEFAULT';
        await _abrirNuevoTurno(empleadoId);
      }
      
    } else {
      final String empleadoId = _cajeroActual?.id ?? 'EMP-DEFAULT';
      await _abrirNuevoTurno(empleadoId);
    }
  }

  Future<void> _abrirNuevoTurno(String empleadoId) async {
    final nuevoId = await MockDatabase.instancia.abrirTurno(empleadoId);
    setState(() {
      _turnoId = nuevoId;
      _horaInicioTurno = DateTime.now();
    });
    _iniciarContadorTiempo();
  }

  void _iniciarContadorTiempo() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _actualizarTiempoSesion();
    });
  }

void _sincronizarEstadoCarrito() {
    if (_turnoId != null) {
      MockDatabase.instancia.sincronizarCarrito(_turnoId!, _carrito);
      
      LocalStorage.guardarSesionCaja(
        turnoId: _turnoId!,
        horaInicio: _horaInicioTurno,
        carrito: _carrito,
        cajeroId: _cajeroActual?.id ?? 'EMP-DEFAULT',
        cajeroNombre: _cajeroActual?.nombre ?? 'Cajero Desconocido',
        cajeroRut: _cajeroActual?.rut ?? '',
        idLocal: (_cajeroActual is Cajero) ? (_cajeroActual as Cajero).idLocal : 1, 
      );
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _focusNodeGlobal.dispose();
    _focusNodeTextField.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme; 

    if (_cargandoDatos) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando terminal de venta...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

      return KeyboardListener(
        focusNode: _focusNodeGlobal,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          // SI EL USUARIO ESTÁ ESCRIBIENDO EN EL TEXTFIELD, IGNORAMOS EL BUFFER GLOBAL
          if (_focusNodeTextField.hasFocus) return; 

          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (_bufferEscaner.isNotEmpty) {
                _procesarCodigoEscaneado(_bufferEscaner);
                _bufferEscaner = ''; 
              }
            } else if (event.character != null) {
              _bufferEscaner += event.character!;
            }
          }
        },
        child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: Image.asset(
            'assets/banner.png', 
            height: 80, 
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
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                    : colorScheme.primaryContainer,
                                foregroundColor: _multiplicador > 1 
                                    ? Colors.white 
                                    : colorScheme.primary,
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
                            focusNode: _focusNodeTextField,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 20),
                            decoration: InputDecoration(
                              labelText: 'Pistolear o Ingresar SKU',
                              hintText: 'Ej: 1, 2, 3...',
                              prefixIcon: const Icon(Icons.qr_code_scanner, size: 32),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.keyboard_return, color: colorScheme.primary),
                                onPressed: () => _procesarCodigoEscaneado(_skuController.text),
                              ),
                            ),
                            onSubmitted: _procesarCodigoEscaneado,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 60,
                          child: OutlinedButton.icon(
                            onPressed: _abrirBuscadorAvanzado,
                            icon: Icon(Icons.search, color: colorScheme.primary),
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
                            color: colorScheme.secondary,
                          ),
                        ),
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
                            
                            if (_carrito.isNotEmpty || _clienteSeleccionado != null)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onPressed: _anularVenta,
                                icon: const Icon(Icons.delete_sweep),
                                label: const Text('Anular Total Venta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          color: colorScheme.surfaceVariant, // Respetando el tema
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
                                style: TextStyle(fontSize: 20, color: colorScheme.outline), 
                              ),
                            )
                          : ListView.separated(
                              itemCount: _carrito.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final sku = _carrito.keys.elementAt(index);
                                final cantidad = _carrito[sku]!;
                                final prod = _productosDisponibles.firstWhere((p) => p['sku'] == sku);
                                
                                final int subtotal = ((prod['precio'] as num) * cantidad).round();
                                // 1. Determinamos si el producto se vende por peso
                                // (Puedes ajustar esta validación según cómo diferencies tus productos en la BD)
                                final bool esGranel = prod['categoria'] == 'Panadería'; 

                                String cantAVisualizar;

                                // 2. Si es a granel o si la cantidad detecta decimales (ej: 0.5)
                                if (esGranel || cantidad.truncateToDouble() != cantidad) {
                                  // Forzamos 3 decimales, cambiamos el punto por coma y agregamos " kg"

                                  cantAVisualizar = '${cantidad.toStringAsFixed(3).replaceAll('.', ',')} kg';
                                } else {
                                  // Si es un producto unitario (ej: una bebida), lo mostramos entero. 
                                  // Opcionalmente puedes agregarle " un" al final: '${cantidad.toInt()} un'
                                  cantAVisualizar = '${cantidad.toInt()} un';}
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
                                            Text('SKU: ${prod['sku']}', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          cantAVisualizar, 
                                          textAlign: TextAlign.center, 
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          // Se aplica AppFormatters.formatearDinero al precio unitario
                                          '\$${AppFormatters.formatearDinero((prod['precio'] as num).round())}', 
                                          textAlign: TextAlign.right, 
                                          style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          // Se aplica AppFormatters.formatearDinero al subtotal
                                          '\$${AppFormatters.formatearDinero(subtotal)}', 
                                          textAlign: TextAlign.right, 
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface) 
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
                        // Se aplica AppFormatters.formatearDinero a la tarifa de despacho
                        trailing: Text('\$${AppFormatters.formatearDinero(_tarifaDespachoFija)}', style: const TextStyle(fontSize: 18)),
                      ),
                    ],
  
                    const Divider(thickness: 2),
                    Text(
                      // Se aplica AppFormatters.formatearDinero al total de la compra
                      'Total a Pagar: \$${AppFormatters.formatearDinero(_totalCompra)}',
                      style: TextStyle(
                        fontSize: 40, 
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
  
            PanelControlCajero(
              clienteSeleccionado: _clienteSeleccionado,
              tipoPedido: _tipoPedido,
              carritoVacio: _carrito.isEmpty,
              cajeroActual: _cajeroActual,
              tiempoTranscurrido: _tiempoTranscurrido,
              onAsignarMayorista: _abrirBuscadorMayoristas,
              onConfigurarPedido: _configurarPedido,
              onCobrarBoleta: _intentarCobrarBoleta,
              onEmitirFactura: () => _procesarPago(true),
              onEmitirValeInterno: _procesarValeInterno,
              onVerDetalleVenta: _mostrarDetalleVentas,
              onCierreCaja: _cerrarCaja,
              onQuitarCliente: () {
                setState(() {
                  _clienteSeleccionado = null;
                  if (_tipoPedido == 'despacho') _tipoPedido = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}