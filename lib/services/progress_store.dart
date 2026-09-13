import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/study_progress.dart';

class ProgressStore {
  const ProgressStore();

  static const _databaseName = 'self_checkin.db';
  static const _tableName = 'app_state';
  static const _progressKey = 'progress';

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      path.join(databasePath, _databaseName),
      version: 1,
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE $_tableName (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      },
    );
  }

  Future<StudyProgress?> load() async {
    final database = await _openDatabase();
    try {
      final rows = await database.query(
        _tableName,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_progressKey],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      final json = jsonDecode(rows.first['value'] as String);
      return json is Map
          ? StudyProgress.fromJson(Map<String, dynamic>.from(json))
          : null;
    } catch (_) {
      return null;
    } finally {
      await database.close();
    }
  }

  Future<void> save(StudyProgress progress) async {
    final database = await _openDatabase();
    try {
      await database.insert(_tableName, {
        'key': _progressKey,
        'value': jsonEncode(progress.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } finally {
      await database.close();
    }
  }

  Future<void> clear() async {
    final database = await _openDatabase();
    try {
      await database.delete(
        _tableName,
        where: 'key = ?',
        whereArgs: [_progressKey],
      );
    } finally {
      await database.close();
    }
  }
}
