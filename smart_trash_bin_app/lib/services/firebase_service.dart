import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<Map<String, dynamic>?> getTrashBinData() {
    return _database.child('sensors').onValue.map((event) {
      final data = event.snapshot.value;
      print('Raw Firebase data: $data');
      if (data is Map<dynamic, dynamic>) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    });
  }

  Future<void> updateNotificationFlags(
    bool hasNotifiedFull,
    bool hasNotifiedHalf,
  ) async {
    await _database.child('app/notification').update({
      'hasNotifiedFull': hasNotifiedFull,
      'hasNotifiedHalf': hasNotifiedHalf,
    });
  }

  Stream<Map<String, bool>> getNotificationFlags() {
    return _database.child('app/notification').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return {
        'hasNotifiedFull': data['hasNotifiedFull'] as bool? ?? false,
        'hasNotifiedHalf': data['hasNotifiedHalf'] as bool? ?? false,
      };
    });
  }

  Stream<Map<String, int>> getSettings() {
    return _database.child('app/settings').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return {
        'trashBinHeight': data['trashBinHeight'] as int? ?? 100,
        'lidDetectionRange': data['lidDetectionRange'] as int? ?? 20,
      };
    });
  }

  Future<void> updateSettings(int trashBinHeight, int lidDetectionRange) async {
    await _database.child('app/settings').update({
      'trashBinHeight': trashBinHeight,
      'lidDetectionRange': lidDetectionRange,
    });
  }
}
