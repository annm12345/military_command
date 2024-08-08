import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

import 'package:militarycommand/colors.dart';

class MilitaryCompass extends StatefulWidget {
  @override
  _MilitaryCompassState createState() => _MilitaryCompassState();
}

class _MilitaryCompassState extends State<MilitaryCompass> {
  double? _direction; // To hold the compass direction in degrees

  @override
  void initState() {
    super.initState();
    // Listen to the compass events
    FlutterCompass.events!.listen((CompassEvent event) {
      setState(() {
        _direction = event.heading; // Get the direction in degrees
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(183, 232, 232, 236),
              Color.fromARGB(255, 32, 2, 141)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: ((_direction ?? 0) * (math.pi / 180) * -1),
              child: Icon(
                Icons.navigation,
                size: 100.0,
                color: Color.fromARGB(255, 247, 247, 247),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              _direction == null
                  ? 'Waiting for direction...'
                  : 'Direction: ${_direction!.toStringAsFixed(2)}°',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              _direction == null
                  ? ''
                  : 'Mils: ${(17.7777778 * _direction!).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close", style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 230, 235, 230),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
