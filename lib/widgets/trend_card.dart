import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/TimeSeriesData.dart';

class TrendCard extends StatelessWidget {
  final DateTime? trendStart;
  final DateTime? trendEnd;
  final Function(bool) onPickTrendDate;
  final VoidCallback onClear;

  const TrendCard({
    super.key,
    required this.trendStart,
    required this.trendEnd,
    required this.onPickTrendDate,
    required this.onClear,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Text(
              'Trend Over Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 10,
                  child: OutlinedButton(
                    onPressed: () => onPickTrendDate(true),
                    child: Text('Start: ${_formatDate(trendStart)}'),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 10,
                  child: OutlinedButton(
                    onPressed: () => onPickTrendDate(false),
                    child: Text('End: ${_formatDate(trendEnd)}'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
              ],
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getTrendOverTime(
                start: trendStart,
                end: trendEnd,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final data = snapshot.data!;
                if (data.isEmpty) {
                  return const Text('No trend data found.');
                }
                final chartData = data.map((row) {
                  final dayStr = row['day'] as String? ?? '';
                  final day = DateTime.tryParse(dayStr) ?? DateTime.now();
                  final cnt = int.tryParse(row['cnt'].toString()) ?? 0;
                  return TimeSeriesData(day, cnt);
                }).toList();

                final spots = <FlSpot>[];
                for (int i = 0; i < chartData.length; i++) {
                  spots
                      .add(FlSpot(i.toDouble(), chartData[i].count.toDouble()));
                }

                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= chartData.length) {
                                return const SizedBox();
                              }
                              final date = chartData[idx].day;
                              final label = DateFormat('MM-dd').format(date);
                              return Text(label,
                                  style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      minX: 0,
                      maxX: chartData.length.toDouble() - 1,
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: Colors.blue,
                          spots: spots,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
