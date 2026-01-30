import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/models/blood_pressure_record.dart';
import 'package:my_first_app/services/database_helper.dart';

class RecordWithTags {
  final BloodPressureRecord record;
  final List<Tag> tags;

  RecordWithTags({required this.record, required this.tags});
}

class HistoryRange {
  final DateTime start;
  final DateTime end;

  const HistoryRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

class HistoryQuery {
  final int? days;
  final HistoryRange? range;

  const HistoryQuery.days(this.days) : range = null;
  const HistoryQuery.range(this.range) : days = null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryQuery &&
        other.days == days &&
        other.range == range;
  }

  @override
  int get hashCode => Object.hash(days, range);
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
final historyRecordsProvider =
    FutureProvider.family<List<RecordWithTags>, HistoryQuery>(
  (ref, query) async {
    final records = await ref.watch(recordsProvider.future);
    if (records.isEmpty) return [];

    List<BloodPressureRecord> filteredRecords = records;

    if (query.range != null) {
      final startDate = DateTime(
        query.range!.start.year,
        query.range!.start.month,
        query.range!.start.day,
      );
      final endDate = DateTime(
        query.range!.end.year,
        query.range!.end.month,
        query.range!.end.day,
        23,
        59,
        59,
        999,
      );
      final startMs = startDate.millisecondsSinceEpoch;
      final endMs = endDate.millisecondsSinceEpoch;

      filteredRecords = records
          .where(
            (r) => r.measureTimeMs >= startMs && r.measureTimeMs <= endMs,
          )
          .toList();
    } else if ((query.days ?? 0) > 0) {
      final days = query.days ?? 0;
      final now = DateTime.now();
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
    FutureProvider.family<List<Map<String, dynamic>>, HistoryQuery>((
      ref,
      query,
    ) async {
      final records = await ref.watch(recordsProvider.future);
      if (records.isEmpty) return [];

      final List<Map<String, dynamic>> result = [];

      if (query.range != null) {
        final startDate = DateTime(
          query.range!.start.year,
          query.range!.start.month,
          query.range!.start.day,
        );
        final endDate = DateTime(
          query.range!.end.year,
          query.range!.end.month,
          query.range!.end.day,
        );
        final daysCount = endDate.difference(startDate).inDays;

        for (int i = 0; i <= daysCount; i++) {
          final day = startDate.add(Duration(days: i));
          result.add(_buildDailyAverage(records, day));
        }
      } else {
        final now = DateTime.now();
        final rangeDays = (query.days ?? 0) > 0 ? query.days! : 30;

        for (int i = rangeDays - 1; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          result.add(_buildDailyAverage(records, day));
        }
      }

      return result;
    });

Map<String, dynamic> _buildDailyAverage(
  List<BloodPressureRecord> records,
  DateTime day,
) {
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

  return {
    'date': day,
    'systolic': avgSys,
    'diastolic': avgDia,
    'hasData': dayRecords.isNotEmpty,
  };
}

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
