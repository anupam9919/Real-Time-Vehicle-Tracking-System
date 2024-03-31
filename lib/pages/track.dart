// tracking_page.dart
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'boarding_point.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < boardingPoints.length; i++)
              TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.5,
                indicatorStyle: const IndicatorStyle(
                  width: 10,
                  color: Colors.blue,
                  padding: EdgeInsets.all(2),
                ),
                startChild: boardingPoints[i].isStart ||
                        boardingPoints[i].isIntermediate
                    ? Container(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(boardingPoints[i].name),
                            Text(boardingPoints[i].eta),
                          ],
                        ),
                      )
                    : const SizedBox(),
                endChild:
                    boardingPoints[i].isEnd || boardingPoints[i].isIntermediate
                        ? Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(boardingPoints[i].name),
                                Text(boardingPoints[i].eta),
                              ],
                            ),
                          )
                        : const SizedBox(),
              ),
          ],
        ),
      ),
    );
  }
}
