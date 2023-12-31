import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:collection/collection.dart";
import 'package:syncfusion_flutter_charts/charts.dart';
import 'traf_count_helper.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Get time frame for past 7 days
  final timeNow = DateTime.now();
  final timeFrame = DateTime.now().subtract(const Duration(days: 7));
  // Get firebas collection
  CollectionReference myCollection =
      FirebaseFirestore.instance.collection('Traffic');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('TrafCount: Statistics for last 7 days',
        style: TextStyle(fontWeight: FontWeight.bold)),
      ),

      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child:Column(
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

                  if(collectionSize == 0){
                    return const Text("NO DATA TO WORK WITH");
                  }

                  // Containers used for analytics
                  var typeCount = {};
                  List<GraphData> dateGraph = [];
                  List<AvgData> avgPerHour = [];
                  final timeFrameHours =
                      timeFrame.difference(timeNow).inHours.abs();
                  var docSnapshots = snapshot.data!.docs;

                  for (var i in docSnapshots) {
                    var type = i.get("type");
                    typeCount[type] =
                        (typeCount[type] ?? 0) + 1;
                  }

                  // Group by day
                  var groupByDate = groupBy(
                      docSnapshots,
                      (obj) => obj
                          .get("time_detected")
                          .toDate()
                          .toString()
                          .substring(0, 10));

                  // Group by class
                  var groupByClass = groupBy(
                      docSnapshots,
                      (obj) =>
                          obj.get("type").substring(1, obj.get("type").length));

                  // Goes through group by date and adds it to array to be used in graph later on
                  groupByDate.forEach((date, list) {
                    var newDetec = GraphData(
                        date: DateTime.parse(date),
                        detections: list.length
                            );
                    dateGraph.add(newDetec);
                  });
                  // Goes through group by class and adds it to array to be used in graph later on
                  groupByClass.forEach((classAvg, list) {
                    var newAvg = AvgData(
                        classDetected: classAvg,
                        avg: (list.length / timeFrameHours) 
                            );
                    avgPerHour.add(newAvg);
                  });

                  // Column for checking count of each type detected
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display totals
                      const SizedBox(
                        width: 25,
                      ),
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
                          buildCountText("Total traffic:",
                              collectionSize ),
                        ],
                      ),
                      const SizedBox(
                        width: 10,
                      ),

                      // Graph for total traffic for the day
                      SizedBox(
                        height: 415,
                        width: 415,
                        child: SfCartesianChart(
                            title: ChartTitle(
                              text: 'Total traffic per day',
                              alignment: ChartAlignment.center,
                            ),
                            primaryXAxis: DateTimeCategoryAxis(
                              intervalType: DateTimeIntervalType.days,
                              labelRotation: 45,
                              labelAlignment: LabelAlignment.center,
                            ),
                            series: <ChartSeries<GraphData, DateTime>>[
                              // Renders Column chart
                              ColumnSeries<GraphData, DateTime>(
                                  dataSource: dateGraph,
                                  xValueMapper: (GraphData data, _) =>
                                      data.date,
                                  yValueMapper: (GraphData data, _) =>
                                      data.detections,
                                  dataLabelSettings: const DataLabelSettings(
                                      isVisible: true)),
                            ]),
                      ),
                      
                      const SizedBox(
                        width: 50,
                      ),
                      Column(
                        children: [
                          buildDoubleText("Vehicles per hour:",
                              (typeCount['-vehicle'] ?? 0) / timeFrameHours),
                          buildDoubleText("Pedestrians per hour:",
                              (typeCount['-pedestrian'] ?? 0) / timeFrameHours),
                          buildDoubleText("Bicyclist per hour:",
                              (typeCount['-cyclist'] ?? 0) / timeFrameHours),
                          buildDoubleText(
                              "Motorcyclist per hour:",
                              (typeCount['-motorcyclist'] ?? 0) /
                                  timeFrameHours),
                          buildDoubleText(
                              "Large vehicles per hour:",
                              (typeCount['-large_vehicle'] ?? 0) /
                                  timeFrameHours),
                          buildDoubleText("Total traffic per hour:",
                              collectionSize / timeFrameHours),
                        ],
                      ),
                      const SizedBox(
                        width: 10,
                      ),

                      // Graph for avg traffic per hour for type
                      SizedBox(
                        height: 415,
                        width: 415,
                        child: SfCartesianChart(
                            title: ChartTitle(
                              text: 'Average traffic per hour',
                              alignment: ChartAlignment.center,
                            ),
                            primaryXAxis: CategoryAxis(
                              labelRotation: 45,
                              labelAlignment: LabelAlignment.center,
                            ),
                            series: <ChartSeries<AvgData, String>>[
                              // Renders Column chart
                              ColumnSeries<AvgData, String>(
                                dataSource: avgPerHour,
                                xValueMapper: (AvgData data, _) =>
                                    data.classDetected,
                                yValueMapper: (AvgData data, _) => data.avg,
                              )
                            ]),
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
