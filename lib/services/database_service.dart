import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity.dart';
import '../models/practice_plan.dart';
import '../models/scheduled_plan.dart';
import '../models/plan_group.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'vb_practice_plan.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to activities table
      await db.execute('ALTER TABLE activities ADD COLUMN last_used_date TEXT');
      
      // Add new columns to practice_plans table
      await db.execute('ALTER TABLE practice_plans ADD COLUMN group_id TEXT');
      await db.execute('ALTER TABLE practice_plans ADD COLUMN last_used_date TEXT');
      
      // Create plan_groups table
      await db.execute('''
        CREATE TABLE plan_groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          color TEXT NOT NULL,
          created_date TEXT NOT NULL
        )
      ''');
      
      // Create indexes
      await db.execute('CREATE INDEX idx_plan_group ON practice_plans (group_id)');
      await db.execute('CREATE INDEX idx_last_used ON practice_plans (last_used_date)');
      await db.execute('CREATE INDEX idx_activity_last_used ON activities (last_used_date)');
    }
    if (oldVersion < 3) {
      // Add tags column to activities table
      await db.execute('ALTER TABLE activities ADD COLUMN tags TEXT DEFAULT \"\"');
    }
    if (oldVersion < 4) {
      // Remove category column from activities table by recreating the table
      // SQLite doesn't support DROP COLUMN directly, so we need to recreate the table
      
      // Create new activities table without category
      await db.execute('''
        CREATE TABLE activities_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL,
          description TEXT NOT NULL,
          coaching_tips TEXT NOT NULL,
          tags TEXT DEFAULT "",
          created_date TEXT NOT NULL,
          last_used_date TEXT
        )
      ''');
      
      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO activities_new (id, name, duration_minutes, description, coaching_tips, tags, created_date, last_used_date)
        SELECT id, name, duration_minutes, description, coaching_tips, COALESCE(tags, ""), created_date, last_used_date
        FROM activities
      ''');
      
      // Drop old table
      await db.execute('DROP TABLE activities');
      
      // Rename new table to activities
      await db.execute('ALTER TABLE activities_new RENAME TO activities');
      
      // Recreate index
      await db.execute('CREATE INDEX idx_activity_last_used ON activities (last_used_date)');
    }
    if (oldVersion < 5) {
      // Add focus column to activities table
      await db.execute('ALTER TABLE activities ADD COLUMN focus TEXT DEFAULT ""');
    }
    if (oldVersion < 6) {
      // Add diagram column to activities table
      await db.execute('ALTER TABLE activities ADD COLUMN diagram TEXT');
    }
    if (oldVersion < 7) {
      // Add custom_duration_minutes column to plan_activities table
      await db.execute('ALTER TABLE plan_activities ADD COLUMN custom_duration_minutes INTEGER');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Activities table
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        description TEXT NOT NULL,
        coaching_tips TEXT NOT NULL,
        focus TEXT DEFAULT "",
        tags TEXT DEFAULT "",
        diagram TEXT,
        created_date TEXT NOT NULL,
        last_used_date TEXT
      )
    ''');

    // Plan groups table
    await db.execute('''
      CREATE TABLE plan_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT NOT NULL,
        created_date TEXT NOT NULL
      )
    ''');

    // Practice plans table
    await db.execute('''
      CREATE TABLE practice_plans (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        notes TEXT,
        group_id TEXT,
        created_date TEXT NOT NULL,
        last_modified_date TEXT,
        last_used_date TEXT,
        FOREIGN KEY (group_id) REFERENCES plan_groups (id) ON DELETE SET NULL
      )
    ''');

    // Plan activities junction table (many-to-many relationship)
    await db.execute('''
      CREATE TABLE plan_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id TEXT NOT NULL,
        activity_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        custom_duration_minutes INTEGER,
        FOREIGN KEY (plan_id) REFERENCES practice_plans (id) ON DELETE CASCADE,
        FOREIGN KEY (activity_id) REFERENCES activities (id) ON DELETE CASCADE
      )
    ''');

    // Scheduled plans table
    await db.execute('''
      CREATE TABLE scheduled_plans (
        id TEXT PRIMARY KEY,
        practice_plan_id TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_date TEXT,
        notes TEXT,
        FOREIGN KEY (practice_plan_id) REFERENCES practice_plans (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_plan_activities_plan ON plan_activities (plan_id)');
    await db.execute('CREATE INDEX idx_scheduled_date ON scheduled_plans (scheduled_date)');
    await db.execute('CREATE INDEX idx_plan_group ON practice_plans (group_id)');
    await db.execute('CREATE INDEX idx_last_used ON practice_plans (last_used_date)');
    await db.execute('CREATE INDEX idx_activity_last_used ON activities (last_used_date)');
  }

  // Plan Group CRUD operations
  Future<int> insertPlanGroup(PlanGroup group) async {
    final db = await database;
    await db.insert('plan_groups', group.toMap());
    return 1;
  }

  Future<List<PlanGroup>> getPlanGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plan_groups',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => PlanGroup.fromMap(maps[i]));
  }

  Future<PlanGroup?> getPlanGroup(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plan_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PlanGroup.fromMap(maps.first);
  }

  Future<int> updatePlanGroup(PlanGroup group) async {
    final db = await database;
    return await db.update(
      'plan_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deletePlanGroup(String id) async {
    final db = await database;
    // Set group_id to null for plans in this group
    await db.update(
      'practice_plans',
      {'group_id': null},
      where: 'group_id = ?',
      whereArgs: [id],
    );
    // Delete the group
    return await db.delete(
      'plan_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Activity CRUD operations
  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    await db.insert('activities', activity.toMap());
    return 1;
  }

  Future<List<Activity>> getActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      orderBy: 'created_date DESC',
    );
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }

  Future<Activity?> getActivity(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Activity.fromMap(maps.first);
  }

  Future<int> updateActivity(Activity activity) async {
    final db = await database;
    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> deleteActivity(String id) async {
    final db = await database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Activity>> getRecentlyUsedActivities({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> activityMaps = await db.query(
      'activities',
      where: 'last_used_date IS NOT NULL',
      orderBy: 'last_used_date DESC',
      limit: limit,
    );
    return List.generate(activityMaps.length, (i) => Activity.fromMap(activityMaps[i]));
  }

  // Practice Plan CRUD operations
  Future<int> insertPracticePlan(PracticePlan plan) async {
    final db = await database;
    await db.insert('practice_plans', plan.toMap());
    
    // Insert plan activities with positions and custom durations
    for (int i = 0; i < plan.activities.length; i++) {
      final activity = plan.activities[i];
      await db.insert('plan_activities', {
        'plan_id': plan.id,
        'activity_id': activity.id,
        'position': i,
        'custom_duration_minutes': activity.durationMinutes,
      });
    }
    return 1;
  }

  Future<List<PracticePlan>> getPracticePlans({String? groupId}) async {
    final db = await database;
    List<Map<String, dynamic>> planMaps;
    
    if (groupId != null) {
      planMaps = await db.query(
        'practice_plans',
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'created_date DESC',
      );
    } else {
      planMaps = await db.query(
        'practice_plans',
        orderBy: 'created_date DESC',
      );
    }
    
    List<PracticePlan> plans = [];
    for (var planMap in planMaps) {
      final plan = PracticePlan.fromMap(planMap);
      plan.activities = await getPlanActivities(plan.id);
      plans.add(plan);
    }
    return plans;
  }

  Future<List<PracticePlan>> getRecentlyUsedPlans({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> planMaps = await db.query(
      'practice_plans',
      where: 'last_used_date IS NOT NULL',
      orderBy: 'last_used_date DESC',
      limit: limit,
    );
    
    List<PracticePlan> plans = [];
    for (var planMap in planMaps) {
      final plan = PracticePlan.fromMap(planMap);
      plan.activities = await getPlanActivities(plan.id);
      plans.add(plan);
    }
    return plans;
  }

  Future<PracticePlan?> getPracticePlan(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practice_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    
    final plan = PracticePlan.fromMap(maps.first);
    plan.activities = await getPlanActivities(id);
    return plan;
  }

  Future<List<Activity>> getPlanActivities(String planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, pa.custom_duration_minutes FROM activities a
      INNER JOIN plan_activities pa ON a.id = pa.activity_id
      WHERE pa.plan_id = ?
      ORDER BY pa.position
    ''', [planId]);
    
    return List.generate(maps.length, (i) {
      final activity = Activity.fromMap(maps[i]);
      // If there's a custom duration, use it
      final customDuration = maps[i]['custom_duration_minutes'] as int?;
      if (customDuration != null) {
        return activity.copyWith(durationMinutes: customDuration);
      }
      return activity;
    });
  }

  Future<int> updatePracticePlan(PracticePlan plan) async {
    final db = await database;
    
    // Update plan
    await db.update(
      'practice_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
    
    // Delete existing plan activities
    await db.delete(
      'plan_activities',
      where: 'plan_id = ?',
      whereArgs: [plan.id],
    );
    
    // Insert new plan activities with custom durations
    for (int i = 0; i < plan.activities.length; i++) {
      final activity = plan.activities[i];
      await db.insert('plan_activities', {
        'plan_id': plan.id,
        'activity_id': activity.id,
        'position': i,
        'custom_duration_minutes': activity.durationMinutes,
      });
    }
    
    return 1;
  }

  Future<int> deletePracticePlan(String id) async {
    final db = await database;
    
    // Delete plan activities first
    await db.delete(
      'plan_activities',
      where: 'plan_id = ?',
      whereArgs: [id],
    );
    
    // Delete the plan
    return await db.delete(
      'practice_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Scheduled Plan CRUD operations
  Future<int> insertScheduledPlan(ScheduledPlan scheduledPlan) async {
    final db = await database;
    await db.insert('scheduled_plans', scheduledPlan.toMap());
    return 1;
  }

  Future<List<ScheduledPlan>> getScheduledPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_plans',
      orderBy: 'scheduled_date DESC',
    );
    return List.generate(maps.length, (i) => ScheduledPlan.fromMap(maps[i]));
  }

  Future<List<ScheduledPlan>> getScheduledPlansForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_plans',
      where: 'scheduled_date >= ? AND scheduled_date <= ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'scheduled_date',
    );
    return List.generate(maps.length, (i) => ScheduledPlan.fromMap(maps[i]));
  }

  Future<ScheduledPlan?> getScheduledPlan(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ScheduledPlan.fromMap(maps.first);
  }

  Future<int> updateScheduledPlan(ScheduledPlan scheduledPlan) async {
    final db = await database;
    return await db.update(
      'scheduled_plans',
      scheduledPlan.toMap(),
      where: 'id = ?',
      whereArgs: [scheduledPlan.id],
    );
  }

  Future<int> deleteScheduledPlan(String id) async {
    final db = await database;
    return await db.delete(
      'scheduled_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Utility method to close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
