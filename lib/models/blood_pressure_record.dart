class BloodPressureRecord {
  final int? id;
  final int systolic;
  final int diastolic;
  final int? heartRate;
  final int measureTimeMs;
  final String? note;
  final int createdAtMs;
  final int updatedAtMs;

  BloodPressureRecord({
    this.id,
    required this.systolic,
    required this.diastolic,
    this.heartRate,
    required this.measureTimeMs,
    this.note,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'measure_time_ms': measureTimeMs,
      'note': note,
      'created_at_ms': createdAtMs,
      'updated_at_ms': updatedAtMs,
    };
  }

  factory BloodPressureRecord.fromMap(Map<String, dynamic> map) {
    return BloodPressureRecord(
      id: map['id'] as int?,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      heartRate: map['heart_rate'] as int?,
      measureTimeMs: map['measure_time_ms'] as int,
      note: map['note'] as String?,
      createdAtMs: map['created_at_ms'] as int,
      updatedAtMs: map['updated_at_ms'] as int,
    );
  }

  BloodPressureRecord copyWith({
    int? id,
    int? systolic,
    int? diastolic,
    int? heartRate,
    int? measureTimeMs,
    String? note,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return BloodPressureRecord(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      measureTimeMs: measureTimeMs ?? this.measureTimeMs,
      note: note ?? this.note,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}

class Tag {
  final int? id;
  final String name;
  final int? color;
  final int createdAtMs;

  Tag({
    this.id,
    required this.name,
    this.color,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at_ms': createdAtMs,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int?,
      createdAtMs: map['created_at_ms'] as int,
    );
  }
}
