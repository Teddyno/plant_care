import 'package:sqflite/sqflite.dart';
import '../../services/db/DatabaseHelper.dart';
import '../AttivitaCuraModel.dart';

class AttivitaCuraRepository {
  AttivitaCuraRepository._privateConstructor();
  static final AttivitaCuraRepository instance = AttivitaCuraRepository._privateConstructor();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<AttivitaCura>> getTutteLeAttivita() async {
    return await _dbHelper.getAllAttivitaCura();
  }

  Future<AttivitaCura?> getAttivita(int id) async {
    return await _dbHelper.getAttivitaCura(id);
  }

  Future<List<AttivitaCura>> getAttivitaByPianta(int idPianta) async {
    return await _dbHelper.getAttivitaCuraByPianta(idPianta);
  }

  Future<List<AttivitaCura>> getAttivitaByTipo(String tipoAttivita) async {
    return await _dbHelper.getAttivitaCuraByTipo(tipoAttivita);
  }

  Future<void> aggiungiAttivita(AttivitaCura attivita) async {
    await _dbHelper.addAttivitaCura(attivita);
  }

  Future<void> aggiornaAttivita(AttivitaCura attivita) async {
    await _dbHelper.updateAttivitaCura(attivita);
  }

  Future<void> eliminaAttivita(int id) async {
    await _dbHelper.deleteAttivitaCura(id);
  }

  /// Ottiene le attività raggruppate per mese negli ultimi 12 mesi
  Future<List<double>> getAttivitaMensili() async {
    final attivita = await getTutteLeAttivita();
    final now = DateTime.now();
    final List<double> attivitaMensili = List.filled(12, 0.0);
    
    for (var attivita in attivita) {
      final mesiFa = now.difference(attivita.data).inDays ~/ 30;
      if (mesiFa < 12) {
        attivitaMensili[11 - mesiFa]++;
      }
    }
    
    return attivitaMensili;
  }
} 