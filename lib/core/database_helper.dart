import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_task.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        user_id INTEGER,
        project_id INTEGER,
        status_id INTEGER,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE task_tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        tag_id INTEGER,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        name TEXT,
        email TEXT,
        profile_picture TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY,
        name TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY,
        name TEXT,
        color TEXT
      )
    ''');
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await db.query('tasks');
  }

  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    final db = await database;
    return await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTaskTag(int taskId, int tagId) async {
    final db = await database;
    return await db.insert('task_tags', {'task_id': taskId, 'tag_id': tagId});
  }

  Future<List<Map<String, dynamic>>> getTaskTags(int taskId) async {
    final db = await database;
    return await db.query(
      'task_tags',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> insertProject(Map<String, dynamic> project) async {
    final db = await database;
    return await db.insert('projects', project);
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return await db.query('projects');
  }

  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    return await db.insert('tags', tag);
  }

  Future<List<Map<String, dynamic>>> getTags() async {
    final db = await database;
    return await db.query('tags');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTasks() async {
    final db = await database;
    return await db.query('tasks', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markTaskAsSynced(int taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> syncOfflineTasks(List<Map<String, dynamic>> tasks) async {
    final db = await database;
    for (var task in tasks) {
      await db.insert('tasks', task);
    }
  }
}
