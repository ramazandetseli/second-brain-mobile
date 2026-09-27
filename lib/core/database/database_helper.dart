import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/notes/models/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    // Web ortamında sqflite çalışmaz, çökmesini engelle
    if (kIsWeb) return null;
    
    if (_database != null) return _database!;
    _database = await _initDB('second_brain.db');
    return _database;
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
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        summary TEXT,
        audio_path TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> insertNote(NoteModel note) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    if (db == null) return [];
    final result = await db.query(
      'notes',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => NoteModel.fromMap(map)).toList();
  }

  Future<void> updateNote(NoteModel note) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllNotes() async {
    final db = await database;
    if (db == null) return;
    await db.delete('notes');
    try {
      await db.rawQuery('VACUUM');
    } catch (_) {}
  }
}