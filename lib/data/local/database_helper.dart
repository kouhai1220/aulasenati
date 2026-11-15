
// ============================================================================
// ADMINISTRADOR DE LA BASE DE DATOS SQLITE
// ----------------------------------------------------------------------------
// Se encarga de crear/abrir la base de datos local "aula_puntos_senati.db",
// crear sus tablas y cargar los datos iniciales la primera vez.
// Usa el patrón "Singleton": existe una sola conexión para toda la app.
// ============================================================================

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';
import 'database_seed.dart';

// Clase con una única instancia (Singleton) que gestiona la base de datos.
class DatabaseHelper {
  // Instancia única de la base de datos
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // Referencia a la base de datos abierta (se reutiliza entre consultas).
  static Database? _database;

  // Constructor privado: obliga a usar "DatabaseHelper.instance".
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
    // Carpeta estándar donde se guardan las bases de datos de la app.
    final databasePath = await getDatabasesPath();

    // Ruta final del archivo de base de datos.
    final pathDatabase = join(
      databasePath,
      'aula_puntos_senati.db',
    );

    // Abre (o crea) la base de datos con la versión 1 del esquema.
    return await openDatabase(
      pathDatabase,
      version: 1,
      onConfigure: (db) async {
        // Activar claves foráneas
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Se ejecuta solo la primera vez: se crean las tablas.
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
