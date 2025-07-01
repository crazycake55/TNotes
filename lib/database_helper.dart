import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tea.dart';


class DatabaseHelper {
  static final _dbName = "tea_collection.db";
  static final _dbVersion = 1;
  static final _tableName = "teas";

  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        type TEXT,
        imgURL TEXT,
        year INTEGER,
        descriptors TEXT
      )
    ''');
  }

  Future<int> insertTea(Tea tea) async {
    final db = await database;
    return await db.insert(_tableName, tea.toMap());
  }

  Future<List<Tea>> getTeas() async {
    final db = await database;
    final maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => Tea.fromMap(maps[i]));
  }

  Future<int> deleteTea(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTea(Tea tea) async {
    final db = await database;
    return await db.update(_tableName, tea.toMap(), where: 'id = ?', whereArgs: [tea.id]);
  }
}
