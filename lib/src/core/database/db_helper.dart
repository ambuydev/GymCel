import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gymcel.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const uuid = Uuid();

    // Table: Settings
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Default settings
    await db.insert('settings', {'key': 'is_premium', 'value': 'false'});
    await db.insert('settings', {'key': 'rest_timer_seconds', 'value': '90'});
    await db.insert('settings', {'key': 'weight_unit', 'value': 'kg'});

    // Table: Exercises
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        equipment TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        tracking_type TEXT NOT NULL DEFAULT 'reps',
        notes TEXT
      )
    ''');

    // Table: Routines
    await db.execute('''
      CREATE TABLE routines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        target_days TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Table: Routine Exercises
    await db.execute('''
      CREATE TABLE routine_exercises (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        target_sets INTEGER NOT NULL DEFAULT 3,
        target_reps INTEGER NOT NULL DEFAULT 10,
        target_weight REAL NOT NULL DEFAULT 0.0,
        execution_seconds INTEGER NOT NULL DEFAULT 45,
        rest_seconds INTEGER,
        has_warmup_set INTEGER NOT NULL DEFAULT 0,
        warmup_reps INTEGER NOT NULL DEFAULT 10,
        warmup_weight REAL NOT NULL DEFAULT 10.0,
        warmup_execution_seconds INTEGER NOT NULL DEFAULT 30,
        warmup_rest_seconds INTEGER NOT NULL DEFAULT 60,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (routine_id) REFERENCES routines (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // Table: Workout Sessions
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        routine_id TEXT,
        routine_name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER DEFAULT 0,
        notes TEXT,
        total_volume REAL DEFAULT 0.0
      )
    ''');

    // Table: Workout Sets
    await db.execute('''
      CREATE TABLE workout_sets (
        id TEXT PRIMARY KEY,
        workout_session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL DEFAULT 0.0,
        reps INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (workout_session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Seed default exercises in Spanish
    final defaultExercises = [
      // Pecho
      {'name': 'Press de Banca con Barra', 'category': 'Pecho', 'equipment': 'Barra', 'type': 'reps'},
      {'name': 'Press Inclinado con Mancuernas', 'category': 'Pecho', 'equipment': 'Mancuernas', 'type': 'reps'},
      {'name': 'Aperturas en Polea', 'category': 'Pecho', 'equipment': 'Polea', 'type': 'reps'},
      {'name': 'Fondos en Paralelas', 'category': 'Pecho', 'equipment': 'Peso corporal', 'type': 'reps'},
      {'name': 'Flexiones de Pecho', 'category': 'Pecho', 'equipment': 'Peso corporal', 'type': 'reps'},

      // Espalda
      {'name': 'Dominadas', 'category': 'Espalda', 'equipment': 'Peso corporal', 'type': 'reps'},
      {'name': 'Jalón al Pecho en Polea', 'category': 'Espalda', 'equipment': 'Polea', 'type': 'reps'},
      {'name': 'Remo con Barra', 'category': 'Espalda', 'equipment': 'Barra', 'type': 'reps'},
      {'name': 'Remo con Mancuerna a una Mano', 'category': 'Espalda', 'equipment': 'Mancuernas', 'type': 'reps'},
      {'name': 'Peso Muerto Convencional', 'category': 'Espalda', 'equipment': 'Barra', 'type': 'reps'},
      {'name': 'Colgado en Barra (Agarre)', 'category': 'Espalda', 'equipment': 'Barra', 'type': 'time'},

      // Piernas
      {'name': 'Sentadilla Trasera con Barra', 'category': 'Piernas', 'equipment': 'Barra', 'type': 'reps'},
      {'name': 'Prensa de Piernas', 'category': 'Piernas', 'equipment': 'Máquina', 'type': 'reps'},
      {'name': 'Peso Muerto Rumano', 'category': 'Piernas', 'equipment': 'Barra', 'type': 'reps'},
      {'name': 'Extensión de Cuádriceps', 'category': 'Piernas', 'equipment': 'Máquina', 'type': 'reps'},
      {'name': 'Curl Femoral Tumbado', 'category': 'Piernas', 'equipment': 'Máquina', 'type': 'reps'},
      {'name': 'Elevación de Talones (Gemelos)', 'category': 'Piernas', 'equipment': 'Máquina', 'type': 'reps'},
      {'name': 'Sentadilla Isométrica en Pared', 'category': 'Piernas', 'equipment': 'Peso corporal', 'type': 'time'},

      // Hombros
      {'name': 'Press Militar con Barra', 'category': 'Hombros', 'equipment': 'Barra', 'type': 'reps'},
      {'name': 'Press de Hombros con Mancuernas', 'category': 'Hombros', 'equipment': 'Mancuernas', 'type': 'reps'},
      {'name': 'Elevaciones Laterales con Mancuernas', 'category': 'Hombros', 'equipment': 'Mancuernas', 'type': 'reps'},
      {'name': 'Pájaros (Elevaciones Posteriores)', 'category': 'Hombros', 'equipment': 'Mancuernas', 'type': 'reps'},

      // Brazos
      {'name': 'Curl de Bíceps con Barra', 'category': 'Brazos', 'equipment': 'Barra', 'type': 'reps'},
      {'name': 'Curl de Bíceps Martillo', 'category': 'Brazos', 'equipment': 'Mancuernas', 'type': 'reps'},
      {'name': 'Extensión de Tríceps en Polea', 'category': 'Brazos', 'equipment': 'Polea', 'type': 'reps'},
      {'name': 'Press Francés con Barra Z', 'category': 'Brazos', 'equipment': 'Barra', 'type': 'reps'},

      // Core
      {'name': 'Crunches Abdominales', 'category': 'Core', 'equipment': 'Peso corporal', 'type': 'reps'},
      {'name': 'Plancha Abdominal', 'category': 'Core', 'equipment': 'Peso corporal', 'type': 'time'},
      {'name': 'Plancha Lateral', 'category': 'Core', 'equipment': 'Peso corporal', 'type': 'time'},
      {'name': 'Elevación de Piernas Colgado', 'category': 'Core', 'equipment': 'Peso corporal', 'type': 'reps'},

      // Cardio
      {'name': 'Cinta / Caminadora (Treadmill)', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},
      {'name': 'Bicicleta Fija / Ergométrica', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},
      {'name': 'Bicicleta al Aire Libre', 'category': 'Cardio', 'equipment': 'Bicicleta', 'type': 'cardio'},
      {'name': 'Correr al Aire Libre', 'category': 'Cardio', 'equipment': 'Exterior', 'type': 'cardio'},
      {'name': 'Elíptica', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},
      {'name': 'Remo Ergométrico', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},

      // TRX / Suspensión
      {'name': 'TRX Remo en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Press de Pecho', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Flexiones en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Sentadilla', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Sentadilla a una Pierna (Pistol)', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Zancadas en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Curl de Bíceps', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Extensión de Tríceps', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Encogimientos Abdominales (Atomic Crunch)', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
      {'name': 'TRX Plancha en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'time'},
    ];

    for (final ex in defaultExercises) {
      await db.insert('exercises', {
        'id': uuid.v4(),
        'name': ex['name'],
        'category': ex['category'],
        'equipment': ex['equipment'],
        'is_custom': 0,
        'tracking_type': ex['type'] ?? 'reps',
        'notes': '',
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE exercises ADD COLUMN tracking_type TEXT NOT NULL DEFAULT 'reps'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE routines ADD COLUMN target_days TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN rest_seconds INTEGER");
      } catch (_) {}

      await db.update('exercises', {'tracking_type': 'time'},
          where: "name LIKE '%Plancha%' OR name LIKE '%Isométrica%' OR name LIKE '%Colgado%'");
    }

    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN target_weight REAL NOT NULL DEFAULT 0.0");
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN execution_seconds INTEGER NOT NULL DEFAULT 45");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN has_warmup_set INTEGER NOT NULL DEFAULT 0");
      } catch (_) {}
    }

    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN warmup_reps INTEGER NOT NULL DEFAULT 10");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN warmup_weight REAL NOT NULL DEFAULT 10.0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN warmup_execution_seconds INTEGER NOT NULL DEFAULT 30");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE routine_exercises ADD COLUMN warmup_rest_seconds INTEGER NOT NULL DEFAULT 60");
      } catch (_) {}
    }

    if (oldVersion < 6) {
      const uuid = Uuid();
      final cardioExercises = [
        {'name': 'Cinta / Caminadora (Treadmill)', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},
        {'name': 'Bicicleta Fija / Ergométrica', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},
        {'name': 'Bicicleta al Aire Libre', 'category': 'Cardio', 'equipment': 'Bicicleta', 'type': 'cardio'},
        {'name': 'Correr al Aire Libre', 'category': 'Cardio', 'equipment': 'Exterior', 'type': 'cardio'},
        {'name': 'Elíptica', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},
        {'name': 'Remo Ergométrico', 'category': 'Cardio', 'equipment': 'Máquina Cardio', 'type': 'cardio'},
      ];

      for (final ex in cardioExercises) {
        await db.insert('exercises', {
          'id': uuid.v4(),
          'name': ex['name'],
          'category': ex['category'],
          'equipment': ex['equipment'],
          'is_custom': 0,
          'tracking_type': ex['type'],
          'notes': '',
        });
      }
    }

    if (oldVersion < 7) {
      const uuid = Uuid();
      final trxExercises = [
        {'name': 'TRX Remo en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Press de Pecho', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Flexiones en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Sentadilla', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Sentadilla a una Pierna (Pistol)', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Zancadas en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Curl de Bíceps', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Extensión de Tríceps', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Encogimientos Abdominales (Atomic Crunch)', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'reps'},
        {'name': 'TRX Plancha en Suspensión', 'category': 'TRX', 'equipment': 'TRX / Suspensión', 'type': 'time'},
      ];

      for (final ex in trxExercises) {
        await db.insert('exercises', {
          'id': uuid.v4(),
          'name': ex['name'],
          'category': ex['category'],
          'equipment': ex['equipment'],
          'is_custom': 0,
          'tracking_type': ex['type'],
          'notes': '',
        });
      }
    }
  }

  // Setting methods
  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String? ?? defaultValue;
    }
    return defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Free Tier History Limiter: Prunes workouts older than 30 days if user is NOT premium
  Future<void> enforceHistoryRetentionLimit() async {
    final isPremium = (await getSetting('is_premium')) == 'true';
    if (isPremium) return; // Premium keeps unlimited history

    final db = await instance.database;
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    await db.delete(
      'workout_sessions',
      where: 'start_time < ?',
      whereArgs: [cutoffDate],
    );
  }
}
