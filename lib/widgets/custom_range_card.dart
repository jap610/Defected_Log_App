import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/MyPieChartData.dart';
// If needed

class CustomRangeCard extends StatelessWidget {
  final DateTime? customStart;
  final DateTime? customEnd;
  final Function(bool) onPickDate; 
  final VoidCallback onClear; 
  final Map<String, Color> categoryColors;

  const CustomRangeCard({
    super.key,
    required this.customStart,
    required this.customEnd,
    required this.onPickDate,
    required this.onClear,
    required this.categoryColors,
  });

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
              'Custom Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.width / 200,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 10,
                  child: OutlinedButton(
                    onPressed: () => onPickDate(true),
                    child: Text('Start: ${_formatDate(customStart)}'),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 10,
                  child: OutlinedButton(
                    onPressed: () => onPickDate(false),
                    child: Text('End: ${_formatDate(customEnd)}'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (customStart != null && customEnd != null)
              _buildCustomRangeContent(context, customStart!, customEnd!)
            else
              const Text('Select Start and End dates above.'),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRangeContent(
      BuildContext context, DateTime startDate, DateTime endDate) {
    return Column(
      children: [
        const Text(
          'Selected Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        FutureBuilder<int>(
          future: DatabaseHelper.instance
              .getTotalCount(start: startDate, end: endDate),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final total = snapshot.data ?? 0;
            return Text('Total: $total', style: const TextStyle(fontSize: 14));
          },
        ),
        const SizedBox(height: 6),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getCategoryBreakdown(
            start: startDate,
            end: endDate,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final data = snapshot.data!;
            if (data.isEmpty) {
              return const Text('No data');
            }
            // Convert DB rows -> MyPieChartData
            final seriesData = data.map((row) {
              final type = row['defect_type'] as String? ?? 'Unknown';
              final count = int.tryParse(row['cnt'].toString()) ?? 0;
              return MyPieChartData(type, count);
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;
                final spacing = cardWidth * 0.009;
                final pieRadius = cardWidth * 0.2;

                return Column(
                  children: [
                    SizedBox(
                      height: cardWidth * 0.4,
                      child: PieChart(
                        PieChartData(
                          sections: seriesData.map((pie) {
                            return PieChartSectionData(
                              title: '',
                              value: pie.count.toDouble(),
                              radius: pieRadius,
                              color:
                                  categoryColors[pie.category] ?? Colors.grey,
                            );
                          }).toList(),
                          centerSpaceRadius: 0,
                          sectionsSpace: spacing,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: spacing / 2,
                      children: seriesData.map((pie) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: cardWidth * 0.04,
                              height: cardWidth * 0.04,
                              color:
                                  categoryColors[pie.category] ?? Colors.grey,
                            ),
                            SizedBox(width: spacing / 2),
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
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}
