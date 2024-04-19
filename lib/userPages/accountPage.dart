import 'package:flutter/material.dart';
import 'package:vehicle/userPages/signIn.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _selectedBus = '';

  final List<String> _buses = ['', 'A1', 'B2', 'C3', 'D4'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(
            height: 20,
          ),
          const CircleAvatar(
            radius: 50.0,
            child: Icon(Icons.person, size: 60.0),
          ),
          const ListTile(
            title: Text('John Doe'),
            subtitle: Text('johndoe@example.com'),
          ),
          const ListTile(
            title: Text('Phone'),
            subtitle: Text('+1 234 567 890'),
          ),
          const ListTile(
            title: Text('Address'),
            subtitle: Text('123 Main Street, City, State'),
          ),
          const ListTile(
            title: Text('College'),
            subtitle: Text('Example University'),
          ),
          const ListTile(
            title: Text('Course'),
            subtitle: Text('Computer Science'),
          ),
          const ListTile(
            title: Text('Year'),
            subtitle: Text('3rd Year'),
          ),
          ListTile(
            title: const Text('Bus Choice'),
            subtitle:
                Text(_selectedBus.isNotEmpty ? _selectedBus : 'Select Bus'),
            trailing: DropdownButton<String>(
              value: _selectedBus,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBus = newValue!;
                });
              },
              items: _buses.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Logout'),
            trailing: const Icon(Icons.logout),
            onTap: () {
              // Handle logout
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignInPage(),
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
