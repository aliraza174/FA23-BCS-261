// ...existing code...
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/doctor.dart';

class DatabaseHelper {
  static final _dbName = 'doctorApp.db';
  static final _dbVersion = 3; // bumped to add doctor fields
  static final _patientTable = 'patients';
  static final _doctorTable = 'doctors';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<void> _onConfigure(Database db) async {
    // enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // create doctors first
    await db.execute('''
      CREATE TABLE $_doctorTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        specialties TEXT,
        phone TEXT,
        email TEXT,
        yearsExperience INTEGER,
        bio TEXT,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $_patientTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age INTEGER,
        diagnosis TEXT,
        imagePath TEXT,
        doctorId INTEGER,
        FOREIGN KEY (doctorId) REFERENCES $_doctorTable(id) ON DELETE SET NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // existing upgrade logic to version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_doctorTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          specialties TEXT,
          phone TEXT,
          email TEXT
        )
      ''');

      final columns = await db.rawQuery("PRAGMA table_info($_patientTable)");
      final hasDoctorId = columns.any((c) => c['name'] == 'doctorId');
      if (!hasDoctorId) {
        await db.execute(
          'ALTER TABLE $_patientTable ADD COLUMN doctorId INTEGER',
        );
      }
    }

    if (oldVersion < 3) {
      // add new doctor columns safely if they don't exist
      final cols = await db.rawQuery("PRAGMA table_info($_doctorTable)");
      final names = cols.map((c) => c['name'] as String).toList();
      if (!names.contains('yearsExperience')) {
        await db.execute(
          'ALTER TABLE $_doctorTable ADD COLUMN yearsExperience INTEGER',
        );
      }
      if (!names.contains('bio')) {
        await db.execute('ALTER TABLE $_doctorTable ADD COLUMN bio TEXT');
      }
      if (!names.contains('imagePath')) {
        await db.execute('ALTER TABLE $_doctorTable ADD COLUMN imagePath TEXT');
      }
    }
  }

  // ...existing CRUD methods...
  // Patient CRUD (unchanged semantics, now includes doctorId in Patient model)
  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert(_patientTable, patient.toMap());
  }

  Future<List<Patient>> getPatients() async {
    final db = await database;
    final maps = await db.query(_patientTable);
    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  Future<List<Patient>> getPatientsByDoctor(int doctorId) async {
    final db = await database;
    final maps = await db.query(
      _patientTable,
      where: 'doctorId = ?',
      whereArgs: [doctorId],
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return await db.update(
      _patientTable,
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return await db.delete(_patientTable, where: 'id = ?', whereArgs: [id]);
  }

  // Doctor CRUD
  Future<int> insertDoctor(Doctor doctor) async {
    final db = await database;
    return await db.insert(_doctorTable, doctor.toMap());
  }

  Future<List<Doctor>> getDoctors() async {
    final db = await database;
    final maps = await db.query(_doctorTable);
    return maps.map((map) => Doctor.fromMap(map)).toList();
  }

  Future<int> updateDoctor(Doctor doctor) async {
    final db = await database;
    return await db.update(
      _doctorTable,
      doctor.toMap(),
      where: 'id = ?',
      whereArgs: [doctor.id],
    );
  }

  Future<int> deleteDoctor(int id) async {
    final db = await database;
    // deleting doctor will set patients' doctorId to NULL because of ON DELETE SET NULL in new DBs
    return await db.delete(_doctorTable, where: 'id = ?', whereArgs: [id]);
  }

  // helper: get patients along with their doctor's data (simple manual join)
  Future<List<Map<String, dynamic>>> getPatientsWithDoctor() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.*, d.name as doctorName, d.specialties as doctorSpecialties, d.phone as doctorPhone, d.email as doctorEmail
      FROM $_patientTable p
      LEFT JOIN $_doctorTable d ON p.doctorId = d.id
    ''');
    return result;
  }
}
// ...existing code...