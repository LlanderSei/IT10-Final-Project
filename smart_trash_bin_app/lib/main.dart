import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/TrashbinMonitorPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request notification permission if not granted
  var status = await Permission.notification.status;
  if (status.isDenied) {
    var result = await Permission.notification.request();
    if (result.isDenied) {
      Fluttertoast.showToast(msg: "Sending notification is rejected");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '"Smart" Trash Bin Monitor',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 255, 182, 74),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const TrashbinMonitorPage(title: '"Smart" Trash Bin Monitor'),
    );
  }
}
