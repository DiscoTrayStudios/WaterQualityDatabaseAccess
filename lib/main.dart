import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:water_quality_database_access/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint("Signed in with temp account");
    debugPrint(userCredential.user!.uid); //user id for anonymous account
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "operation-not-allowed":
        debugPrint("Anonymous auth hasn't been enabled for this project.");
        break;
      default:
        debugPrint("Unknown error.");
        debugPrint(e.code);
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Access',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Water Quality Download'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool downloading = false;
  late Future<Uint8List> csv;

  @override
  void initState() {
    super.initState();

    csv = downloadCSV();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: FutureBuilder(
                future: csv,
                builder:
                    (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return SpinKitChasingDots(
                        color: Theme.of(context).colorScheme.primary,
                        size: 50.0,
                      );
                    case ConnectionState.active:
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return const Text("Error!");
                      } else {
                        return TextButton(
                            onPressed: (() {
                              launchUrl(Uri.parse(
                                  "data:text/csv;base64,${base64Encode(snapshot.data!)}"));
                            }),
                            child: const Text("Download"));
                      }
                  }
                })));
  }

  Future<Uint8List> downloadCSV() async {
    CollectionReference ref =
        FirebaseFirestore.instance.collection("testInstances");

    QuerySnapshot eventsQuery = await ref.get();

    List<List<dynamic>> data = List.empty(growable: true);

    List<dynamic> row = [];
    row.add("ID");
    row.add("Longitude");
    row.add("Latitude");
    row.add("DateTime");
    row.add("WaterType");
    row.add("WaterInfo");
    row.add("Notes");
    row.add("pH");
    row.add("Hardness");
    row.add("HydrogenSulfide");
    row.add("Iron");
    row.add("Copper");
    row.add("Lead");
    row.add("Manganese");
    row.add("TotalChlorine");
    row.add("Mercury");
    row.add("Nitrate");
    row.add("Nitrite");
    row.add("Sulfate");
    row.add("Zinc");
    row.add("Flouride");
    row.add("SodiumChloride");
    row.add("TotalAlkalinity");
    row.add("ImageLink");
    data.add(row);

    int count = 0;

    for (var document in eventsQuery.docs) {
      List<dynamic> row = [];
      row.add(count);
      count++;
      row.add(document["longitude"]);
      row.add(document["latitude"]);
      row.add(DateFormat('yyyy/MM/dd HH:mm:ss')
          .format(DateTime.fromMicrosecondsSinceEpoch(document["timestamp"]))
          .toString());
      row.add(document["Water Type"]);
      (document.data() as Map<String, dynamic>).containsKey('Water Info')
          ? row.add("Info: " + document["Water Info"])
          : row.add("None");
      (document.data() as Map<String, dynamic>).containsKey('Notes')
          ? row.add("Info: " + document["Notes"])
          : row.add("None");
      row.add(document["pH"]);
      row.add(document["Hardness"]);
      row.add(document["Hydrogen Sulfide"]);
      row.add(document["Iron"]);
      row.add(document["Copper"]);
      row.add(document["Lead"]);
      row.add(document["Manganese"]);
      row.add(document["Total Chlorine"]);
      row.add(document["Mercury"]);
      row.add(document["Nitrate"]);
      row.add(document["Nitrite"]);
      row.add(document["Sulfate"]);
      row.add(document["Zinc"]);
      row.add(document["Flouride"]);
      row.add(document["Sodium Chloride"]);
      row.add(document["Total Alkalinity"]);
      row.add(document["image"]);
      data.add(row);
    }

    return Uint8List.fromList(
        utf8.encode(const ListToCsvConverter().convert(data)));
  }
}
