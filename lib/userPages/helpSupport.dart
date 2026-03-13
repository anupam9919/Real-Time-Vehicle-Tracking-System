import 'package:flutter/material.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('HelpPage');

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
              ExpansionTile(
                title: const Text('FAQ 1'),
                onExpansionChanged: (expanded) {
                  if (expanded) _log.fine('FAQ 1 expanded');
                },
                children: const [
                  ListTile(
                    title: Text('Answer 1'),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('FAQ 2'),
                onExpansionChanged: (expanded) {
                  if (expanded) _log.fine('FAQ 2 expanded');
                },
                children: const [
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
                  _log.info('Support ticket button tapped');
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
          _log.warning('SOS button pressed!');
          // Handle SOS button press
        },
      ),
    );
  }
}
