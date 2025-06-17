import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VeritabaniYardimcisi {
  static final VeritabaniYardimcisi _instance = VeritabaniYardimcisi._internal();
  static Database? _database;

  VeritabaniYardimcisi._internal();

  factory VeritabaniYardimcisi() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'gelirgider.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE islemler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tur TEXT,
            kategori TEXT,
            miktar REAL,
            tarih TEXT
          )
        ''');
      },
    );
  }

  Future<int> islemEkle(Map<String, dynamic> veri) async {
    final db = await database;
    return await db.insert('islemler', veri);
  }

  Future<List<Map<String, dynamic>>> tumIslemler() async {
    final db = await database;
    return await db.query('islemler', orderBy: 'tarih DESC');
  }

  Future<void> tumunuSil() async {
    final db = await database;
    await db.delete('islemler');
  }
}
