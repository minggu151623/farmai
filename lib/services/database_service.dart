import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diagnosis_record.dart';

class DatabaseService {
  static const String _dbName = 'farmai.db';
  static const String _tableName = 'diagnosis_history';
  static const int _dbVersion = 1;

  Database? _database;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        plantName TEXT NOT NULL,
        diseaseName TEXT NOT NULL,
        confidence INTEGER NOT NULL,
        imagePath TEXT,
        imageUrl TEXT,
        overview TEXT NOT NULL,
        cause TEXT NOT NULL,
        signs TEXT NOT NULL,
        solutions TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertRecord(DiagnosisRecord record) async {
    final db = await database;
    return db.insert(_tableName, record.toMap());
  }

  Future<List<DiagnosisRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'id DESC');
    return maps.map((map) => DiagnosisRecord.fromMap(map)).toList();
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllRecords() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
