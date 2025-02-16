import 'package:flutter/material.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../models/defect_item.dart';

class AddDefectScreen extends StatefulWidget {
  final String userName;

  const AddDefectScreen({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  State<AddDefectScreen> createState() => _AddDefectScreenState();
}

class _AddDefectScreenState extends State<AddDefectScreen> {
  final List<String> _defectTypes = [
    'Poor punching quality',
    'CLIPID lens position',
    'Defected chip',
    'CLIPID lens defects',
  ];

  String _selectedDefectType = 'CLIPID lens position';

  final TextEditingController _docController = TextEditingController();

  // Temporary list of defects
  final List<DefectItem> _defectList = [];

  // Focus node to track user input
  final FocusNode _docFocusNode = FocusNode();
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());

    _docController.addListener(() {
      _onDocNumberChanged(_docController.text);
    });
  }

  @override
  void dispose() {
    _docController.dispose();
    _docFocusNode.dispose();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = _formatTime(DateTime.now());
    });
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:";
  }

  void _onDocNumberChanged(String currentText) {
    if (currentText.isEmpty) return;

    if (currentText.length == 1) {
      String first = currentText[0].toUpperCase();
      _docController.value = TextEditingValue(
        text: first,
        selection: TextSelection.collapsed(offset: 1),
      );
      return;
    }

    if (currentText.length == 9) {
      if (_isValidDocNumber(currentText)) {
        bool isDuplicate =
            _defectList.any((item) => item.documentNumber == currentText);
        if (isDuplicate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Document $currentText is already in the list!')),
          );
          _docController.clear();
          return;
        }

        _addDefectItem(currentText);
        _docController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Invalid document number! Must be Letter+8 digits.')),
        );
        _docController.clear();
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

  void _addDefectItem(String docNumber) {
    final newItem = DefectItem(
      defectType: _selectedDefectType,
      documentNumber: docNumber,
      timestamp: DateTime.now(),
      createdBy: widget.userName,
    );
    setState(() {
      _defectList.add(newItem);
    });
  }

  void _deleteDefectItem(DefectItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content:
            Text('Are you sure you want to remove ${item.documentNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _defectList.remove(item);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _clearList() {
    if (_defectList.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Entries'),
        content: const Text('Are you sure you want to clear the entire list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _defectList.clear();
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDefects() async {
    if (_defectList.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No defects to save!')));
      return;
    }

    try {
      final defectsToSave =
          _defectList.map((defect) => defect.toMap()).toList();
      await DatabaseHelper.instance.saveDefects(defectsToSave);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Defects saved successfully!')));
      setState(() {
        _defectList.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving defects: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Defects - ${widget.userName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _currentTime,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Defect Type:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<String>(
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
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 50,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Documents in list: ${_defectList.length}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            TextField(
              controller: _docController,
              focusNode: _docFocusNode,
              decoration: const InputDecoration(
                labelText: 'Document Number',
                hintText: 'Format: A12345678',
              ),
              keyboardType: TextInputType.text,
              maxLength: 9,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _defectList.length,
                itemBuilder: (context, index) {
                  final defect = _defectList[index];
                  return ListTile(
                    title:
                        Text('${defect.documentNumber} - ${defect.defectType}'),
                    subtitle: Text(
                        'Timestamp: ${defect.timestamp}\nCreated By: ${defect.createdBy}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDefectItem(defect),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _clearList,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Clear List'),
                ),
                ElevatedButton(
                  onPressed: _saveDefects,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
