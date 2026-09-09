import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/local/db_entities.dart';

/// Port 1:1 của `data/local/LeagueDbHelper.kt`.
/// DB dựng sẵn nằm trong assets, copy sang thư mục database lần chạy đầu.
class LeagueDbHelper {
  LeagueDbHelper();

  static const String dbName = 'sp098_live_score13.db';
  static const String _assetPath = 'assets/db/$dbName';

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, dbName);

    if (!await File(path).exists()) {
      await Directory(dir).create(recursive: true);
      final bytes = await rootBundle.load(_assetPath);
      await File(path).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    final db = await openDatabase(path);
    await _ensureNotificationTable(db);
    return db;
  }

  /// Bảng `fixture_notifications` + migration cột mới, y như bản gốc.
  Future<void> _ensureNotificationTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fixture_notifications (
        fixture_id INTEGER PRIMARY KEY,
        league_name TEXT,
        league_logo TEXT,
        home_name TEXT,
        home_logo TEXT,
        away_name TEXT,
        away_logo TEXT,
        kickoff_time TEXT,
        status TEXT,
        before_match_minutes INTEGER,
        notify_match_start INTEGER,
        notify_end_first_half INTEGER,
        notify_start_second_half INTEGER,
        notify_end_match INTEGER
      )
    ''');

    const newColumns = <String, String>{
      'before_match_minutes': 'INTEGER DEFAULT 15',
      'notify_match_start': 'INTEGER DEFAULT 1',
      'notify_end_first_half': 'INTEGER DEFAULT 1',
      'notify_start_second_half': 'INTEGER DEFAULT 0',
      'notify_end_match': 'INTEGER DEFAULT 0',
      'sport_slug': "TEXT DEFAULT 'football'",
    };

    final existing = <String>{};
    try {
      final info = await db.rawQuery('PRAGMA table_info(fixture_notifications)');
      for (final row in info) {
        final name = row['name'];
        if (name != null) existing.add('$name');
      }
    } catch (_) {
      // Bỏ qua như bản gốc.
    }

    for (final entry in newColumns.entries) {
      if (existing.contains(entry.key)) continue;
      try {
        await db.execute(
          'ALTER TABLE fixture_notifications ADD COLUMN ${entry.key} ${entry.value}',
        );
      } catch (_) {
        // Bỏ qua nếu vẫn lỗi.
      }
    }
  }

  // ---- Giải đấu ----

  /// `sub_type = 1` — giải quốc tế.
  Future<List<LeagueDbEntity>> getInternationalLeagues() => _queryLeagues('''
        SELECT * FROM league
        WHERE sub_type = 1
        ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC
      ''');

  Future<List<LeagueDbEntity>> getNationalLeagues({int limit = 500}) =>
      _queryLeagues('''
        SELECT * FROM league
        WHERE (sub_type != 1 OR sub_type IS NULL)
        ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC
        LIMIT $limit
      ''');

  Future<List<LeagueDbEntity>> getAllLeagues() => _queryLeagues('''
        SELECT * FROM league
        ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC
      ''');

  Future<List<LeagueDbEntity>> getFavouriteLeagues() => _queryLeagues('''
        SELECT * FROM league
        WHERE is_favourite = 1
        ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC
      ''');

  Future<List<LeagueDbEntity>> searchLeagues(String query, {int limit = 50}) =>
      _queryLeagues(
        '''
        SELECT * FROM league
        WHERE name LIKE ?
        ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC
        LIMIT $limit
      ''',
        ['%$query%'],
      );

  Future<LeagueDbEntity?> getLeagueById(int leagueId) async {
    final rows = await _queryLeagues(
      'SELECT * FROM league WHERE id = ? LIMIT 1',
      [leagueId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> toggleFavourite(int leagueId) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE league SET is_favourite = CASE WHEN is_favourite = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [leagueId],
    );
  }

  Future<bool> isFavourite(int leagueId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT is_favourite FROM league WHERE id = ?',
      [leagueId],
    );
    if (rows.isEmpty) return false;
    return (rows.first['is_favourite'] as int? ?? 0) == 1;
  }

  Future<void> updateLeagueTimeUse(int leagueId) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE league SET time_use = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, leagueId],
    );
  }

  Future<List<LeagueDbEntity>> getSearchHistoryLeagues({int limit = 10}) =>
      _queryLeagues(
        'SELECT * FROM league WHERE time_use IS NOT NULL ORDER BY time_use DESC LIMIT $limit',
      );

  Future<void> clearSearchLeagueHistory() async {
    final db = await _database;
    await db.rawUpdate('UPDATE league SET time_use = NULL');
  }

  // ---- Đội bóng ----

  Future<List<TeamDbEntity>> getAllTeams({int limit = 1000, int offset = 0}) =>
      _queryTeams(
        'SELECT * FROM team ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC, id ASC LIMIT $limit OFFSET $offset',
      );

  Future<List<TeamDbEntity>> getFavouriteTeams() => _queryTeams(
        'SELECT * FROM team WHERE is_favourite = 1 ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC, id ASC',
      );

  Future<List<TeamDbEntity>> searchTeams(String query, {int limit = 50}) =>
      _queryTeams(
        'SELECT * FROM team WHERE name LIKE ? ORDER BY CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority ASC, id ASC LIMIT $limit',
        ['%$query%'],
      );

  Future<TeamDbEntity?> getTeamById(int teamId) async {
    final rows =
        await _queryTeams('SELECT * FROM team WHERE id = ? LIMIT 1', [teamId]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> toggleTeamFavourite(int teamId) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE team SET is_favourite = CASE WHEN is_favourite = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [teamId],
    );
  }

  Future<void> updateTeamTimeUse(int teamId) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE team SET time_use = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, teamId],
    );
  }

  Future<List<TeamDbEntity>> getSearchHistoryTeams({int limit = 10}) =>
      _queryTeams(
        'SELECT * FROM team WHERE time_use IS NOT NULL AND time_use > 0 ORDER BY time_use DESC LIMIT $limit',
      );

  Future<void> clearSearchHistory() async {
    final db = await _database;
    await db.rawUpdate('UPDATE team SET time_use = NULL');
  }

  // ---- Thông báo trận ----

  Future<void> toggleNotification(NotificationDbItem item) async {
    final db = await _database;
    if (await isNotificationEnabled(item.id)) {
      await db.delete(
        'fixture_notifications',
        where: 'fixture_id = ?',
        whereArgs: [item.id],
      );
    } else {
      await db.insert(
        'fixture_notifications',
        item.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> saveNotification(NotificationDbItem item) async {
    final db = await _database;
    await db.insert(
      'fixture_notifications',
      item.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeNotification(int fixtureId) async {
    final db = await _database;
    await db.delete(
      'fixture_notifications',
      where: 'fixture_id = ?',
      whereArgs: [fixtureId],
    );
  }

  Future<bool> isNotificationEnabled(int fixtureId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT 1 FROM fixture_notifications WHERE fixture_id = ?',
      [fixtureId],
    );
    return rows.isNotEmpty;
  }

  Future<Set<int>> getNotifiedFixtureIds() async {
    final db = await _database;
    try {
      final rows =
          await db.rawQuery('SELECT fixture_id FROM fixture_notifications');
      return rows
          .map((r) => r['fixture_id'])
          .whereType<int>()
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  Future<List<NotificationDbItem>> getAllNotifications() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT * FROM fixture_notifications');
    return rows.map(NotificationDbItem.fromDbMap).toList(growable: false);
  }

  // ---- Truy vấn nội bộ ----

  Future<List<LeagueDbEntity>> _queryLeagues(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await _database;
    final rows = await db.rawQuery(sql, args);
    return rows.map(LeagueDbEntity.fromDbMap).toList(growable: false);
  }

  Future<List<TeamDbEntity>> _queryTeams(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await _database;
    final rows = await db.rawQuery(sql, args);
    return rows.map(TeamDbEntity.fromDbMap).toList(growable: false);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
