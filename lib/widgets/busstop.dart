import 'package:flutter/material.dart';
import 'package:vehicle/pages/searchpage.dart';

class BusStopWidget extends StatelessWidget {
  const BusStopWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearest Bus Stop',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildBusStopInfo(
                icon: Icons.bus_alert,
                title: 'Ada Mode',
                subTitle: '3 min',
              ),
              const SizedBox(height: 16),
              Text(
                'Next Buses',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 8),
              _buildBusInfo(
                busNumber: 'PE-5',
                destination: 'To New Shantipuram',
                time: '10:05 AM',
              ),
              const SizedBox(height: 8),
              _buildBusInfo(
                busNumber: 'PE-5',
                destination: 'To Jahangirabad',
                time: '10:51 AM',
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SearchPage(),
                      ),
                    );
                    // Handle "See all buses" button press
                  },
                  child: const Text('See all buses'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusStopInfo({
    required IconData icon,
    required String title,
    required String subTitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subTitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBusInfo({
    required String busNumber,
    required String destination,
    required String time,
  }) {
    return Row(
      children: [
        const Icon(Icons.bus_alert, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              busNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              destination,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
