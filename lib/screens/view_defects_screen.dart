import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../database/database_helper.dart';
import '../models/defect_item.dart';
import '../utils/pdf_export_helper.dart';

class ViewDefectsScreen extends StatefulWidget {
  const ViewDefectsScreen({Key? key}) : super(key: key);

  @override
  ViewDefectsScreenState createState() => ViewDefectsScreenState();
}

class ViewDefectsScreenState extends State<ViewDefectsScreen> {

  List<DefectItem> _allDefects = [];
  List<DefectItem> _filteredDefects = [];


  final TextEditingController _searchController = TextEditingController();
  List<String> _allCreators = ['All'];
  String _selectedCreator = 'All';


  List<String> _defectTypes = [];
  String _selectedDefectType = 'All';

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadDefects();
    _loadDefectTypes();  
    _searchController.addListener(() => setState(() => _applyFilters()));
  }


  void _loadDefects() async {
    try {
      final defectsData = await DatabaseHelper.instance.getAllDefects();
      final items = defectsData.map((data) {
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
        _allCreators = creatorsSet.toList()..sort();

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

 
  Future<void> _loadDefectTypes() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query('defect_types');

      final typesFromDB =
          results.map<String>((row) => row['defect_name'].toString()).toList();

      typesFromDB.insert(0, 'All');

      setState(() {
        _defectTypes = typesFromDB;
        _selectedDefectType = 'All'; 
      });
    } catch (e) {
      debugPrint('Error loading defect types: $e');
      setState(() {
        _defectTypes = ['All'];
        _selectedDefectType = 'All';
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allDefects.where((defect) {
      final matchDoc = defect.documentNumber.toLowerCase().contains(query);

      final matchCreatedBy = (_selectedCreator == 'All')
          ? true
          : (defect.createdBy == _selectedCreator);

      final matchDefectType = (_selectedDefectType == 'All')
          ? true
          : (defect.defectType == _selectedDefectType);

      final matchStart = (_startDate == null) ||
          defect.timestamp.isAfter(_startDate!.subtract(const Duration(days: 1)));
      final matchEnd = (_endDate == null) ||
          defect.timestamp.isBefore(_endDate!.add(const Duration(days: 1)));

      return matchDoc && matchCreatedBy && matchDefectType && matchStart && matchEnd;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export as PDF',
            onPressed: () async {
              try {
                // Load logo
                final logoData = await rootBundle.load('lib/assets/veridos-logo.png');
                final logoBytes = logoData.buffer.asUint8List();

                final filePath = await generateAndSaveDefectsPDF(
                  _filteredDefects,
                  _defectTypes,
                  logoBytes,
                );

                final result = await OpenFile.open(filePath);
                debugPrint('OpenFile result: $result');
              } catch (e) {
                debugPrint('Error generating PDF: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to generate PDF: $e'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
    
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
                // Creator Filter
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width / 7,
                              alignment: Alignment.center,
                              child: Text(defect.documentNumber),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width / 7,
                              alignment: Alignment.center,
                              child: Text(defect.defectType),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width / 4,
                              alignment: Alignment.center,
                              child: Text('${defect.timestamp}'),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width / 7,
                              alignment: Alignment.center,
                              child: Text(defect.createdBy),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
