
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';
import 'database_seed.dart';

class DatabaseHelper {
  // Instancia única de la base de datos
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  // Obtener la base de datos
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar SQLite
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final pathDatabase = join(
      databasePath,
      'aula_puntos_senati.db',
    );

    return await openDatabase(
      pathDatabase,
      version: 1,
      onConfigure: (db) async {
        // Activar claves foráneas
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Crear todas las tablas
        final batch = db.batch();

        for (final table in DatabaseTables.allTables) {
          batch.execute(table);
        }

        await batch.commit(noResult: true);

        // Insertar datos iniciales
        await DatabaseSeed.insertInitialData(db);
      },
    );
  }

  // Cerrar conexión
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
