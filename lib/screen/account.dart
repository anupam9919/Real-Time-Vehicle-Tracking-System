import 'package:flutter/material.dart';
import 'package:vehicle/screen/sign_in.dart';

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: ListView(
        children: [
          CircleAvatar(
            radius: 50.0,
            child: Icon(Icons.person, size: 60.0),
          ),
          ListTile(
            title: Text('John Doe'),
            subtitle: Text('johndoe@example.com'),
          ),
          ListTile(
            title: Text('Phone'),
            subtitle: Text('+1 234 567 890'),
          ),
          ListTile(
            title: Text('Address'),
            subtitle: Text('123 Main Street, City, State'),
          ),
          ListTile(
            title: Text('College'),
            subtitle: Text('Example University'),
          ),
          ListTile(
            title: Text('Course'),
            subtitle: Text('Computer Science'),
          ),
          ListTile(
            title: Text('Year'),
            subtitle: Text('3rd Year'),
          ),
          ListTile(
            title: Text('Logout'),
            trailing: Icon(Icons.logout),
            onTap: () {
              // Handle logout
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => SignInPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
