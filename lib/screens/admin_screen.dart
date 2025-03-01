import 'package:flutter/material.dart';
import '../database/admin_helper.dart';
import '../database/database_helper.dart';

class AdminScreen extends StatefulWidget {
  final String currentAdminUsername;

  const AdminScreen({Key? key, required this.currentAdminUsername})
      : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminHelper _adminHelper = AdminHelper();

  List<Map<String, dynamic>> _defectTypes = [];
  String _selectedDefectType = '';
  final TextEditingController _addDefectTypeController =
      TextEditingController();
  final TextEditingController _renameDefectTypeController =
      TextEditingController();

  List<Map<String, dynamic>> _users = [];
  String _selectedUsername = '';
  // String _newRole = '';

  @override
  void initState() {
    super.initState();
    _loadDefectTypes();
    _loadUsers();
  }

  Future<void> _loadDefectTypes() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('defect_types');
    setState(() {
      _defectTypes = result;
      // Clear selection if it's invalid
      if (!_defectTypes
          .any((type) => type['defect_name'] == _selectedDefectType)) {
        _selectedDefectType = '';
      }
    });
  }

  Future<void> _addDefectType() async {
    final defectName = _addDefectTypeController.text.trim();
    if (defectName.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    try {
      await db.insert('defect_types', {'defect_name': defectName});
      _addDefectTypeController.clear();
      await _loadDefectTypes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding defect type: $e')),
      );
    }
  }

  Future<void> _renameDefectType() async {
    if (_selectedDefectType.isEmpty) return;
    final newName = _renameDefectTypeController.text.trim();
    if (newName.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Check old type
      final oldType = await txn.query('defect_types',
          where: 'defect_name = ?', whereArgs: [_selectedDefectType]);
      if (oldType.isEmpty) {
        throw Exception('Defect type $_selectedDefectType does not exist.');
      }

      final newType = await txn.query('defect_types',
          where: 'defect_name = ?', whereArgs: [newName]);
      if (newType.isNotEmpty) {
        throw Exception('Defect type $newName already exists.');
      }

      await txn.update(
        'defect_types',
        {'defect_name': newName},
        where: 'defect_name = ?',
        whereArgs: [_selectedDefectType],
      );

      await txn.update(
        'defects',
        {'defect_type': newName},
        where: 'defect_type = ?',
        whereArgs: [_selectedDefectType],
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error renaming: $error')),
      );
    });

    _renameDefectTypeController.clear();
    await _loadDefectTypes();
  }

  Future<void> _deleteDefectType() async {
    if (_selectedDefectType.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Defect Type'),
        content:
            Text('Are you sure you want to delete "$_selectedDefectType"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final db = await DatabaseHelper.instance.database;

    final inUse = await db.query(
      'defects',
      where: 'defect_type = ?',
      whereArgs: [_selectedDefectType],
      limit: 1,
    );
    if (inUse.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Cannot delete "$_selectedDefectType": In use.')),
      );
      return;
    }
    await db.delete(
      'defect_types',
      where: 'defect_name = ?',
      whereArgs: [_selectedDefectType],
    );

    setState(() {
      _selectedDefectType = '';
    });
    await _loadDefectTypes();
  }

  Future<void> _loadUsers() async {
    final users = await _adminHelper.getAllUsers();
    setState(() {
      _users = users;
      if (!_users.any((user) => user['user_name'] == _selectedUsername)) {
        _selectedUsername = '';
      }
    });
  }

  Future<void> _removeUser() async {
    if (_selectedUsername.isEmpty) return;

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove User'),
        content: Text('Are you sure you want to remove $_selectedUsername?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldRemove != true) return;

    final success = await _adminHelper.removeUser(
      _selectedUsername,
      widget.currentAdminUsername,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove user $_selectedUsername')),
      );
    }

    setState(() {
      _selectedUsername = '';
    });
    await _loadUsers();
  }

  Future<void> _changeUserRole(String username, String newRole) async {
    final success = await _adminHelper.updateUserRole(username, newRole);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role for $username')),
      );
    }
    await _loadUsers();
  }

  Future<void> _showAddUserDialog() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    String selectedRole = 'operator'; // default role

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedRole,
                  items: <String>['admin', 'engineer', 'operator']
                      .map<DropdownMenuItem<String>>((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      selectedRole = value;
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
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();

                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter username and password.'),
                    ),
                  );
                  return;
                }

                final success = await DatabaseHelper.instance
                    .addUser(username, password, selectedRole);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('User $username created successfully.')),
                  );
                  await _loadUsers();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed: $username already exists.')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Defect Types',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _defectTypes.length,
                    itemBuilder: (context, index) {
                      final defect = _defectTypes[index];
                      final name = defect['defect_name'] as String;
                      return ListTile(
                        title: Text(name),
                        selected: name == _selectedDefectType,
                        onTap: () {
                          setState(() {
                            _selectedDefectType = name;
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _addDefectTypeController,
                    decoration: const InputDecoration(
                      labelText: 'New Defect Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addDefectType,
                  child: const Text('Add Defect Type'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _renameDefectTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Rename Selected Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _renameDefectType,
                  child: const Text('Rename Defect Type'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _deleteDefectType,
                  child: const Text('Delete Defect Type'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          VerticalDivider(
            color: Colors.grey,
            thickness: 1,
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'User Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final username = user['user_name'];
                      final userType = user['user_type'];
                      return ListTile(
                        title: Text('$username ($userType)'),
                        selected: username == _selectedUsername,
                        onTap: () {
                          setState(() {
                            _selectedUsername = username;
                          });
                        },
                        trailing: DropdownButton<String>(
                          value: userType,
                          items: <String>['manger', 'engineer', 'operator']
                              .map<DropdownMenuItem<String>>((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null && newValue != userType) {
                              _changeUserRole(username, newValue);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _showAddUserDialog,
                  child: const Text('+ Add User'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _removeUser,
                  child: const Text('Remove Selected User'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addDefectTypeController.dispose();
    _renameDefectTypeController.dispose();
    super.dispose();
  }
}
