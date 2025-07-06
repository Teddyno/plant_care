import 'package:sqflite/sqflite.dart';
import '../../services/db/DatabaseHelper.dart';
import '../SpecieModel.dart';

class SpecieRepository {
  SpecieRepository._privateConstructor();
  static final SpecieRepository instance = SpecieRepository._privateConstructor();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Specie>> getTutteLeSpecie() async {
    return await _dbHelper.getAllSpecie();
  }

  Future<Specie?> getSpecie(int id) async {
    return await _dbHelper.getSpecie(id);
  }

  Future<List<Specie>> getSpecieByCategoria(int idCategoria) async {
    return await _dbHelper.getSpecieByCategoria(idCategoria);
  }

  Future<void> aggiungiSpecie(Specie specie) async {
    await _dbHelper.addSpecie(specie);
  }

  Future<void> aggiornaSpecie(Specie specie) async {
    final db = await _dbHelper.database;
    await db.update(
      'specie',
      specie.toMap(),
      where: 'id = ?',
      whereArgs: [specie.id],
    );
  }

  Future<void> eliminaSpecie(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'specie',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
