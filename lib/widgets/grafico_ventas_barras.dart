import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class GraficoVentasBarras extends StatelessWidget {
  const GraficoVentasBarras({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 140, // Límite vertical basado en tu diseño de referencia
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => colorScheme.secondary,
            tooltipBorder: BorderSide(color: colorScheme.outlineVariant, width: 1),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\$${rod.toY}',
                TextStyle(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
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
                // Mapeo de días del mes o etiquetas para el eje X
                switch (value.toInt()) {
                  case 0: return const Text('01-11');
                  case 1: return const Text('01-12');
                  case 2: return const Text('01-13');
                  case 3: return const Text('01-14');
                  case 4: return const Text('01-15');
                  default: return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) => value % 20 == 0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          // Cada grupo representa una barra. Las alturas emulan las de tu referencia.
          _crearGrupoBarra(0, 65, 69, colorScheme),
          _crearGrupoBarra(1, 17, 17, colorScheme),
          _crearGrupoBarra(2, 16, 16, colorScheme),
          _crearGrupoBarra(3, 5, 5, colorScheme),
          _crearGrupoBarra(4, 65, 20, colorScheme),
        ],
      ),
    );
  }

  BarChartGroupData _crearGrupoBarra(int x, double y1, double y2, ColorScheme colorScheme) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1 + y2,
          color: AppTheme.adminCardWarning, // Color centralizado de Ventas
          width: 35,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          rodStackItems: [
            BarChartRodStackItem(0, y1, AppTheme.primaryColor), // Segmento inferior (Naranja panadería)
            BarChartRodStackItem(y1, y1 + y2, AppTheme.infoColor), // Segmento superior (Azul info)
          ],
        ),
      ],
    );
  }
}