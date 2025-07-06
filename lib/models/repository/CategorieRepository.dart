import 'package:sqflite/sqflite.dart';
import '../../services/db/DatabaseHelper.dart';
import '../CategoriaModel.dart';

class CategorieRepository {
  CategorieRepository._privateConstructor();
  static final CategorieRepository instance = CategorieRepository._privateConstructor();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Categoria>> getTutteLeCategorie() async {
    return await _dbHelper.getAllCategorie();
  }

  Future<Categoria?> getCategoria(int id) async {
    return await _dbHelper.getCategoria(id);
  }

  Future<void> aggiungiCategoria(Categoria categoria) async {
    await _dbHelper.addCategoria(categoria);
  }

  Future<void> aggiornaCategoria(Categoria categoria) async {
    await _dbHelper.updateCategoria(categoria);
  }

  Future<void> eliminaCategoria(int id) async {
    await _dbHelper.deleteCategoria(id);
  }
}