import 'database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineTaskManager {
  static final OfflineTaskManager _instance = OfflineTaskManager._internal();
  factory OfflineTaskManager() => _instance;
  OfflineTaskManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Save a new task for offline creation
  Future<void> saveOfflineTask(Map<String, dynamic> taskData) async {
    final db = await _dbHelper.database;
    final taskWithMetadata = Map<String, dynamic>.from(taskData)..addAll({
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
      'status_id': 1,
    });

    await db.insert('tasks', taskWithMetadata);

    if (taskData['tag_id[]'] != null) {
      final tagIds =
          taskData['tag_id[]'] is List
              ? taskData['tag_id[]']
              : [taskData['tag_id[]']];

      for (var tagId in tagIds) {
        await db.insert('task_tags', {
          'task_id': taskData['id'],
          'tag_id': tagId,
        });
      }
    }
  }

  // Save a task update for offline processing
  Future<void> saveOfflineTaskUpdate(
    String taskId,
    Map<String, dynamic> updateData,
  ) async {
    final db = await _dbHelper.database;
    final taskUpdateData =
        Map<String, dynamic>.from(updateData)
          ..remove('tag_id[]')
          ..addAll({
            'updated_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
            'status_id': 2,
          });

    await db.update(
      'tasks',
      taskUpdateData,
      where: 'id = ?',
      whereArgs: [taskId],
    );

    if (updateData['tag_id[]'] != null) {
      await db.delete('task_tags', where: 'task_id = ?', whereArgs: [taskId]);
      final tagIds =
          updateData['tag_id[]'] is List
              ? updateData['tag_id[]']
              : [updateData['tag_id[]']];

      for (var tagId in tagIds) {
        await db.insert('task_tags', {'task_id': taskId, 'tag_id': tagId});
      }
    }
  }

  // Get all offline tasks waiting to be created
  Future<List<Map<String, dynamic>>> getOfflineTasks() async {
    final db = await _dbHelper.database;
    final tasks = await db.query(
      'tasks',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (var task in tasks) {
      final tags = await db.query(
        'task_tags',
        where: 'task_id = ?',
        whereArgs: [task['id']],
      );
      task['tag_id[]'] = tags.map((tag) => tag['tag_id']).toList();
    }

    return tasks;
  }

  // Get all offline task updates waiting to be processed
  Future<List<Map<String, dynamic>>> getOfflineTaskUpdates() async {
    final db = await _dbHelper.database;
    final updates = await db.query(
      'tasks',
      where: 'status_id = ?',
      whereArgs: [2],
    );

    for (var update in updates) {
      final tags = await db.query(
        'task_tags',
        where: 'task_id = ?',
        whereArgs: [update['id']],
      );
      update['tag_id[]'] = tags.map((tag) => tag['tag_id']).toList();
    }

    return updates;
  }

  // Remove a task after successful sync
  Future<void> removeOfflineTask(Map<String, dynamic> taskData) async {
    final db = await _dbHelper.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskData['id']]);
  }

  // Remove a task update after successful sync
  Future<void> removeOfflineTaskUpdate(Map<String, dynamic> updateData) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'is_synced': 1, 'status_id': 1},
      where: 'id = ?',
      whereArgs: [updateData['id']],
    );
  }

  // Clear all offline data (useful for logout)
  Future<void> clearOfflineData() async {
    final db = await _dbHelper.database;
    await db.delete('tasks', where: 'is_synced = ?', whereArgs: [0]);
    await db.delete('task_tags');
  }
}
