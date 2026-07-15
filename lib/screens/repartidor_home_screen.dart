import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/envio.dart';

class RepartidorHomeScreen extends StatefulWidget {
  const RepartidorHomeScreen({super.key});

  @override
  State<RepartidorHomeScreen> createState() => _RepartidorHomeScreenState();
}

class _RepartidorHomeScreenState extends State<RepartidorHomeScreen> {
  bool _cargando = true;
  String? _error;
  List<EnvioAsignado> _envios = [];

  @override
  void initState() {
    super.initState();
    _cargarEnvios();
  }

  Future<void> _cargarEnvios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _fetchEnviosAsignados();
      if (!mounted) return;
      setState(() {
        _envios = resultado;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los envíos. Intenta nuevamente.';
        _cargando = false;
      });
    }
  }

  /// TODO: reemplazar esta simulación por la llamada real al backend/BD que
  /// ejecuta la consulta compleja documentada al final del archivo, filtrando
  /// por el id del repartidor autenticado.
  Future<List<EnvioAsignado>> _fetchEnviosAsignados() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      EnvioAsignado(
        idEnvio: 1042,
        nombreCliente: 'Javiera Contreras',
        direccionEntrega: 'Av. Libertador 1450, Depto 302, Santiago',
        horaEstimada: '11:30',
        precioDespacho: 3500,
      ),
      EnvioAsignado(
        idEnvio: 1043,
        nombreCliente: 'Comercial Rivas Ltda.',
        direccionEntrega: 'Los Aromos 220, Ñuñoa',
        horaEstimada: '12:15',
        precioDespacho: 4200,
      ),
      EnvioAsignado(
        idEnvio: 1045,
        nombreCliente: 'Matías Fuentes',
        direccionEntrega: 'Pasaje El Roble 88, La Florida',
        horaEstimada: '13:00',
        precioDespacho: 2900,
      ),
    ];
  }

  void _marcarComoEntregado(EnvioAsignado envio) {
    // TODO: aquí iría el UPDATE real (cerrar el Envio y, por ejemplo, liberar
    // el Vehiculo poniendo Disponibilidad = 'desocupado').
    setState(() {
      _envios = _envios.where((e) => e.idEnvio != envio.idEnvio).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Envío #${envio.idEnvio} marcado como entregado')),
    );
  }

  String _formatCLP(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '\$$buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo de Despachos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envíos Programados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _cargarEnvios,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_envios.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarEnvios,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            Icon(Icons.local_shipping, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes entregas pendientes por ahora.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEnvios,
      child: ListView.separated(
        itemCount: _envios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _EnvioCard(
          envio: _envios[index],
          precioFormateado: _formatCLP(_envios[index].precioDespacho),
          onEntregado: () => _marcarComoEntregado(_envios[index]),
        ),
      ),
    );
  }
}

class _EnvioCard extends StatelessWidget {
  const _EnvioCard({
    required this.envio,
    required this.precioFormateado,
    required this.onEntregado,
  });

  final EnvioAsignado envio;
  final String precioFormateado;
  final VoidCallback onEntregado;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.location_on, color: Colors.blueGrey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    envio.nombreCliente,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    envio.direccionEntrega,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(envio.horaEstimada, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.payments, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(precioFormateado, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Marcar como entregado',
              onPressed: onEntregado,
            ),
          ],
        ),
      ),
    );
  }
}

/*
Consulta SQL de referencia — cruza el modelo relacional para obtener los
envíos asignados al vehículo que conduce el repartidor autenticado.
Ajusta nombres de tablas/columnas a tu DDL real.

SELECT e.id_envio,
       cl.nombre           AS nombre_cliente,
       be.direccion,
       be.hora_estimada,
       be.precio_despacho
FROM   Repartidor   r
JOIN   Conduce      c  ON c.id_repartidor = r.id_repartidor
JOIN   Vehiculo     v  ON v.patente = c.patente
JOIN   Despacha     d  ON d.patente = v.patente
JOIN   Envio        e  ON e.id_envio = d.id_envio
JOIN   Boleta_envio be ON be.id_envio = e.id_envio
JOIN   Recibe       rc ON rc.id_envio = e.id_envio
JOIN   Cliente      cl ON cl.rut = rc.rut
WHERE  r.id_repartidor = :idRepartidor;
*/