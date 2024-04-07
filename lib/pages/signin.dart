import 'package:flutter/material.dart';
import 'package:vehicle/pages/admin.dart';
import 'package:vehicle/pages/homescreen.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Sample user data
  static const List<Map<String, dynamic>> users = [
    {'id': 'student', 'password': 'student123', 'role': 'student'},
    {'id': 'admin', 'password': 'admin123', 'role': 'admin'},
  ];

  // Variables to store user input
  String studentId = '';
  String password = '';

  // Variable to control password visibility
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                studentId = value.trim();
              },
            ),
            const SizedBox(height: 10.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              onChanged: (value) {
                password = value.trim();
              },
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                // Find the user in the sample data
                var user = users.firstWhere(
                  (user) =>
                      user['id'] == studentId.trim() &&
                      user['password'] == password.trim(),
                  orElse: () => {'id': '', 'password': '', 'role': ''},
                );

                // Navigate to the appropriate page based on the user's role
                if (user['role'] == 'student') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                } else if (user['role'] == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPage()),
                  );
                } else {
                  // Show an error message if the user is not found
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid ID or Password')),
                  );
                }
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                // TODO: Implement forgot password functionality
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
