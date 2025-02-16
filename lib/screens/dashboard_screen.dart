import 'package:flutter/material.dart';
import 'package:defected_log_app/route_observer.dart';
import '../database/database_helper.dart';
import 'add_defect_screen.dart';
import 'view_defects_screen.dart';
import '../widgets/stats_card.dart';
import '../widgets/custom_range_card.dart';
import '../widgets/trend_card.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userType;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userType,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  DateTime? _customStart;
  DateTime? _customEnd;
  DateTime? _trendStart;
  DateTime? _trendEnd;

  final Map<String, Color> categoryColors = {
    'Poor punching quality': Colors.red,
    'CLIPID lens position': Colors.green,
    'Defected chip': Colors.blue,
    'CLIPID lens defects': Colors.orange,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
        this, ModalRoute.of(context)! as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshDashboard();
  }

  void _refreshDashboard() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            padding:
                EdgeInsets.only(right: MediaQuery.of(context).size.width / 50),
            child: Column(
              children: [
                const SizedBox(width: 30),
                Text('Welcome, ${widget.userName}!',
                    style: const TextStyle(fontSize: 20)),
                Text('Your role: ${widget.userType}'),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddDefectScreen(userName: widget.userName),
                        ),
                      );
                    },
                    child: const Text('Add Defect'),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 50),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ViewDefectsScreen(),
                        ),
                      );
                    },
                    child: const Text('View Defects'),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 50),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Log Out'),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 50),
                ],
              ),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: [
                StatsCard(
                  title: 'All-Time',
                  futureTotal: DatabaseHelper.instance.getTotalCount(),
                  futureBreakdown:
                      DatabaseHelper.instance.getCategoryBreakdown(),
                  categoryColors: categoryColors,
                ),
                StatsCard(
                  title: 'Last Month',
                  futureTotal: DatabaseHelper.instance.getTotalCount(
                    start: DateTime.now().subtract(const Duration(days: 30)),
                    end: DateTime.now(),
                  ),
                  futureBreakdown: DatabaseHelper.instance.getCategoryBreakdown(
                    start: DateTime.now().subtract(const Duration(days: 30)),
                    end: DateTime.now(),
                  ),
                  categoryColors: categoryColors,
                ),
                StatsCard(
                  title: 'Last Week',
                  futureTotal: DatabaseHelper.instance.getTotalCount(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
                  futureBreakdown: DatabaseHelper.instance.getCategoryBreakdown(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
                  categoryColors: categoryColors,
                ),
                CustomRangeCard(
                  customStart: _customStart,
                  customEnd: _customEnd,
                  categoryColors: categoryColors,
                  onPickDate: (isStart) => _pickCustomDate(isStart),
                  onClear: () {
                    setState(() {
                      _customStart = null;
                      _customEnd = null;
                    });
                  },
                ),
                TrendCard(
                  trendStart: _trendStart,
                  trendEnd: _trendEnd,
                  onPickTrendDate: (isStart) => _pickTrendDate(isStart),
                  onClear: () {
                    setState(() {
                      _trendStart = null;
                      _trendEnd = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDate(bool isStart) async {
    final initialDate = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (_customStart ?? initialDate) : (_customEnd ?? initialDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (chosen != null) {
      setState(() {
        if (isStart) {
          _customStart = chosen;
        } else {
          _customEnd = chosen;
        }
      });
    }
  }

  Future<void> _pickTrendDate(bool isStart) async {
    final initialDate = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (_trendStart ?? initialDate) : (_trendEnd ?? initialDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (chosen != null) {
      setState(() {
        if (isStart) {
          _trendStart = chosen;
        } else {
          _trendEnd = chosen;
        }
      });
    }
  }
}
