/*
 * DASHBOARD VIEW - SCHERMATA PRINCIPALE DELLA HOME
 * 
 * Questo file contiene la dashboard principale dell'app FloraManager.
 * È la prima schermata che l'utente vede quando apre l'app e fornisce
 * una panoramica completa della collezione di piante.
 * 
 * SEZIONI PRINCIPALI:
 * 1. Ultime piante aggiunte - Lista delle piante più recenti
 * 2. Promemoria attività di cura - Attività imminenti da completare
 * */

import 'package:flutter/material.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/PromemoriaModel.dart';
import '../../models/repository/PianteRepository.dart';
import '../../models/repository/SpecieRepository.dart';
import '../../models/repository/PromemoriaRepository.dart';
import 'piante_detail_view.dart';

/// Schermata dashboard principale che mostra una panoramica della collezione di piante.
/// 
/// Questa schermata è il punto di ingresso principale dell'app e fornisce:
/// - Una vista d'insieme della collezione
/// - Accesso rapido alle informazioni più importanti
/// - Gestione delle attività di cura imminenti
/// - Navigazione ai dettagli delle piante

class PianteDashboardView extends StatefulWidget {

  const PianteDashboardView({super.key});

  @override
  State<PianteDashboardView> createState() => PianteDashboardViewState();
}

/// Stato interno della schermata dashboard.
/// 
class PianteDashboardViewState extends State<PianteDashboardView> {
  final PianteRepository _pianteRepository = PianteRepository();
  final SpecieRepository _specieRepository = SpecieRepository.instance;
  final PromemoriaRepository _promemoriaRepository = PromemoriaRepository();

  List<Pianta> _pianteRecenti = [];
  List<Promemoria> _promemoriaImminenti = [];
  List<Specie> _tutteLeSpecie = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  /// Carica i dati dal database all'avvio e quando richiesto.
  /// 
  /// Questo metodo recupera:
  /// - Le piante più recenti
  /// - I promemoria imminenti
  /// - Le specie per le informazioni complete
  Future<void> _caricaDati() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _pianteRepository.getPianteRecenti(limit: 5),
        _promemoriaRepository.getPromemoriaImminenti(),
        _specieRepository.getTutteLeSpecie(),
      ]);

      setState(() {
        _pianteRecenti = futures[0] as List<Pianta>;
        _promemoriaImminenti = futures[1] as List<Promemoria>;
        _tutteLeSpecie = futures[2] as List<Specie>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Errore nel caricamento dei dati: $e');
    }
  }

  /// Metodo pubblico per forzare il refresh dei dati.
  /// 
  /// Questo metodo viene chiamato esternamente (ad esempio dal MainView)
  /// per aggiornare la dashboard dopo modifiche ai dati.
  /// 
  void refresh() {
    _caricaDati();
  }

  /// Restituisce la specie corrispondente all'ID della specie.
  /// 
  Specie? _getSpecieById(int idSpecie) {
    try {
      return _tutteLeSpecie.firstWhere((specie) => specie.id == idSpecie);
    } catch (e) {
      return null;
    }
  }

  /// Formatta una data in formato leggibile.
  /// 
  String _formattaData(DateTime data) {
    final oggi = DateTime.now();
    final differenza = oggi.difference(data).inDays;

    if (differenza == 0) {
      return 'Oggi';
    } else if (differenza == 1) {
      return 'Ieri';
    } else if (differenza < 7) {
      return '$differenza giorni fa';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }

  /// Formatta la data di scadenza di un promemoria.
  /// 
  String _formattaScadenza(DateTime dataScadenza) {
    final oggi = DateTime.now();
    final differenza = dataScadenza.difference(oggi).inDays;

    if (differenza < 0) {
      return 'Scaduto ${differenza.abs()} giorni fa';
    } else if (differenza == 0) {
      return 'Oggi';
    } else if (differenza == 1) {
      return 'Domani';
    } else if (differenza < 7) {
      return 'Tra $differenza giorni';
        } else {
      return 'Tra ${(differenza / 7).round()} settimane';
    }
  }

  /// Restituisce l'icona appropriata per il tipo di attività.
  /// 
  IconData _getAttivitaIcon(TipoAttivita tipoAttivita) {
    switch (tipoAttivita) {
      case TipoAttivita.innaffiatura:
        return Icons.water_drop;
      case TipoAttivita.potatura:
        return Icons.content_cut;
      case TipoAttivita.rinvaso:
        return Icons.grass;
      default:
        return Icons.eco;
    }
  }

  /// Restituisce il colore appropriato per il tipo di attività.
  /// 
  Color _getAttivitaColor(TipoAttivita tipoAttivita) {
    switch (tipoAttivita) {
      case TipoAttivita.innaffiatura:
        return Colors.blue;
      case TipoAttivita.potatura:
        return Colors.green;
      case TipoAttivita.rinvaso:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  /// Restituisce l'icona e il colore appropriati per lo stato della pianta.
  /// 
  Widget _getStatoIcon(String stato) {
    IconData icon;
    Color color;
    
    switch (stato.toLowerCase()) {
      case 'sana':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'in crescita':
        icon = Icons.trending_up;
        color = Colors.blue;
        break;
      case 'malata':
        icon = Icons.sick;
        color = Colors.red;
        break;
      case 'in riposo':
        icon = Icons.bedtime;
        color = Colors.purple;
        break;
      case 'necessita cure':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'in fioritura':
        icon = Icons.local_florist;
        color = Colors.pink;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color, size: 16);
  }

  /// Costruisce l'interfaccia utente della schermata dashboard.
  /// 
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _caricaDati,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ========================================
        // SEZIONE: ULTIME PIANTE AGGIUNTE
        // ========================================
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
            ),
              borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ultime piante aggiunte',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
                const SizedBox(height: 16),
                
                if (_pianteRecenti.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Nessuna pianta aggiunta ancora',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ..._pianteRecenti.map((pianta) {
                    final specie = _getSpecieById(pianta.idSpecie);
                    return Container(
                      key: ValueKey(pianta.id),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                        leading: pianta.foto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  pianta.foto!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_florist,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                        
                  title: Text(
                          pianta.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            if (specie != null)
                      Text(
                                specie.nome,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                            Text(
                              'Acquisita il: ${_formattaData(pianta.dataAcquisto)}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                _getStatoIcon(pianta.stato),
                                const SizedBox(width: 4),
                                Text(
                                  pianta.stato,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                    ],
                  ),
                          ],
                        ),
                        
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                  
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PianteDetailView(pianta: pianta),
                      ),
                    );
                  },
                ),
                    );
                  }).toList(),
            ],
          ),
        ),
        
          const SizedBox(height: 24),
        
        // ========================================
        // SEZIONE: PROMEMORIA ATTIVITÀ DI CURA
        // ========================================
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promemoria attività di cura imminenti',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 16),
              
                if (_promemoriaImminenti.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Nessuna attività imminente',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ..._promemoriaImminenti.map((promemoria) {
                    final scadenza = _formattaScadenza(promemoria.dataScadenza);
                    final isScaduto = promemoria.dataScadenza.isBefore(DateTime.now());
                    
                    return Container(
                      key: ValueKey('${promemoria.pianta.id}_${promemoria.attivita}'),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                        color: isScaduto ? Colors.red.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                            color: _getAttivitaColor(promemoria.attivita).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                            _getAttivitaIcon(promemoria.attivita),
                            color: _getAttivitaColor(promemoria.attivita),
                      size: 20,
                    ),
                  ),
                  
                  title: Text(
                          _getAttivitaNome(promemoria.attivita),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                            color: isScaduto ? Colors.red : Colors.black,
                    ),
                  ),
                  
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promemoria.pianta.nome,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              scadenza,
                              style: TextStyle(
                                color: isScaduto ? Colors.red : Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                      ),
                    ),
                          ],
                        ),
                        
                        trailing: isScaduto
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'URGENTE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                    ),
                  ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
            ],
          ),
        ),
      ],
      ),
    );
  }

  /// Restituisce il nome leggibile del tipo di attività.
  /// 
  String _getAttivitaNome(TipoAttivita tipoAttivita) {
    switch (tipoAttivita) {
      case TipoAttivita.innaffiatura:
        return 'Innaffiatura';
      case TipoAttivita.potatura:
        return 'Potatura';
      case TipoAttivita.rinvaso:
        return 'Rinvaso';
      default:
        return 'Attività';
    }
  }
} 