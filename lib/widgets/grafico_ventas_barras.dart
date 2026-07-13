import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/mock_database.dart';
import '../utils/app_formatters.dart';

class GraficoVentasBarras extends StatefulWidget {
  const GraficoVentasBarras({super.key});

  @override
  State<GraficoVentasBarras> createState() => _GraficoVentasBarrasState();
}

class _GraficoVentasBarrasState extends State<GraficoVentasBarras> {
  bool _cargando = true;
  String _filtroSeleccionado = 'Semana'; // 'Semana', 'Mes', 'Año'
  DateTime _fechaReferencia = DateTime.now(); // Controla en qué momento del tiempo estamos
  
  List<double> _boletas = [];
  List<double> _facturas = [];
  List<String> _etiquetas = [];
  double _maximoY = 10000;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Desplaza la fecha de referencia hacia el pasado o el futuro
  void _cambiarPeriodo(int direccion) {
    setState(() {
      if (_filtroSeleccionado == 'Semana') {
        _fechaReferencia = _fechaReferencia.add(Duration(days: 7 * direccion));
      } else if (_filtroSeleccionado == 'Mes') {
        _fechaReferencia = DateTime(_fechaReferencia.year, _fechaReferencia.month + direccion, 1);
      } else if (_filtroSeleccionado == 'Año') {
        _fechaReferencia = DateTime(_fechaReferencia.year + direccion, 1, 1);
      }
    });
    _cargarDatos();
  }

  // Genera el texto que va entre las flechas (ej: "Julio 2026")
  String _obtenerTextoPeriodo() {
    if (_filtroSeleccionado == 'Semana') {
      DateTime lunes = _fechaReferencia.subtract(Duration(days: _fechaReferencia.weekday - 1));
      DateTime domingo = lunes.add(const Duration(days: 6));
      return "${lunes.day}/${lunes.month} - ${domingo.day}/${domingo.month} / ${lunes.year}";
    } else if (_filtroSeleccionado == 'Mes') {
      const meses = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
      return "${meses[_fechaReferencia.month - 1]} ${_fechaReferencia.year}";
    } else {
      return "${_fechaReferencia.year}";
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final ventas = await MockDatabase.instancia.obtenerVentasDelDia(); // Actúa como historial de todas las ventas

    int numBarras = 0;
    List<double> tempBoletas = [];
    List<double> tempFacturas = [];
    List<String> tempEtiquetas = [];
    double maxValor = 0;

    // LÓGICA DE AGRUPACIÓN TEMPORAL (Viajando en el tiempo)
    if (_filtroSeleccionado == 'Semana') {
      numBarras = 7;
      tempBoletas = List.filled(numBarras, 0.0);
      tempFacturas = List.filled(numBarras, 0.0);
      tempEtiquetas = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];

      // Calculamos el lunes de la semana que estamos viendo
      DateTime lunes = _fechaReferencia.subtract(Duration(days: _fechaReferencia.weekday - 1));

      for (var v in ventas) {
        DateTime f = v['hora'];
        // Si la venta está en el rango de los 7 días desde ese lunes
        int diferenciaDias = f.difference(DateTime(lunes.year, lunes.month, lunes.day)).inDays;
        if (diferenciaDias >= 0 && diferenciaDias < 7) {
          v['documento'] == 'Factura' ? tempFacturas[diferenciaDias] += v['total'] : tempBoletas[diferenciaDias] += v['total'];
        }
      }
    } 
    else if (_filtroSeleccionado == 'Mes') {
      // Agrupamos en 4 bloques (Semanas del mes)
      numBarras = 4;
      tempBoletas = List.filled(numBarras, 0.0);
      tempFacturas = List.filled(numBarras, 0.0);
      tempEtiquetas = ["Sem 1", "Sem 2", "Sem 3", "Sem 4"];

      for (var v in ventas) {
        DateTime f = v['hora'];
        if (f.year == _fechaReferencia.year && f.month == _fechaReferencia.month) {
          int bloqueSemana = (f.day - 1) ~/ 7;
          if (bloqueSemana > 3) bloqueSemana = 3; // Los días 29, 30 y 31 se suman a la última semana
          v['documento'] == 'Factura' ? tempFacturas[bloqueSemana] += v['total'] : tempBoletas[bloqueSemana] += v['total'];
        }
      }
    } 
    else if (_filtroSeleccionado == 'Año') {
      // Agrupamos por los 12 meses
      numBarras = 12;
      tempBoletas = List.filled(numBarras, 0.0);
      tempFacturas = List.filled(numBarras, 0.0);
      tempEtiquetas = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];

      for (var v in ventas) {
        DateTime f = v['hora'];
        if (f.year == _fechaReferencia.year) {
          int indiceMes = f.month - 1;
          v['documento'] == 'Factura' ? tempFacturas[indiceMes] += v['total'] : tempBoletas[indiceMes] += v['total'];
        }
      }
    }

    // Calcular el techo del gráfico dinámicamente
    for (int i = 0; i < numBarras; i++) {
      if (tempBoletas[i] + tempFacturas[i] > maxValor) {
        maxValor = tempBoletas[i] + tempFacturas[i];
      }
    }

    if (mounted) {
      setState(() {
        _boletas = tempBoletas;
        _facturas = tempFacturas;
        _etiquetas = tempEtiquetas;
        _maximoY = maxValor > 0 ? maxValor * 1.2 : 10000;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==========================================
        // CABECERA MODERNA CON NAVEGADOR
        // ==========================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppTheme.adminCardInfo,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Título Dinámico
              Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Historial de Ventas - ${_filtroSeleccionado.toUpperCase()}', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ],
              ),
              
              // 2. Controles de Tiempo y Filtro
              Row(
                children: [
                  // NAVEGADOR DE FECHAS (Flechas)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () => _cambiarPeriodo(-1),
                        tooltip: 'Anterior',
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          _obtenerTextoPeriodo(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () => _cambiarPeriodo(1),
                        tooltip: 'Siguiente',
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // SEGMENTED CONTROL (Reemplazo del Dropdown)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: ['Semana', 'Mes', 'Año'].map((filtro) {
                        bool activo = _filtroSeleccionado == filtro;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _filtroSeleccionado = filtro;
                              _fechaReferencia = DateTime.now(); // Al cambiar filtro, volvemos al presente
                            });
                            _cargarDatos();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: activo ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: activo 
                                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] 
                                : [],
                            ),
                            child: Text(
                              filtro, 
                              style: TextStyle(
                                color: activo ? AppTheme.adminCardInfo : Colors.white,
                                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ==========================================
        // ÁREA DEL GRÁFICO
        // ==========================================
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: _cargando 
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _IndicadorLeyenda(color: AppTheme.primaryColor, texto: 'Boletas'),
                        const SizedBox(width: 16),
                        _IndicadorLeyenda(color: AppTheme.infoColor, texto: 'Facturas'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _maximoY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => colorScheme.secondary,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '\$${AppFormatters.formatearDinero(rod.toY.toInt())}',
                                TextStyle(color: colorScheme.onSecondary, fontWeight: FontWeight.bold),
                              );
                            },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < _etiquetas.length) {
                                    return Text(_etiquetas[index], style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  if (value == _maximoY) return const SizedBox.shrink();
                                  String texto = value >= 1000 
                                      ? '${(value / 1000).toStringAsFixed(0)}k' 
                                      : value.toInt().toString();
                                  return Text('\$$texto', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: colorScheme.outlineVariant.withOpacity(0.5),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(_etiquetas.length, (index) {
                            return _crearGrupoBarra(index, _boletas[index], _facturas[index]);
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _crearGrupoBarra(int x, double boletas, double facturas) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: boletas + facturas,
          width: _filtroSeleccionado == 'Año' ? 16 : 35, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          rodStackItems: [
            BarChartRodStackItem(0, boletas, AppTheme.primaryColor),
            BarChartRodStackItem(boletas, boletas + facturas, AppTheme.infoColor),
          ],
        ),
      ],
    );
  }
}

class _IndicadorLeyenda extends StatelessWidget {
  final Color color;
  final String texto;
  const _IndicadorLeyenda({required this.color, required this.texto});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}