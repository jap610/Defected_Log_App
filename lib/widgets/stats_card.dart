import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/MyPieChartData.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final Future<int> futureTotal;
  final Future<List<Map<String, dynamic>>> futureBreakdown;
  final Map<String, Color> categoryColors;

  const StatsCard({
    super.key,
    required this.title,
    required this.futureTotal,
    required this.futureBreakdown,
    required this.categoryColors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          height: MediaQuery.of(context).size.width / 4,
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<int>(
                future: futureTotal,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final total = snapshot.data ?? 0;
                  return Text('Total: $total',
                      style: const TextStyle(fontSize: 14));
                },
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: futureBreakdown,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return const Text('No data');
                    }
                    final seriesData = data.map((row) {
                      final type = row['defect_type'] as String? ?? 'Unknown';
                      final count = int.tryParse(row['cnt'].toString()) ?? 0;
                      return MyPieChartData(type, count);
                    }).toList();

                    return Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 10,
                          height: MediaQuery.of(context).size.width / 5,
                          child: PieChart(
                            PieChartData(
                              sections: seriesData.map((pie) {
                                return PieChartSectionData(
                                  title: '',
                                  value: pie.count.toDouble(),
                                  radius:
                                      MediaQuery.of(context).size.width / 12,
                                  color: categoryColors[pie.category] ??
                                      Colors.grey,
                                );
                              }).toList(),
                              centerSpaceRadius: 0,
                              sectionsSpace:
                                  MediaQuery.of(context).size.width / 400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: seriesData.map((pie) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width / 80,
                                  height:
                                      MediaQuery.of(context).size.width / 80,
                                  color: categoryColors[pie.category] ??
                                      Colors.grey,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width /
                                        150),
                                Text(
                                  '${pie.category} (${pie.count})',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
