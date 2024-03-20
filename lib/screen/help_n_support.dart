import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help and Support'),
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: Text('FAQ 1'),
            children: [
              ListTile(
                title: Text('Answer 1'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('FAQ 2'),
            children: [
              ListTile(
                title: Text('Answer 2'),
              ),
            ],
          ),
          ListTile(
            title: Text('Contact Us'),
            subtitle: Text('support@vehicletracking.com'),
            trailing: Icon(Icons.email),
          ),
          ListTile(
            title: Text('Call Us'),
            subtitle: Text('+1 234 567 890'),
            trailing: Icon(Icons.call),
          ),
          ListTile(
            title: Text('Open Support Ticket'),
            onTap: () {
              // Open support ticket form
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.warning),
        onPressed: () {
          // Handle SOS button press
        },
      ),
    );
  }
}
