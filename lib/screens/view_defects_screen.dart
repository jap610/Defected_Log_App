import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/defect_item.dart';
import 'package:intl/intl.dart'; // For formatting dates

class ViewDefectsScreen extends StatefulWidget {
  const ViewDefectsScreen({super.key});

  @override
  ViewDefectsScreenState createState() => ViewDefectsScreenState();
}

class ViewDefectsScreenState extends State<ViewDefectsScreen> {
  // Master list of all defects from the DB
  List<DefectItem> _allDefects = [];
  // Filtered list to display
  List<DefectItem> _filteredDefects = [];

  // Existing doc search
  final TextEditingController _searchController = TextEditingController();

  // Created By filter
  // We'll populate _allCreators from the data, plus an "All" option
  List<String> _allCreators = ['All'];
  String _selectedCreator = 'All';

  // Defect Type filter
  // Add "All" to your existing defect types
  final List<String> _defectTypes = [
    'All',
    'Poor punching quality',
    'CLIPID lens position',
    'Defected chip',
    'CLIPID lens defects',
  ];
  String _selectedDefectType = 'All';

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadDefects();
    _searchController.addListener(() => setState(() => _applyFilters()));
  }

  void _loadDefects() async {
    try {
      final defectsData = await DatabaseHelper.instance.getAllDefects();
      final items = defectsData.map((data) {
        // fallback handling
        final createdByVal = data['created_by'] ?? 'Unknown';
        final timestampVal = data['timestamp'] ??
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
        return DefectItem(
          defectType: data['defect_type'] ?? 'N/A',
          documentNumber: data['document_number'] ?? 'N/A',
          timestamp: DateTime.tryParse(timestampVal) ?? DateTime.now(),
          createdBy: createdByVal,
        );
      }).toList();

      setState(() {
        _allDefects = items;
        final creatorsSet = {'All'};
        creatorsSet.addAll(_allDefects.map((item) => item.createdBy));
        _allCreators = creatorsSet.toList();
        _allCreators.sort();

        _filteredDefects = _allDefects;
      });
    } catch (e) {
      debugPrint('Error loading defects: $e');
      setState(() {
        _allDefects = [];
        _filteredDefects = [];
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    List<DefectItem> filtered = _allDefects.where((defect) {
      final matchDoc = defect.documentNumber.toLowerCase().contains(query);

      final matchCreatedBy = _selectedCreator == 'All'
          ? true
          : defect.createdBy == _selectedCreator;

      final matchDefectType = _selectedDefectType == 'All'
          ? true
          : defect.defectType == _selectedDefectType;

      final matchStart = (_startDate == null) ||
          defect.timestamp
              .isAfter(_startDate!.subtract(const Duration(days: 1)));
      final matchEnd = (_endDate == null) ||
          defect.timestamp.isBefore(_endDate!.add(const Duration(days: 1)));

      return matchDoc &&
          matchCreatedBy &&
          matchDefectType &&
          matchStart &&
          matchEnd;
    }).toList();

    setState(() {
      _filteredDefects = filtered;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (_startDate ?? initialDate) : (_endDate ?? initialDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      setState(() {
        if (isStart) {
          _startDate = newDate;
        } else {
          _endDate = newDate;
        }
        _applyFilters();
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _applyFilters();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Defects'),
      ),
      body: Column(
        children: [
          // Document Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Document Number',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCreator,
                    items: _allCreators.map((creator) {
                      return DropdownMenuItem<String>(
                        value: creator,
                        child: Text(creator),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCreator = value;
                          _applyFilters();
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Created By'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDefectType,
                    items: _defectTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDefectType = value;
                          _applyFilters();
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Defect Type'),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text('Start: ${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text('End: ${_formatDate(_endDate)}'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateRange,
                  tooltip: 'Clear Date Range',
                ),
              ],
            ),
          ),

          Expanded(
            child: _filteredDefects.isEmpty
                ? const Center(child: Text('No defects found.'))
                : ListView.builder(
                    itemCount: _filteredDefects.length,
                    itemBuilder: (context, index) {
                      final defect = _filteredDefects[index];
                      return Card(
                          margin: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2), // smaller margin
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                  width: MediaQuery.of(context).size.width / 7,
                                  alignment: Alignment.center,
                                  child: Text(defect.documentNumber)),
                              Container(
                                  width: MediaQuery.of(context).size.width / 7,
                                  alignment: Alignment.center,
                                  child: Text(defect.defectType)),
                              Container(
                                  width: MediaQuery.of(context).size.width / 4,
                                  alignment: Alignment.center,
                                  child: Text('${defect.timestamp}')),
                              Container(
                                  width: MediaQuery.of(context).size.width / 7,
                                  alignment: Alignment.center,
                                  child: Text(defect.createdBy))
                            ],
                          ));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
