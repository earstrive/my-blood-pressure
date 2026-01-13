import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:my_first_app/models/blood_pressure_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('blood_pressure.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 2.1 血压记录表
    await db.execute('''
      CREATE TABLE blood_pressure_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        heart_rate INTEGER,
        measure_time_ms INTEGER NOT NULL,
        note TEXT,
        created_at_ms INTEGER NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
    
    // Index for measure_time_ms
    await db.execute(
      'CREATE INDEX idx_bpr_measure_time_ms ON blood_pressure_record(measure_time_ms)',
    );

    // 2.2 标签表
    await db.execute('''
      CREATE TABLE tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER,
        created_at_ms INTEGER NOT NULL
      )
    ''');

    // 2.3 记录-标签关联表
    await db.execute('''
      CREATE TABLE record_tag (
        record_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (record_id, tag_id),
        FOREIGN KEY (record_id) REFERENCES blood_pressure_record (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tag (id) ON DELETE CASCADE
      )
    ''');
    
    // Index for tag_id
    await db.execute(
      'CREATE INDEX idx_record_tag_tag_id ON record_tag(tag_id)',
    );

    // 2.4 应用设置表
    await db.execute('''
      CREATE TABLE app_kv (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
    
    // Initialize default tags
    await _insertDefaultTags(db);
  }

  Future<void> _insertDefaultTags(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tags = [
      {'name': '咖啡', 'color': 0xFF795548}, // Brown
      {'name': '运动', 'color': 0xFF4CAF50}, // Green
      {'name': '服药', 'color': 0xFF2196F3}, // Blue
      {'name': '熬夜', 'color': 0xFF9C27B0}, // Purple
    ];

    for (var tag in tags) {
      await db.insert('tag', {
        'name': tag['name'],
        'color': tag['color'],
        'created_at_ms': now,
      });
    }
  }

  // --- CRUD Operations for BloodPressureRecord ---

  Future<int> createRecord(BloodPressureRecord record) async {
    final db = await instance.database;
    return await db.insert('blood_pressure_record', record.toMap());
  }

  Future<BloodPressureRecord?> readRecord(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'blood_pressure_record',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return BloodPressureRecord.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<BloodPressureRecord>> readAllRecords() async {
    final db = await instance.database;
    const orderBy = 'measure_time_ms DESC';
    final result = await db.query('blood_pressure_record', orderBy: orderBy);
    return result.map((json) => BloodPressureRecord.fromMap(json)).toList();
  }

  Future<int> updateRecord(BloodPressureRecord record) async {
    final db = await instance.database;
    return db.update(
      'blood_pressure_record',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'blood_pressure_record',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // --- Tag Operations ---
  
  Future<List<Tag>> getAllTags() async {
    final db = await instance.database;
    final result = await db.query('tag', orderBy: 'id ASC');
    return result.map((json) => Tag.fromMap(json)).toList();
  }
  
  Future<int> createTag(Tag tag) async {
    final db = await instance.database;
    return await db.insert('tag', tag.toMap());
  }
  
  // --- Record-Tag Operations ---
  
  Future<void> addTagToRecord(int recordId, int tagId) async {
    final db = await instance.database;
    await db.insert('record_tag', {
      'record_id': recordId,
      'tag_id': tagId,
    });
  }
  
  Future<List<Tag>> getTagsForRecord(int recordId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.* FROM tag t
      INNER JOIN record_tag rt ON t.id = rt.tag_id
      WHERE rt.record_id = ?
    ''', [recordId]);
    
    return result.map((json) => Tag.fromMap(json)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
