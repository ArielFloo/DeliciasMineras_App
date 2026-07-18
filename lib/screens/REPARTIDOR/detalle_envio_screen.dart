import 'package:flutter/material.dart';

class DetalleEnvioScreen extends StatefulWidget {
  // En el futuro, pasarás el objeto EnvioAsignado completo
  final Map<String, dynamic> envio; 

  const DetalleEnvioScreen({super.key, required this.envio});

  @override
  State<DetalleEnvioScreen> createState() => _DetalleEnvioScreenState();
}

class _DetalleEnvioScreenState extends State<DetalleEnvioScreen> {
  bool _enCamino = false;

  void _iniciarRecorrido() {
    setState(() => _enCamino = true);
    
    // TODO: Aquí irá la notificación/UPDATE a Supabase para avisar al cliente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ruta iniciada. Cliente notificado exitosamente.'),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmarEntrega() {
    // TODO: Aquí irá el UPDATE a la base de datos (Hito 2: Cambiar estado del envío)
    Navigator.pop(context, true); // Retornamos 'true' para avisar que se entregó y sacarlo de la lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.envio['razonSocial'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Tarjeta de Información de Entrega
                _buildInfoCard(),
                const SizedBox(height: 20),
                
                // Sección de Documento Asociado (Factura / Boleta)
                _buildDocumentoCard(),
                const SizedBox(height: 24),
                
                // Desglose de Carga
                const Text(
                  'Desglose de la Carga',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                _buildDetalleCarga(),
              ],
            ),
          ),
          
          // Barra de Acción Inferior Estacionaria
          _buildActionBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.envio['direccionEntrega'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text('Estimado: ${widget.envio['horaEstimada']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
              Text(
                widget.envio['precioFormateado'],
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Factura Electrónica', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text('N° 440912 - Asociada al pedido', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.visibility_rounded, color: Colors.blue.shade700),
            onPressed: () {
              // Simulación de visualización
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abriendo visor de PDF de la factura...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleCarga() {
    // Datos simulados del desglose
    final productos = [
      {'cant': '20x', 'name': 'Pan de Molde Integral'},
      {'cant': '5x', 'name': 'Torta Amor (15 porciones)'},
      {'cant': '12x', 'name': 'Medialunas Caseras'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: productos.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) => ListTile(
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
            child: Text(productos[index]['cant']!, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
          ),
          title: Text(productos[index]['name']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildActionBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _enCamino ? _confirmarEntrega : _iniciarRecorrido,
            style: ElevatedButton.styleFrom(
              backgroundColor: _enCamino ? Colors.green.shade600 : const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_enCamino ? Icons.check_circle : Icons.local_shipping),
                const SizedBox(width: 10),
                Text(
                  _enCamino ? 'CONFIRMAR ENTREGA' : 'INICIAR RECORRIDO',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}