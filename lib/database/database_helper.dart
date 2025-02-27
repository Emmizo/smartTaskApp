import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final _lock = Lock();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'tasks.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        title TEXT,
        description TEXT,
        due_date TEXT,
        user_id INTEGER,
        tag_id TEXT,
        project_id INTEGER,
        status_id INTEGER,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    await _lock.synchronized(() async {
      await db.insert('tasks', task);
    });
  }

  Future<void> updateTask(Map<String, dynamic> task) async {
    final db = await database;
    await _lock.synchronized(() async {
      await db.update(
        'tasks',
        task,
        where: 'task_id = ?',
        whereArgs: [task['task_id']],
      );
    });
  }

  Future<void> deleteTask(int taskId) async {
    final db = await database;
    await _lock.synchronized(() async {
      await db.delete('tasks', where: 'task_id = ?', whereArgs: [taskId]);
    });
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await _lock.synchronized(() async {
      return await db.query('tasks');
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTasks() async {
    final db = await database;
    return await _lock.synchronized(() async {
      return await db.query('tasks', where: 'is_synced = ?', whereArgs: [0]);
    });
  }

  Future<void> markTaskAsSynced(int taskId) async {
    final db = await database;
    await _lock.synchronized(() async {
      await db.update(
        'tasks',
        {'is_synced': 1},
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
    });
  }
}
