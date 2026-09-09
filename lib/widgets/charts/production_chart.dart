import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProductionChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;

  const ProductionChart({
    super.key,
    required this.data,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: data
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(toY: e.value, color: Colors.blue),
                    ],
                  ))
              .toList(),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
