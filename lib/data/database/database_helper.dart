import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/utils/date_utils.dart';
import '../models/confession.dart';

/// SQLite Database Helper for 100% offline persistence in Renovo.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static const String _dbName = 'renovo.db';
  static const int _dbVersion = 1;

  static const String tableConfessions = 'confessions';
  static const String tableSettings = 'app_settings';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Confessions table
    await db.execute('''
      CREATE TABLE $tableConfessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        parish TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // App settings table (for theme mode, preferences)
    await db.execute('''
      CREATE TABLE $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Index on date for fast queries and ordering
    await db.execute('''
      CREATE INDEX idx_confessions_date ON $tableConfessions (date DESC)
    ''');
  }

  /// Inserts a new confession and returns the inserted ID.
  Future<int> insertConfession(Confession confession) async {
    final db = await database;
    return await db.insert(
      tableConfessions,
      confession.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing confession.
  Future<int> updateConfession(Confession confession) async {
    final db = await database;
    if (confession.id == null) return 0;
    return await db.update(
      tableConfessions,
      confession.toMap(),
      where: 'id = ?',
      whereArgs: [confession.id],
    );
  }

  /// Deletes a confession by ID.
  Future<int> deleteConfession(int id) async {
    final db = await database;
    return await db.delete(
      tableConfessions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all local confessions after a successful cloud migration.
  Future<void> clearAllConfessions() async {
    final db = await database;
    await db.delete(tableConfessions);
  }

  /// Returns whether there are any guest-mode confessions to back up.
  Future<bool> hasLocalConfessions() async {
    final db = await database;
    final results = await db.query(tableConfessions, columns: ['id'], limit: 1);
    return results.isNotEmpty;
  }

  /// Retrieves all confessions, ordered by date descending (most recent first).
  Future<List<Confession>> getAllConfessions() async {
    final db = await database;
    final results = await db.query(
      tableConfessions,
      orderBy: 'date DESC, id DESC',
    );
    return results.map((map) => Confession.fromMap(map)).toList();
  }

  /// Retrieves the single most recent confession.
  Future<Confession?> getLatestConfession() async {
    final db = await database;
    final results = await db.query(
      tableConfessions,
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Confession.fromMap(results.first);
  }

  /// Finds confessions for a specific calendar day.
  Future<List<Confession>> getConfessionsForDay(DateTime day) async {
    final db = await database;
    final normalized = RenovoDateUtils.normalizeDate(day).toIso8601String();
    final results = await db.query(
      tableConfessions,
      where: 'date = ?',
      whereArgs: [normalized],
      orderBy: 'id DESC',
    );
    return results.map((map) => Confession.fromMap(map)).toList();
  }

  /// Retrieves distinct parish names previously entered by the user for autocomplete.
  Future<List<String>> getDistinctParishes() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT parish FROM $tableConfessions 
      WHERE parish IS NOT NULL AND TRIM(parish) != ''
      ORDER BY parish ASC
    ''');
    return results
        .map((row) => (row['parish'] as String).trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Gets a persistent setting value.
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      tableSettings,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  /// Saves a persistent setting value.
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      tableSettings,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
