import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../../domain/entities/entities.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(metricsHistoryProvider);

    return Scaffold(
      // AppBar handled by MainScaffold
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('No hay registros disponibles.'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    'Evolución de Peso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                Container(
                  height: 300,
                  padding: const EdgeInsets.only(
                    right: 24,
                    left: 12,
                    top: 24,
                    bottom: 12,
                  ),
                  child: _buildWeightChart(history),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'Registros Detallados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                _buildHistoryTable(context, history),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildWeightChart(List<BodyMetrics> history) {
    // Sort history chronologically (oldest first) for the chart
    final reversedHistory = history.reversed.toList();

    // Create spots
    final spots =
        reversedHistory.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.weight);
        }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1);
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
                if (index < 0 || index >= reversedHistory.length)
                  return const Text('');
                // Show dates only for some points to avoid overcrowding if many
                if (reversedHistory.length > 7 && index % 2 != 0)
                  return const Text('');

                final date = reversedHistory[index].createdAt;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (reversedHistory.length - 1).toDouble(),
        // Add some buffer to Y axis
        minY:
            (reversedHistory
                        .map((e) => e.weight)
                        .reduce((a, b) => a < b ? a : b) -
                    2)
                .floorToDouble(),
        maxY:
            (reversedHistory
                        .map((e) => e.weight)
                        .reduce((a, b) => a > b ? a : b) +
                    2)
                .ceilToDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.green,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final index = touchedSpot.x.toInt();
                final data = reversedHistory[index];
                return LineTooltipItem(
                  '${DateFormat('dd/MM').format(data.createdAt)}\n${data.weight} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context, List<BodyMetrics> history) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.green.withOpacity(0.1),
          ),
          columnSpacing: 25,
          border: TableBorder.all(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Fecha',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Peso',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Variación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('IMC', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: _generateRows(history),
        ),
      ),
    );
  }

  List<DataRow> _generateRows(List<BodyMetrics> history) {
    // history is already sorted descending
    return List.generate(history.length, (index) {
      final current = history[index];

      String variationText = '--';
      Color variationColor = Colors.grey;
      IconData? variationIcon;

      if (index + 1 < history.length) {
        final previous = history[index + 1];
        final diff = current.weight - previous.weight;

        if (diff > 0) {
          variationText = '+${diff.toStringAsFixed(1)} kg';
          variationColor = Colors.redAccent;
          variationIcon = Icons.arrow_upward;
        } else if (diff < 0) {
          variationText = '${diff.toStringAsFixed(1)} kg';
          variationColor = Colors.green;
          variationIcon = Icons.arrow_downward;
        } else {
          variationText = '0.0 kg';
          variationColor = Colors.grey;
          variationIcon = Icons.remove;
        }
      }

      return DataRow(
        cells: [
          DataCell(Text(DateFormat('dd/MM/yyyy').format(current.createdAt))),
          DataCell(
            Text(
              '${current.weight.toStringAsFixed(1)} kg',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          DataCell(
            Row(
              children: [
                if (variationIcon != null)
                  Icon(variationIcon, size: 16, color: variationColor),
                const SizedBox(width: 4),
                Text(
                  variationText,
                  style: TextStyle(
                    color: variationColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          DataCell(_buildBmiBadge(current.bmi)),
        ],
      );
    });
  }

  Widget _buildBmiBadge(double bmi) {
    Color color;

    if (bmi < 18.5) {
      color = Colors.blue;
    } else if (bmi < 25) {
      color = Colors.green;
    } else if (bmi < 30) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '${bmi.toStringAsFixed(1)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
