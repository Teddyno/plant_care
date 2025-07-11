import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/CategoriaModel.dart';
import '../../models/AttivitaCuraModel.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  
  /// Inizializza il database factory appropriato per la piattaforma
  static Future<void> initializeDatabaseFactory() async {
    try {
      // Verifica se siamo su una piattaforma desktop
      bool isDesktop = false;
      
      try {
        // Prova a rilevare la piattaforma
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          isDesktop = true;
        }
      } catch (e) {
        // Se il rilevamento della piattaforma fallisce, 
        // assumiamo che non siamo su desktop
        print('Impossibile rilevare la piattaforma: $e');
        isDesktop = false;
      }
      
      if (isDesktop) {
        sqfliteFfiInit(); // Inizializza FFI per desktop
        databaseFactory = databaseFactoryFfi;
        print('Database factory inizializzato per piattaforma desktop');
      } else {
        print('Utilizzo database factory predefinito per piattaforma mobile/web');
      }
    } catch (e) {
      print('Errore durante l\'inizializzazione del database factory: $e');
      // Continua con il database factory predefinito
    }
  }
  
  Future<Database> get database async => _database ??= await _initDB();

  Future<Database> _initDB() async {
    // Assicurati che il database factory sia inizializzato
    await initializeDatabaseFactory();
    
    String path;
    try {
      path = join(await getDatabasesPath(), 'plant_care_v3.db');
    } catch (e) {
      print('Errore nel determinare il percorso del database: $e');
      // Fallback: usa un percorso temporaneo
      path = 'plant_care_v3.db';
    }
    
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _onCreate, 
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON')
    );
  }

  Future _onCreate(Database db, int version) async {
    var batch = db.batch();
    
    // Tabella categorie
    batch.execute('''
      CREATE TABLE categorie(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        nome TEXT NOT NULL UNIQUE
      )
    ''');

    // Tabella specie
    batch.execute('''
      CREATE TABLE specie(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        nome TEXT NOT NULL UNIQUE, 
        descrizione TEXT, 
        idCategoria INTEGER NOT NULL, 
        FOREIGN KEY (idCategoria) 
        REFERENCES categorie(id) ON DELETE CASCADE
      )
    ''');

    // Tabella piante
    batch.execute('''
      CREATE TABLE piante(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        nome TEXT NOT NULL, 
        dataAcquisto TEXT NOT NULL, 
        foto BLOB, 
        frequenzaInnaffiatura INTEGER NOT NULL, 
        frequenzaPotatura INTEGER NOT NULL, 
        frequenzaRinvaso INTEGER NOT NULL, 
        note TEXT, 
        stato TEXT NOT NULL, 
        idSpecie INTEGER NOT NULL, 
        FOREIGN KEY (idSpecie) 
        REFERENCES specie(id) ON DELETE CASCADE
      )
    ''');
      
    // Tabella attivitaCura
    batch.execute('''
      CREATE TABLE attivitaCura(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        idPianta INTEGER NOT NULL, 
        tipoAttivita TEXT NOT NULL, 
        data TEXT NOT NULL, 
        FOREIGN KEY (idPianta) 
        REFERENCES piante(id) ON DELETE CASCADE
      )
    ''');
    
    await batch.commit(noResult: true);
    
    // Inizializza il database con dati di default
    await _inizializzaDatiDefault(db);
  }

  /// Inizializza il database con categorie e specie di default.
  /// Questo metodo viene chiamato solo se il database è vuoto.
  Future<void> _inizializzaDatiDefault(Database db) async {
    try {
      // Inserisce categoria di default
      final categoriaId = await db.insert('categorie', {
        'nome': 'Piante da interno',
      });
      
      // Inserisce specie di default
      await db.insert('specie', {
        'nome': 'Pianta generica',
        'descrizione': 'Una pianta da interno generica per iniziare',
        'idCategoria': categoriaId,
      });
      
      print('Database inizializzato con dati di default');
    } catch (e) {
      print('Errore durante l\'inizializzazione dei dati di default: $e');
    }
  }

  // ========================================
  // OPERAZIONI CRUD PER PIANTA
  // ========================================

  /// Inserisce una nuova pianta nel database.
  Future<int> addPianta(Pianta pianta) async {
    final db = await database;
    return await db.insert('piante', pianta.toMap());
  }

  /// Recupera una singola pianta tramite il suo ID.
  Future<Pianta?> getPianta(int id) async {
    final db = await database;
    final maps = await db.query(
      'piante',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Pianta.fromMap(maps.first);
    }
    return null;
  }

  /// Recupera tutte le piante dal database.
  Future<List<Pianta>> getAllPiante() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('piante');
    return List.generate(maps.length, (i) => Pianta.fromMap(maps[i]));
  }

  /// Recupera le piante più recenti ordinate per data di acquisto.
  Future<List<Pianta>> getPianteRecenti({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'piante',
      orderBy: 'dataAcquisto DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Pianta.fromMap(maps[i]));
  }

  /// Aggiorna una pianta esistente.
  Future<int> updatePianta(Pianta pianta) async {
    final db = await database;
    return await db.update(
      'piante',
      pianta.toMap(),
      where: 'id = ?',
      whereArgs: [pianta.id],
    );
  }

  /// Elimina una pianta tramite il suo ID.
  Future<int> deletePianta(int id) async {
    final db = await database;
    return await db.delete(
      'piante',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // OPERAZIONI CRUD PER CATEGORIA
  // ========================================

  /// Inserisce una nuova categoria nel database.
  Future<int> addCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categorie', categoria.toMap());
  }

  /// Recupera una singola categoria tramite il suo ID.
  Future<Categoria?> getCategoria(int id) async {
    final db = await database;
    final maps = await db.query(
      'categorie',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Categoria.fromMap(maps.first);
    }
    return null;
  }

  /// Recupera tutte le categorie dal database.
  Future<List<Categoria>> getAllCategorie() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categorie');
    return List.generate(maps.length, (i) => Categoria.fromMap(maps[i]));
  }

  /// Aggiorna una categoria esistente.
  Future<int> updateCategoria(Categoria categoria) async {
    final db = await database;
    return await db.update(
      'categorie',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  /// Elimina una categoria tramite il suo ID.
  /// Grazie a ON DELETE CASCADE, verranno eliminate anche tutte le specie
  /// e le piante associate a questa categoria.
  Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await db.delete(
      'categorie',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // OPERAZIONI CRUD PER SPECIE
  // ========================================

  /// Inserisce una nuova specie nel database.
  Future<int> addSpecie(Specie specie) async {
    final db = await database;
    return await db.insert('specie', specie.toMap());
  }

  /// Recupera una singola specie tramite il suo ID.
  Future<Specie?> getSpecie(int id) async {
    final db = await database;
    final maps = await db.query(
      'specie',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Specie.fromMap(maps.first);
    }
    return null;
  }

  /// Recupera tutte le specie dal database.
  Future<List<Specie>> getAllSpecie() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('specie');
    return List.generate(maps.length, (i) => Specie.fromMap(maps[i]));
  }

  /// Recupera tutte le specie appartenenti a una determinata categoria.
  /// Molto utile per i filtri nell'interfaccia utente.
  Future<List<Specie>> getSpecieByCategoria(int idCategoria) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'specie',
      where: 'idCategoria = ?',
      whereArgs: [idCategoria],
    );
    return List.generate(maps.length, (i) => Specie.fromMap(maps[i]));
  }

  /// Aggiorna una specie esistente.
  Future<int> updateSpecie(Specie specie) async {
    final db = await database;
    return await db.update(
      'specie',
      specie.toMap(),
      where: 'id = ?',
      whereArgs: [specie.id],
    );
  }

  /// Elimina una specie tramite il suo ID.
  /// Grazie a ON DELETE CASCADE, verranno eliminate anche tutte le piante
  /// associate a questa specie.
  Future<int> deleteSpecie(int id) async {
    final db = await database;
    return await db.delete(
      'specie',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // ========================================
  // OPERAZIONI CRUD PER ATTIVITA CURA
  // ========================================

  /// Inserisce una nuova attività di cura nel database.
  Future<int> addAttivitaCura(AttivitaCura attivita) async {
    final db = await database;
    return await db.insert('attivitaCura', attivita.toMap());
  }

  /// Recupera una singola attività di cura tramite il suo ID.
  Future<AttivitaCura?> getAttivitaCura(int id) async {
    final db = await database;
    final maps = await db.query(
      'attivitaCura',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AttivitaCura.fromMap(maps.first);
    }
    return null;
  }

  /// Recupera tutte le attività di cura dal database.
  Future<List<AttivitaCura>> getAllAttivitaCura() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('attivitaCura');
    return List.generate(maps.length, (i) => AttivitaCura.fromMap(maps[i]));
  }

  /// Recupera tutte le attività di cura per una specifica pianta.
  Future<List<AttivitaCura>> getAttivitaCuraByPianta(int idPianta) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attivitaCura',
      where: 'idPianta = ?',
      whereArgs: [idPianta],
      orderBy: 'data DESC',
    );
    return List.generate(maps.length, (i) => AttivitaCura.fromMap(maps[i]));
  }

  /// Aggiorna un'attività di cura esistente.
  Future<int> updateAttivitaCura(AttivitaCura attivita) async {
    final db = await database;
    return await db.update(
      'attivitaCura',
      attivita.toMap(),
      where: 'id = ?',
      whereArgs: [attivita.id],
    );
  }

  /// Elimina un'attività di cura tramite il suo ID.
  Future<int> deleteAttivitaCura(int id) async {
    final db = await database;
    return await db.delete(
      'attivitaCura',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Recupera l'ultima attività di un determinato tipo per una pianta.
  /// Utile per calcolare le prossime scadenze.
  Future<DateTime?> getUltimaAttivita(int idPianta, String tipoAttivita) async {
    final db = await database;
    final maps = await db.query(
      'attivitaCura',
      where: 'idPianta = ? AND tipoAttivita = ?',
      whereArgs: [idPianta, tipoAttivita],
      orderBy: 'data DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['data'] as String);
    }
    return null;
  }

  /// Recupera tutte le attività di cura per un determinato tipo.
  Future<List<AttivitaCura>> getAttivitaCuraByTipo(String tipoAttivita) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attivitaCura',
      where: 'tipoAttivita = ?',
      whereArgs: [tipoAttivita],
      orderBy: 'data DESC',
    );
    return List.generate(maps.length, (i) => AttivitaCura.fromMap(maps[i]));
  }

  // ========================================
  // METODI UTILITY
  // ========================================

  /// Chiude la connessione al database.
  /// Utile per liberare risorse quando l'app viene chiusa.
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Elimina il database e lo ricrea.
  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
    await _initDB();
  }

  /// Verifica se il database è vuoto e lo inizializza con dati di default se necessario.
  /// 
  /// Questo metodo controlla se esistono categorie nel database. Se non ce ne sono,
  /// aggiunge automaticamente una categoria e una specie di default per permettere
  /// agli utenti di iniziare subito a usare l'app.
  /// 
  Future<void> inizializzaSeVuoto() async {
    try {
      final db = await database;
      
      // Controlla se esistono categorie
      final categorie = await db.query('categorie', limit: 1);
      
      // Se non ci sono categorie, inizializza con dati di default
      if (categorie.isEmpty) {
        await _inizializzaDatiDefault(db);
        print('Database vuoto inizializzato con dati di default');
      }
    } catch (e) {
      print('Errore durante la verifica del database: $e');
    }
  }
}
