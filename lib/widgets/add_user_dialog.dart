import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart'; 


void showAddUserDialog(BuildContext context) {
  final TextEditingController adminPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Admin Authentication'),
        content: TextField(
          controller: adminPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter Admin Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
             
              if (adminPasswordController.text == adminFixedPassword) {
                Navigator.pop(dialogContext); 
                _showUserForm(context);        
              } else {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect admin password!')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}


void _showUserForm(BuildContext context) {
  final newUsernameController = TextEditingController();
  final newPasswordController = TextEditingController();
  String selectedUserType = 'operator';

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Add New User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newUsernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                DropdownButton<String>(
                  value: selectedUserType,
                  items: ['operator', 'engineer', 'manager']
                      .map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserType = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  // Basic validation
                  if (newUsernameController.text.isEmpty ||
                      newPasswordController.text.isEmpty) {
                    return;
                  }

                  final success = await DatabaseHelper.instance.addUser(
                    newUsernameController.text,
                    newPasswordController.text,
                    selectedUserType,
                  );

                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'User added successfully!'
                            : 'Username already exists!',
                      ),
                    ),
                  );
                },
                child: const Text('Add User'),
              ),
            ],
          );
        },
      );
    },
  );
}
