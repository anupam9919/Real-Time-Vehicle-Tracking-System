import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          child: ListView(
            children: [
              const ExpansionTile(
                title: Text('FAQ 1'),
                children: [
                  ListTile(
                    title: Text('Answer 1'),
                  ),
                ],
              ),
              const ExpansionTile(
                title: Text('FAQ 2'),
                children: [
                  ListTile(
                    title: Text('Answer 2'),
                  ),
                ],
              ),
              const ListTile(
                title: Text('Contact Us'),
                subtitle: Text('support@vehicletracking.com'),
                trailing: Icon(Icons.email),
              ),
              const ListTile(
                title: Text('Call Us'),
                subtitle: Text('+1 234 567 890'),
                trailing: Icon(Icons.call),
              ),
              ListTile(
                title: const Text('Open Support Ticket'),
                onTap: () {
                  // Open support ticket form
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.warning),
        onPressed: () {
          // Handle SOS button press
        },
      ),
    );
  }
}
