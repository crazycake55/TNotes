import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'tea.dart';

class TeaStatsPage extends StatelessWidget {
  final List<Tea> teas;

  const TeaStatsPage({super.key, required this.teas});

  @override
  Widget build(BuildContext context) {
    final typeCounts = <String, int>{};
    final yearCounts = <String, int>{};
    final descriptorCounts = <String, int>{};

    for (var tea in teas) {
      typeCounts[tea.type] = (typeCounts[tea.type] ?? 0) + 1;
      yearCounts[tea.year] = (yearCounts[tea.year] ?? 0) + 1;
      for (var desc in tea.descriptors) {
        final d = desc.trim();
        descriptorCounts[d] = (descriptorCounts[d] ?? 0) + 1;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tea Collection Statistics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Teas by type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 200, child: PieChart(_buildPieData(typeCounts))),

            const SizedBox(height: 24),
            const Text("Teas by years", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 200, child: BarChart(_buildBarData(yearCounts))),

            const SizedBox(height: 24),
            const Text("Popularity of descriptors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 250, child: BarChart(_buildBarData(descriptorCounts, rotateLabels: true))),
          ],
        ),
      ),
    );
  }

  PieChartData _buildPieData(Map<String, int> data) {
    final total = data.values.fold(0, (a, b) => a + b);
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.cyan];

    return PieChartData(
      sections: data.entries.mapIndexed((i, entry) {
        return PieChartSectionData(
          color: colors[i % colors.length],
          value: entry.value.toDouble(),
          title: '${entry.key} (${(entry.value / total * 100).toStringAsFixed(1)}%)',
          titleStyle: const TextStyle(fontSize: 12),
        );
      }).toList(),
    );
  }

  BarChartData _buildBarData(Map<String, int> data, {bool rotateLabels = false}) {
    final keys = data.keys.toList();
    final values = data.values.toList();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: List.generate(keys.length, (i) {
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: values[i].toDouble(),
            color: Color(0xFFCD1C0E),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ]);
      }),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < keys.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 25,
                  child: rotateLabels
                      ? SizedBox(
                    width: 40,
                    child: Transform.rotate(
                      angle: -1.5708,
                      alignment: Alignment.center,
                      child: Text(
                        keys[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                      : Text(
                    keys[index],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: false),
    );
  }
}

extension MapIndex<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int i, T e) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}
