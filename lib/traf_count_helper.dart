import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class GraphData {
  GraphData({this.date, this.detections});
  final DateTime? date;
  final int? detections;
}

class AvgData {
  AvgData({this.classDetected, this.avg});
  final String? classDetected;
  final double? avg;
}

RichText buildCountText(String labelText, int count){
  return RichText(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(fontSize: 20),
          children: <TextSpan>[
            TextSpan(text: ' $count\n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

RichText buildDoubleText(String labelText, double count){
  return RichText(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(fontSize: 20),
          children: <TextSpan>[
            TextSpan(text: ' $count\n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}