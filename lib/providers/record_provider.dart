import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/models/blood_pressure_record.dart';
import 'package:my_first_app/services/database_helper.dart';

// Provider for all records
final recordsProvider = FutureProvider<List<BloodPressureRecord>>((ref) async {
  return await DatabaseHelper.instance.readAllRecords();
});

// Provider for daily average
final dailyAverageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final records = await ref.watch(recordsProvider.future);

  if (records.isEmpty) {
    return {
      'systolic': 0,
      'diastolic': 0,
      'heartRate': 0,
      'count': 0,
      'status': '无数据',
      'lastUpdated': null,
    };
  }

  // Filter for today's records
  final now = DateTime.now();
  final todayStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;
  final todayEnd = DateTime(
    now.year,
    now.month,
    now.day,
    23,
    59,
    59,
  ).millisecondsSinceEpoch;

  final todayRecords = records.where((r) {
    return r.measureTimeMs >= todayStart && r.measureTimeMs <= todayEnd;
  }).toList();

  if (todayRecords.isEmpty) {
    return {
      'systolic': 0,
      'diastolic': 0,
      'heartRate': 0,
      'count': 0,
      'status': '今日无记录',
      'lastUpdated': null,
    };
  }

  // Calculate averages
  int totalSys = 0;
  int totalDia = 0;
  int totalHr = 0;
  int hrCount = 0;

  for (var r in todayRecords) {
    totalSys += r.systolic;
    totalDia += r.diastolic;
    if (r.heartRate != null) {
      totalHr += r.heartRate!;
      hrCount++;
    }
  }

  final avgSys = (totalSys / todayRecords.length).round();
  final avgDia = (totalDia / todayRecords.length).round();
  final avgHr = hrCount > 0 ? (totalHr / hrCount).round() : 0;
  final lastUpdated = todayRecords
      .first
      .measureTimeMs; // Records are sorted DESC by default in DB helper

  // Determine status
  String status;
  if (avgSys < 120 && avgDia < 80) {
    status = '正常';
  } else if (avgSys < 140 && avgDia < 90) {
    status = '偏高';
  } else {
    status = '高血压';
  }

  return {
    'systolic': avgSys,
    'diastolic': avgDia,
    'heartRate': avgHr,
    'count': todayRecords.length,
    'status': status,
    'lastUpdated': lastUpdated,
  };
});
