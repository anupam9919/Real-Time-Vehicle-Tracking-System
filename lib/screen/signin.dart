import 'package:flutter/material.dart';
import 'package:vehicle/screen/admin.dart';
import 'package:vehicle/screen/homescreen.dart';

class SignInPage extends StatelessWidget {
  // Sample user data
  static const List<Map<String, dynamic>> users = [
    {'id': 'student', 'password': 'student123', 'role': 'student'},
    {'id': 'admin', 'password': 'admin123', 'role': 'admin'},
  ];

  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Variables to store user input
    String studentId = '';
    String password = '';
    String vehicleNumber = '';

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
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                studentId = value;
              },
            ),
            const SizedBox(height: 10.0),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) {
                password = value;
              },
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                // Find the user in the sample data
                var user = users.firstWhere(
                  (user) =>
                      user['id'] == studentId && user['password'] == password,
                  orElse: () => {'id': '', 'password': '', 'role': ''},
                );

                // Navigate to the appropriate page based on the user's role
                if (user['role'] == 'student') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Enter Vehicle Number'),
                      content: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          vehicleNumber = value;
                        },
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                            );
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  );
                } else if (user['role'] == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AdminPage()),
                  );
                } else {
                  // Show an error message if the user is not found
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid Student ID or Password')),
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
