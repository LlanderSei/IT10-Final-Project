import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'models/smart_trash_bin.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: '"Smart" Trash Bin Monitor'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  SmartTrashBin? _trashBinData;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _firebaseService.getTrashBinData().listen((data) {
      _handleDataUpdate(data);
    });
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _handleDataUpdate(SmartTrashBin? data) {
    if (data == null) return;

    final previousData = _trashBinData;
    setState(() {
      _trashBinData = data;
    });

    // Check for notifications
    if (data.fullnessPercentage >= 100 &&
        (previousData == null || !previousData.hasNotifiedFull)) {
      _showNotification(
        'Trash Bin Full',
        'The trash bin is full. Please empty it.',
      );
      _firebaseService.updateNotificationFlags(true, data.hasNotifiedHalf);
    } else if (data.fullnessPercentage >= 50 &&
        data.fullnessPercentage < 100 &&
        (previousData == null || !previousData.hasNotifiedHalf)) {
      _showNotification('Trash Bin Half Full', 'The trash bin is half full.');
      _firebaseService.updateNotificationFlags(data.hasNotifiedFull, true);
    } else if (data.fullnessPercentage < 50 &&
        previousData != null &&
        previousData.hasNotifiedHalf) {
      // Reset half notification flag
      _firebaseService.updateNotificationFlags(data.hasNotifiedFull, false);
    } else if (data.fullnessPercentage < 100 &&
        previousData != null &&
        previousData.hasNotifiedFull) {
      // Reset full notification flag
      _firebaseService.updateNotificationFlags(false, data.hasNotifiedHalf);
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'trash_bin_channel',
          'Trash Bin Notifications',
          channelDescription: 'Notifications for trash bin status',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _trashBinData == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.0),
                Text('Loading data...'),
              ],
            )
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.all(14.0),
              child: Card(
                elevation: 4.0,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Trash Bin',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Fullness: ${_trashBinData!.fullnessPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: _trashBinData!.getFullnessColor(),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _trashBinData!.isLidOpen ? 'Open' : 'Closed',
                        style: const TextStyle(fontSize: 18.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
