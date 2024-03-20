import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.5,
              indicatorStyle: const IndicatorStyle(
                width: 50,
                color: Colors.blue,
                padding: EdgeInsets.all(2),
              ),
              startChild: Container(
                alignment: Alignment.centerRight,
                child: const Text('Boarding Point'),
              ),
              endChild: const SizedBox(),
            ),
            TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.5,
              indicatorStyle: const IndicatorStyle(
                width: 50,
                color: Colors.blue,
                padding: EdgeInsets.all(2),
              ),
              startChild: Container(
                alignment: Alignment.centerRight,
                child: const Text('Naini'),
              ),
              endChild: const SizedBox(),
            ),
            TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.5,
              indicatorStyle: const IndicatorStyle(
                width: 50,
                color: Colors.blue,
                padding: EdgeInsets.all(2),
              ),
              startChild: const SizedBox(),
              endChild: Container(
                alignment: Alignment.centerLeft,
                child: const Text('Destination'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
