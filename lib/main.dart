import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'traf_count_helper.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final timeNow = DateTime.now();
  final timeFrame = DateTime.now().subtract(const Duration(days: 7));

  CollectionReference myCollection = FirebaseFirestore.instance.collection('Traffic');
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrafCount: Statistics for previous week'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<QuerySnapshot>(
              future: myCollection.where('time_detected', isGreaterThanOrEqualTo: timeFrame).get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                int collectionSize = snapshot.data!.size;

                var typeCount = {};
                List<GraphData> dateGraph = [];
                // '-motorcyclist':0,'-vehicle':0

                var docSnapshots = snapshot.data!.docs;

                for (var i in docSnapshots) {
                  var type = i.get("type");
                  var time = i.get("time_detected");
                  var newDetec = GraphData(date: time, detection: type);
                  typeCount[type] = (typeCount[type] ?? 0) + 1;
                  dateGraph.add(newDetec);
                }

                final timeFrameHours = timeFrame.difference(timeNow).inHours;

                // Column for checking count of each type detected
                return Row(
                  children: [
                    Column(
                      children: [

                        buildCountText("vehicles",(typeCount['-vehicle'] ?? 0)),

                        buildCountText("pedestrians",(typeCount['-pedestrian'] ?? 0)),

                        buildCountText("bicyclist",(typeCount['-cyclist'] ?? 0)),

                        buildCountText("motorcyclist",(typeCount['-motorcyclist'] ?? 0)),

                        buildCountText("large vehicles",(typeCount['-large_vehicle'] ?? 0)),

                        RichText(
                                text: TextSpan(
                                  text: "Total traffic:",
                                  style: const TextStyle(fontSize: 18),
                                  children: <TextSpan>[
                                    TextSpan(text: ' $collectionSize\n', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                      ],
                    ),

                    Column(
                      children: [

                        buildCountText("vehicles",(typeCount['-vehicle'] ?? 0)),

                        buildCountText("pedestrians",(typeCount['-pedestrian'] ?? 0)),

                        buildCountText("bicyclist",(typeCount['-cyclist'] ?? 0)),

                        buildCountText("motorcyclist",(typeCount['-motorcyclist'] ?? 0)),

                        buildCountText("large vehicles",(typeCount['-large_vehicle'] ?? 0)),

                        RichText(
                                text: TextSpan(
                                  text: "Total traffic:",
                                  style: const TextStyle(fontSize: 18),
                                  children: <TextSpan>[
                                    TextSpan(text: ' $collectionSize\n', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                      ],
                    ),

                    
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
