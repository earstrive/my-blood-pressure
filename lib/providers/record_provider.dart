import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/models/blood_pressure_record.dart';
import 'package:my_first_app/services/database_helper.dart';

class RecordWithTags {
  final BloodPressureRecord record;
  final List<Tag> tags;

  RecordWithTags({required this.record, required this.tags});
}

// Provider for all records
final recordsProvider = FutureProvider<List<BloodPressureRecord>>((ref) async {
  return await DatabaseHelper.instance.readAllRecords();
});

// Provider for recent records with tags
final recentRecordsProvider = FutureProvider<List<RecordWithTags>>((ref) async {
  final records = await ref.watch(recordsProvider.future);
  if (records.isEmpty) return [];

  final dbHelper = DatabaseHelper.instance;
  final Map<String, List<BloodPressureRecord>> grouped = {};

  for (var record in records) {
    final date = DateTime.fromMillisecondsSinceEpoch(record.measureTimeMs);
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(record);
  }

  if (grouped.isEmpty) return [];

  final dayLists = grouped.values.toList();
  final List<BloodPressureRecord> selected = [];

  for (final dayRecords in dayLists) {
    selected.addAll(dayRecords);
    if (selected.length >= 4) {
      break;
    }
  }

  List<RecordWithTags> result = [];
  for (var record in selected) {
    final tags = await dbHelper.getTagsForRecord(record.id!);
    result.add(RecordWithTags(record: record, tags: tags));
  }
  return result;
});

// Provider for history records with time range filtering
final historyRecordsProvider = FutureProvider.family<List<RecordWithTags>, int>(
  (ref, days) async {
    final records = await ref.watch(recordsProvider.future);
    if (records.isEmpty) return [];

    // If days is 0, it means "All" or "Custom" (simplified to All for now)
    // Otherwise filter by last N days
    List<BloodPressureRecord> filteredRecords = records;

    if (days > 0) {
      final now = DateTime.now();
      // Start from midnight of N days ago
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days - 1));
      final startMs = startDate.millisecondsSinceEpoch;

      filteredRecords = records
          .where((r) => r.measureTimeMs >= startMs)
          .toList();
    }

    final dbHelper = DatabaseHelper.instance;
    List<RecordWithTags> result = [];

    for (var record in filteredRecords) {
      final tags = await dbHelper.getTagsForRecord(record.id!);
      result.add(RecordWithTags(record: record, tags: tags));
    }

    return result;
  },
);

// Provider for history chart data (daily averages for the selected range)
final historyChartProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
      final records = await ref.watch(recordsProvider.future);
      if (records.isEmpty) return [];

      // Determine range
      final now = DateTime.now();
      // Default to 7 days if 0 provided for chart to show something meaningful or handle all data
      // Let's say if days=0 (custom), we show last 30 days for now
      final rangeDays = days > 0 ? days : 30;

      final List<Map<String, dynamic>> result = [];

      // Loop through each day in the range
      for (int i = rangeDays - 1; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final startOfDay = DateTime(
          day.year,
          day.month,
          day.day,
        ).millisecondsSinceEpoch;
        final endOfDay = DateTime(
          day.year,
          day.month,
          day.day,
          23,
          59,
          59,
        ).millisecondsSinceEpoch;

        final dayRecords = records.where((r) {
          return r.measureTimeMs >= startOfDay && r.measureTimeMs <= endOfDay;
        }).toList();

        double avgSys = 0;
        double avgDia = 0;

        if (dayRecords.isNotEmpty) {
          final totalSys = dayRecords.fold(0, (sum, r) => sum + r.systolic);
          final totalDia = dayRecords.fold(0, (sum, r) => sum + r.diastolic);
          avgSys = totalSys / dayRecords.length;
          avgDia = totalDia / dayRecords.length;
        }

        result.add({
          'date': day,
          'systolic': avgSys,
          'diastolic': avgDia,
          'hasData': dayRecords.isNotEmpty,
        });
      }

      return result;
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

// Provider for weekly trend
final weeklyTrendProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final records = await ref.watch(recordsProvider.future);

  // Last 7 days including today
  final now = DateTime.now();
  final List<Map<String, dynamic>> result = [];

  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final startOfDay = DateTime(
      day.year,
      day.month,
      day.day,
    ).millisecondsSinceEpoch;
    final endOfDay = DateTime(
      day.year,
      day.month,
      day.day,
      23,
      59,
      59,
    ).millisecondsSinceEpoch;

    final dayRecords = records.where((r) {
      return r.measureTimeMs >= startOfDay && r.measureTimeMs <= endOfDay;
    }).toList();

    double avgSys = 0;
    double avgDia = 0;

    if (dayRecords.isNotEmpty) {
      final totalSys = dayRecords.fold(0, (sum, r) => sum + r.systolic);
      final totalDia = dayRecords.fold(0, (sum, r) => sum + r.diastolic);
      avgSys = totalSys / dayRecords.length;
      avgDia = totalDia / dayRecords.length;
    }

    result.add({
      'weekday': day.weekday, // 1 = Monday, 7 = Sunday
      'systolic': avgSys,
      'diastolic': avgDia,
      'hasData': dayRecords.isNotEmpty,
    });
  }

  return result;
});
