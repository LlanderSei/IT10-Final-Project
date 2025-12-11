import 'package:flutter/material.dart';

class SmartTrashBin {
  final double fullnessPercentage;
  final bool isLidOpen;
  final bool hasNotifiedFull;
  final bool hasNotifiedHalf;

  SmartTrashBin({
    required this.fullnessPercentage,
    required this.isLidOpen,
    this.hasNotifiedFull = false,
    this.hasNotifiedHalf = false,
  });

  factory SmartTrashBin.fromJson(
    Map<String, dynamic> json,
    bool hasNotifiedFull,
    bool hasNotifiedHalf, {
    required int trashBinHeight,
    required int lidDetectionRange,
  }) {
    final fullness = json['fullness'];
    if (fullness is! Map) {
      throw Exception("Fullness data is not a map");
    }
    final fullnessMap = Map<String, dynamic>.from(fullness as Map);

    final lid = json['lid'];
    if (lid is! Map) {
      throw Exception("Lid data is not a map");
    }
    final lidMap = Map<String, dynamic>.from(lid as Map);

    // Assuming fullness value_cm is the distance from sensor to trash level
    final valueCm = (fullnessMap['value_cm'] as num?)?.toDouble();
    if (valueCm == null) {
      throw Exception("Fullness value_cm is null, fullness: $fullnessMap");
    }
    double percentage;
    if (valueCm >= trashBinHeight) {
      percentage = 0; // Empty
    } else if (valueCm <= 0) {
      percentage = 100; // Full
    } else {
      // Linear interpolation: 0% at trashBinHeight, 100% at 0
      percentage = (1 - valueCm / trashBinHeight) * 100;
    }

    // Lid is open if value_cm is below lidDetectionRange
    final lidValueCm = (lid['value_cm'] as num?)?.toDouble();
    if (lidValueCm == null) {
      throw Exception("Lid value_cm is null");
    }
    final isLidOpen = lidValueCm < lidDetectionRange;

    return SmartTrashBin(
      fullnessPercentage: percentage.clamp(0, 100),
      isLidOpen: isLidOpen,
      hasNotifiedFull: hasNotifiedFull,
      hasNotifiedHalf: hasNotifiedHalf,
    );
  }

  Color getFullnessColor() {
    if (fullnessPercentage < 33) {
      return Colors.green; // Low fullness
    } else if (fullnessPercentage < 66) {
      return Colors.orange; // Medium fullness
    } else {
      return Colors.red; // High fullness
    }
  }
}
