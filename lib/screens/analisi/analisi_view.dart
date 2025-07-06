import 'package:flutter/material.dart';
import '../../components/grafici/pie_chart.dart';
import '../../components/grafici/line_chart.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/CategoriaModel.dart';
import '../../models/AttivitaCuraModel.dart';
import '../../models/repository/PianteRepository.dart';
import '../../models/repository/SpecieRepository.dart';
import '../../models/repository/CategorieRepository.dart';
import '../../models/repository/AttivitaCuraRepository.dart';

/// Schermata che mostra analisi e statistiche avanzate sulla collezione di piante.
/// Include metriche dettagliate, grafici interattivi e timeline delle attività.
/// Fornisce una panoramica completa della gestione e dello stato delle piante.
class AnalisiView extends StatefulWidget {
  const AnalisiView({super.key});

  @override
  State<AnalisiView> createState() => _AnalisiViewState();
}

class _AnalisiViewState extends State<AnalisiView> {
  final PianteRepository _pianteRepository = PianteRepository();
  final SpecieRepository _specieRepository = SpecieRepository.instance;
  final CategorieRepository _categorieRepository = CategorieRepository.instance;
  final AttivitaCuraRepository _attivitaRepository = AttivitaCuraRepository.instance;

  List<Pianta> _piante = [];
  List<Specie> _tutteLeSpecie = [];
  List<Categoria> _tutteLeCategorie = [];
  List<AttivitaCura> _tutteLeAttivita = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  /// Carica i dati dal database
  Future<void> _caricaDati() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carica i dati in parallelo per migliorare le performance
      final futures = await Future.wait([
        _pianteRepository.getTutteLePiante(),
        _specieRepository.getTutteLeSpecie(),
        _categorieRepository.getTutteLeCategorie(),
        _attivitaRepository.getTutteLeAttivita(),
      ]);

      setState(() {
        _piante = futures[0] as List<Pianta>;
        _tutteLeSpecie = futures[1] as List<Specie>;
        _tutteLeCategorie = futures[2] as List<Categoria>;
        _tutteLeAttivita = futures[3] as List<AttivitaCura>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Errore nel caricamento dei dati: $e');
    }
  }

  /// Restituisce la specie corrispondente all'ID della specie
  Specie? _getSpecieById(int idSpecie) {
    try {
      return _tutteLeSpecie.firstWhere((specie) => specie.id == idSpecie);
    } catch (e) {
      return null;
    }
  }

  /// Restituisce la categoria corrispondente all'ID della categoria
  Categoria? _getCategoriaById(int idCategoria) {
    try {
      return _tutteLeCategorie.firstWhere((categoria) => categoria.id == idCategoria);
    } catch (e) {
      return null;
    }
  }

  /// Calcola la distribuzione delle piante per categoria
  Map<String, int> get _distribuzioneCategorie {
    final Map<String, int> distribuzione = {};
    
    for (var pianta in _piante) {
      final specie = _getSpecieById(pianta.idSpecie);
      final categoria = specie != null ? _getCategoriaById(specie.idCategoria) : null;
      final nomeCategoria = categoria?.nome ?? 'Senza categoria';
      
      distribuzione[nomeCategoria] = (distribuzione[nomeCategoria] ?? 0) + 1;
    }
    
    return distribuzione;
  }

  /// Calcola le attività mensili degli ultimi 12 mesi
  List<double> get _attivitaMensili {
    final now = DateTime.now();
    final List<double> attivitaMensili = List.filled(12, 0.0);
    
    for (var attivita in _tutteLeAttivita) {
      final mesiFa = now.difference(attivita.data).inDays ~/ 30;
      if (mesiFa < 12) {
        attivitaMensili[11 - mesiFa]++;
      }
    }
    
    return attivitaMensili;
  }

  /// Calcola lo stato generale della collezione
  Map<String, dynamic> get _statoCollezione {
    final pianteTotali = _piante.length;
    final attivitaCompletate = _tutteLeAttivita.length;
    final percentualeAttivita = pianteTotali > 0 ? attivitaCompletate / (pianteTotali * 2) : 0.0; // esempio: 2 attività per pianta
    
    String statoTesto;
    Color statoColore;
    IconData statoIcona;
    
    if (percentualeAttivita >= 0.7) {
      statoTesto = 'Collezione in ottima salute';
      statoColore = Colors.green.shade100;
      statoIcona = Icons.sentiment_very_satisfied;
    } else if (percentualeAttivita >= 0.4) {
      statoTesto = 'Collezione da monitorare';
      statoColore = Colors.orange.shade100;
      statoIcona = Icons.sentiment_neutral;
    } else {
      statoTesto = 'Attenzione: molte attività non eseguite';
      statoColore = Colors.red.shade100;
      statoIcona = Icons.sentiment_dissatisfied;
    }
    
    return {
      'testo': statoTesto,
      'colore': statoColore,
      'icona': statoIcona,
      'percentuale': percentualeAttivita,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pianteTotali = _piante.length;
    final distribuzioneCategorie = _distribuzioneCategorie;
    final attivitaMensili = _attivitaMensili;
    final statoCollezione = _statoCollezione;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _caricaDati,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Numero totale di piante
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.eco, color: Colors.green[700], size: 48),
                        const SizedBox(height: 8),
                        Text('$pianteTotali', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 4),
                        const Text('Numero totale di piante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 2. Distribuzione per tipologia/categoria
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Distribuzione per tipologia/categoria',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 260,
                          child: PlantPieChart(conteggioCategorie: distribuzioneCategorie),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 3. Attività di cura eseguite (grafico mensile)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Attività di cura eseguite (ultimi 12 mesi)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: PlantBarChart(
                            labels: List.generate(12, (i) => (i + 1).toString()),
                            values: attivitaMensili,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
