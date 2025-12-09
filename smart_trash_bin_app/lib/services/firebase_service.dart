import 'package:firebase_database/firebase_database.dart';
import '../models/smart_trash_bin.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<SmartTrashBin?> getTrashBinData() {
    return _database.child('sensors').onValue.map((event) {
      final data = event.snapshot.value;
      print('Raw Firebase data: $data');
      if (data is Map<dynamic, dynamic>) {
        try {
          return SmartTrashBin.fromJson(Map<String, dynamic>.from(data));
        } catch (e) {
          print('Error parsing data: $e');
          return null;
        }
      }
      return null;
    });
  }

  Future<void> updateNotificationFlags(
    bool hasNotifiedFull,
    bool hasNotifiedHalf,
  ) async {
    await _database.child('sensors/notifications').update({
      'hasNotifiedFull': hasNotifiedFull,
      'hasNotifiedHalf': hasNotifiedHalf,
    });
  }
}
