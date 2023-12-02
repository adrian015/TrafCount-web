import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:collection/collection.dart";
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
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

  CollectionReference myCollection =
      FirebaseFirestore.instance.collection('Traffic');

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
              future: myCollection
                  .where('time_detected', isGreaterThanOrEqualTo: timeFrame)
                  .get(),
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
                List<AvgData> avgPerHour = [];
                final timeFrameHours = timeFrame.difference(timeNow).inHours.abs();
                var docSnapshots = snapshot.data!.docs;

                for (var i in docSnapshots) {
                  var type = i.get("type");
                  typeCount[type] = (typeCount[type] ?? 0) + 1;
                }

                var groupByDate = groupBy(
                    docSnapshots,
                    (obj) => obj
                        .get("time_detected")
                        .toDate()
                        .toString()
                        .substring(0, 10));

                var groupByClass = groupBy(
                    docSnapshots,
                    (obj) =>
                        obj.get("type").substring(1, obj.get("type").length));

                groupByDate.forEach((date, list) {
                  var newDetec = GraphData(
                      date: DateTime.parse(date), detections: list.length);
                  dateGraph.add(newDetec);
                });
                groupByClass.forEach((classAvg, list) {
                  var newAvg = AvgData(
                      classDetected: classAvg, avg: (list.length/timeFrameHours));
                      print(classAvg);
                  avgPerHour.add(newAvg);
                });

                // Column for checking count of each type detected
                return Row(
                  children: [
                    // Display totals
                    Column(
                      children: [
                        buildCountText("Number of vehicles:",
                            (typeCount['-vehicle'] ?? 0)),
                        buildCountText("Number of pedestrians:",
                            (typeCount['-pedestrian'] ?? 0)),
                        buildCountText("Number of bicyclist:",
                            (typeCount['-cyclist'] ?? 0)),
                        buildCountText("Number of motorcyclist:",
                            (typeCount['-motorcyclist'] ?? 0)),
                        buildCountText("Number of large vehicles:",
                            (typeCount['-large_vehicle'] ?? 0)),
                        buildCountText("Total traffic:", collectionSize),
                      ],
                    ),

                    // Graph for total traffic for the day
                    Column(
                      children: [
                        SfCartesianChart(
                            primaryXAxis: DateTimeCategoryAxis(
                              intervalType: DateTimeIntervalType.days,
                            ),
                            series: <ChartSeries<GraphData, DateTime>>[
                              // Renders Column chart
                              ColumnSeries<GraphData, DateTime>(
                                  dataSource: dateGraph,
                                  xValueMapper: (GraphData data, _) =>
                                      data.date,
                                  yValueMapper: (GraphData data, _) =>
                                      data.detections)
                            ]),
                      ],
                    ),
                    
                    // Graph for avg traffic per hour for type
                    Column(
                      children: [
                        SfCartesianChart(
                          primaryXAxis: CategoryAxis(
                            labelRotation:45,
                            labelAlignment: LabelAlignment.center,
                          ),
                            series: <ChartSeries<AvgData, String>>[
                              // Renders Column chart
                              ColumnSeries<AvgData, String>(
                                  dataSource: avgPerHour,
                                  xValueMapper: (AvgData data, _) =>
                                      data.classDetected,
                                  yValueMapper: (AvgData data, _) =>
                                      data.avg)
                            ]),
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
