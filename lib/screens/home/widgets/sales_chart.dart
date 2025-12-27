import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/dashboard_provider.dart';

/// Widget de gráfico de vendas por dia
class SalesChart extends StatelessWidget {
  final List<VendaDia> dados;
  final bool mostrarLucro;

  const SalesChart({
    super.key,
    required this.dados,
    this.mostrarLucro = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dados.length) {
                    return const Text('');
                  }
                  final data = dados[index].data;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormatter.formatShortDate(data),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: _calculateInterval(),
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  return Text(
                    _formatValue(value),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey[300]!),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          minX: 0,
          maxX: dados.length.toDouble() - 1,
          minY: 0,
          maxY: _calculateMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: _generateSpots(),
              isCurved: true,
              gradient: LinearGradient(
                colors: mostrarLucro
                    ? [Colors.green[400]!, Colors.green[700]!]
                    : [Colors.blue[400]!, Colors.blue[700]!],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: mostrarLucro ? Colors.green : Colors.blue,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: mostrarLucro
                      ? [
                          Colors.green[200]!.withValues(alpha: 0.3),
                          Colors.green[200]!.withValues(alpha: 0.0),
                        ]
                      : [
                          Colors.blue[200]!.withValues(alpha: 0.3),
                          Colors.blue[200]!.withValues(alpha: 0.0),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.grey[800]!,
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  if (index < 0 || index >= dados.length) {
                    return null;
                  }
                  final venda = dados[index];
                  final valor =
                      mostrarLucro ? venda.lucro : venda.valorTotal;

                  return LineTooltipItem(
                    '${DateFormatter.formatDate(venda.data)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${mostrarLucro ? "Lucro" : "Vendas"}: ${CurrencyFormatter.format(valor)}\n',
                      ),
                      TextSpan(
                        text: '${venda.quantidadeVendas} vendas',
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return List.generate(dados.length, (index) {
      final valor =
          mostrarLucro ? dados[index].lucro : dados[index].valorTotal;
      return FlSpot(index.toDouble(), valor);
    });
  }

  double _calculateMaxY() {
    if (dados.isEmpty) return 100;

    final valores = dados
        .map((d) => mostrarLucro ? d.lucro : d.valorTotal)
        .toList();
    final maxValue = valores.reduce((a, b) => a > b ? a : b);

    // Adiciona 20% de margem no topo
    return maxValue * 1.2;
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY < 100) return 20;
    if (maxY < 500) return 100;
    if (maxY < 1000) return 200;
    if (maxY < 5000) return 1000;
    return 2000;
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$ ${value.toInt()}';
  }
}
