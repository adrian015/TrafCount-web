import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class GraphData {
  GraphData({this.date, this.detection});
  final DateTime? date;
  final String? detection;
}

RichText buildCountText(String labelText, int count){
  return RichText(
        text: TextSpan(
          text: "Number of $labelText:",
          style: const TextStyle(fontSize: 18),
          children: <TextSpan>[
            TextSpan(text: ' $count\n', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}