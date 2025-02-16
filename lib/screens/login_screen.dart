import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../screens/dashboard_screen.dart';
import '../widgets/add_user_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    usernameController.clear();
    passwordController.clear();
  }

  void _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Please enter both username and password.');
      return;
    }

    final user = await DatabaseHelper.instance.getUser(username, password);

    if (user != null) {
      _showMessage('Login successful!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userName: user['user_name'],
            userType: user['user_type'],
          ),
        ),
      );
    } else {
      _showMessage('Invalid username or password.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'lib/assets/background.jpg',
            fit: BoxFit.scaleDown,
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.width / 15,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    child: TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    child: TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Login button
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 10),
                  // Add user button
                  TextButton(
                    onPressed: () => showAddUserDialog(context),
                    child: const Text('Add User'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
