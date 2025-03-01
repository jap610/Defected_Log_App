import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DefectItem {
  final int? id;
  String defectType;
  String documentNumber;
  DateTime timestamp;
  String createdBy;

  DefectItem({
    this.id,
    required this.defectType,
    required this.documentNumber,
    required this.timestamp,
    required this.createdBy,
  });
}

class EditDefectsScreen extends StatefulWidget {
  final String currentUserName;

  const EditDefectsScreen({
    Key? key,
    required this.currentUserName,
  }) : super(key: key);

  @override
  _EditDefectsScreenState createState() => _EditDefectsScreenState();
}

class _EditDefectsScreenState extends State<EditDefectsScreen> {
  List<DefectItem> _userDefects = [];
  List<String> _defectTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDefects();
    _loadDefectTypes();
  }

  Future<void> _loadUserDefects() async {
    setState(() => _isLoading = true);
    try {
      final userDefectsData = await DatabaseHelper.instance
          .getDefectsByUser(widget.currentUserName);
      final userDefects = userDefectsData.map((row) {
        return DefectItem(
          id: row['id'] as int?,
          defectType: row['defect_type'] ?? 'N/A',
          documentNumber: row['document_number'] ?? 'N/A',
          timestamp:
              DateTime.tryParse(row['timestamp'] ?? '') ?? DateTime.now(),
          createdBy: row['created_by'] ?? widget.currentUserName,
        );
      }).toList();
      setState(() {
        _userDefects = userDefects;
      });
    } catch (e) {
      debugPrint('Error loading user defects: $e');
      setState(() {
        _userDefects = [];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadDefectTypes() async {
    try {
      final results = await DatabaseHelper.instance.getAllDefectTypes();
      final types = results.map((row) => row['defect_name'] as String).toList();
      setState(() {
        _defectTypes = types;
      });
    } catch (e) {
      debugPrint('Error loading defect types: $e');
    }
  }

  Future<void> _showEditDialog(DefectItem defect) async {
    String tempDocNumber = defect.documentNumber;
    String tempDefectType = defect.defectType;
    final docController = TextEditingController(text: tempDocNumber);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Defect'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: docController,
                  decoration: const InputDecoration(
                    labelText: 'Document Number',
                  ),
                  maxLength: 9,
                  onChanged: (value) {
                    tempDocNumber = value.trim();
                  },
                ),
                const SizedBox(height: 10),
                if (_defectTypes.isEmpty)
                  const Text('No defect types available in DB.')
                else
                  DropdownButton<String>(
                    value: tempDefectType,
                    items: _defectTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newVal) {
                      if (newVal != null) {
                        setState(() {
                          tempDefectType = newVal;
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_isValidDocNumber(tempDocNumber)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid document number.')),
                  );
                  return;
                }
                final updatedTime = DateTime.now();
                try {
                  if (defect.id != null) {
                    final rowsAffected =
                        await DatabaseHelper.instance.updateDefect(
                      defect.id!,
                      tempDocNumber,
                      tempDefectType,
                      updatedTime,
                    );
                    if (rowsAffected == 1) {
                      await _loadUserDefects();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Defect updated successfully!')),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Error: Defect not updated.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Error: Defect ID is missing.')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error updating defect: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating defect: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDefect(DefectItem defect) async {
    if (defect.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Defect ID is missing.')),
      );
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Defect'),
        content:
            Text('Are you sure you want to delete "${defect.documentNumber}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      try {
        final rowsDeleted =
            await DatabaseHelper.instance.deleteDefect(defect.id!);
        if (rowsDeleted == 1) {
          setState(() {
            _userDefects.remove(defect);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Defect deleted successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Defect not deleted.')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting defect: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting defect: $e')),
        );
      }
    }
  }

  bool _isValidDocNumber(String docNumber) {
    if (docNumber.length != 9) return false;
    final firstChar = docNumber[0];
    if (!RegExp(r'^[A-Za-z]$').hasMatch(firstChar)) {
      return false;
    }
    final digits = docNumber.substring(1);
    if (!RegExp(r'^[0-9]{8}$').hasMatch(digits)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit My Defects (${widget.currentUserName})'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userDefects.isEmpty
              ? const Center(child: Text('No defects found for you.'))
              : ListView.builder(
                  itemCount: _userDefects.length,
                  itemBuilder: (context, index) {
                    final defect = _userDefects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(defect),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deleteDefect(defect),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
