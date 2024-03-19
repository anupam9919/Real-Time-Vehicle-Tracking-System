import 'package:flutter/material.dart';
import 'package:vehicle/screen/admin_page.dart';
import 'package:vehicle/screen/homepage.dart';
import 'package:vehicle/screen/student_page.dart';
// Import the admin page

class SignInPage extends StatelessWidget {
  // Sample user data
  static const List<Map<String, dynamic>> users = [
    {'id': 'student', 'password': 'student123', 'role': 'student'},
    {'id': 'admin', 'password': 'admin123', 'role': 'admin'},
  ];

  @override
  Widget build(BuildContext context) {
    // Variables to store user input
    String studentId = '';
    String password = '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                studentId = value;
              },
            ),
            SizedBox(height: 10.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) {
                password = value;
              },
            ),
            SizedBox(height: 10.0),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                } else if (user['role'] == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AdminPage()),
                  );
                } else {
                  // Show an error message if the user is not found
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid Student ID or Password')),
                  );
                }
              },
              child: Text('Login'),
            ),
            SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                // TODO: Implement forgot password functionality
              },
              child: Text(
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
