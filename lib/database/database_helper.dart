import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../models/event_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('timetide.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, filePath);

    return await openDatabase(dbFilePath, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE events (
  id $idType,
  name $textType,
  description $textNullable,
  eventDate $textType,
  type $textType
)
''');
  }

  Future<List<EventModel>> getEvents() async {
    final db = await instance.database;
    final result = await db.query('events');
    return result.map((json) => EventModel.fromMap(json)).toList();
  }

  Future<int> insertEvent(EventModel event) async {
    final db = await instance.database;
    return await db.insert('events', event.toMap());
  }

  Future<int> updateEvent(EventModel event) async {
    final db = await instance.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
