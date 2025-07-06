import '../../services/db/DatabaseHelper.dart';
import '../PiantaModel.dart';

class PianteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Pianta>> getTutteLePiante() async {
    return await _dbHelper.getAllPiante();
  }

  Future<Pianta?> getPianta(int id) async {
    return await _dbHelper.getPianta(id);
  }

  Future<void> aggiungiPianta(Pianta pianta) async {
    await _dbHelper.addPianta(pianta);
  }

  Future<void> aggiornaPianta(Pianta pianta) async {
    await _dbHelper.updatePianta(pianta);
  }

  Future<void> eliminaPianta(int id) async {
    await _dbHelper.deletePianta(id);
  }

  Future<List<Pianta>> getPianteRecenti({int limit = 5}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'piante',
      orderBy: 'dataAcquisto DESC',
      limit: limit,
    );
    return maps.map((map) => Pianta.fromMap(map)).toList();
  }
}
