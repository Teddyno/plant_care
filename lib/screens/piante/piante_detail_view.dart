import 'package:flutter/material.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/AttivitaCuraModel.dart';
import '../../models/repository/SpecieRepository.dart';
import '../../models/repository/PianteRepository.dart';
import '../../services/db/DatabaseHelper.dart';

/// Schermata che mostra i dettagli di una pianta specifica.
/// Permette di visualizzare le informazioni della pianta e le relative attività di cura.
/// Include funzionalità per modificare la pianta e gestire le attività di cura.
class PianteDetailView extends StatefulWidget {
  /// Pianta di cui mostrare i dettagli
  final Pianta pianta;
  
  /// Costruttore della schermata dettagli pianta
  const PianteDetailView({super.key, required this.pianta});

  @override
  State<PianteDetailView> createState() => _PianteDetailViewState();
}

/// Stato interno della schermata dettagli pianta.
/// Gestisce la modifica della pianta e le attività di cura associate.
class _PianteDetailViewState extends State<PianteDetailView> {
  /// Pianta corrente (può essere modificata)
  late Pianta _pianta;
  
  /// Attività di cura della pianta
  List<AttivitaCura> _attivita = [];
  
  /// Specie della pianta
  Specie? _specie;
  
  /// Repository per le operazioni sui dati
  final PianteRepository _pianteRepository = PianteRepository();
  final SpecieRepository _specieRepository = SpecieRepository.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  /// Note personali della pianta (gestite localmente)
  String _notePersonali = '';
  
  /// Stato di caricamento
  bool _isLoading = true;

  /// Inizializza lo stato e carica i dati
  @override
  void initState() {
    super.initState();
    _pianta = widget.pianta;
    _notePersonali = widget.pianta.note ?? '';
    _caricaDati();
  }

  /// Carica i dati della pianta dal database
  Future<void> _caricaDati() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carica la specie della pianta
      _specie = await _specieRepository.getSpecie(_pianta.idSpecie);
      
      // Carica le attività di cura della pianta
      _attivita = await _dbHelper.getAttivitaCuraByPianta(_pianta.id!);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Errore nel caricamento dei dati: $e');
    }
  }

  /// Formatta una data in formato leggibile
  String _formattaData(DateTime data) {
    return '${data.day}/${data.month}/${data.year}';
  }

  /// Restituisce l'icona appropriata per il tipo di attività
  IconData _getActivityIcon(String tipo) {
    switch (tipo) {
      case 'innaffiatura':
        return Icons.water_drop;
      case 'potatura':
        return Icons.content_cut;
      case 'rinvaso':
        return Icons.grass;
      default:
        return Icons.task;
    }
  }

  /// Restituisce il colore appropriato per il tipo di attività
  Color _getActivityColor(String tipo) {
    switch (tipo) {
      case 'innaffiatura':
        return Colors.blue;
      case 'potatura':
        return Colors.green;
      case 'rinvaso':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  /// Modifica i dati della pianta tramite un dialog.
  /// Permette di cambiare nome, note e stato.
  Future<void> _modificaPianta() async {
    final nomeController = TextEditingController(text: _pianta.nome);
    final noteController = TextEditingController(text: _pianta.note ?? '');
    String stato = _pianta.stato;
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Modifica pianta'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo nome
                TextFormField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome pianta',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Inserisci un nome' : null,
                ),
                const SizedBox(height: 16),
                
                // Campo note
                TextFormField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Dropdown stato
                DropdownButtonFormField<String>(
                  value: stato,
                  decoration: InputDecoration(
                    labelText: 'Stato',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: [
                    'Sana',
                    'In crescita',
                    'Malata',
                    'In riposo',
                    'Necessita cure',
                    'In fioritura',
                  ].map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  )).toList(),
                  onChanged: (v) => stato = v ?? 'Sana',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Aggiorna la pianta con i nuovi dati
      final piantaAggiornata = Pianta(
        id: _pianta.id,
        nome: nomeController.text.trim(),
        dataAcquisto: _pianta.dataAcquisto,
        foto: _pianta.foto,
        frequenzaInnaffiatura: _pianta.frequenzaInnaffiatura,
        frequenzaPotatura: _pianta.frequenzaPotatura,
        frequenzaRinvaso: _pianta.frequenzaRinvaso,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        stato: stato,
        idSpecie: _pianta.idSpecie,
      );

      try {
        await _pianteRepository.aggiornaPianta(piantaAggiornata);
        setState(() {
          _pianta = piantaAggiornata;
          _notePersonali = piantaAggiornata.note ?? '';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pianta aggiornata con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'aggiornamento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Elimina un'attività di cura.
  void _eliminaAttivita(AttivitaCura attivita) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Elimina attività'),
          ],
        ),
        content: Text('Sei sicuro di voler eliminare questa attività di cura?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _dbHelper.deleteAttivitaCura(attivita.id!);
        
        setState(() {
          _attivita.removeWhere((a) => a.id == attivita.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attività eliminata con successo'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'eliminazione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Modifica un'attività di cura esistente.
  void _modificaAttivita(AttivitaCura attivita) async {
    String tipoAttivita = attivita.tipoAttivita;
    DateTime data = attivita.data;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Modifica attività'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown tipo attività
            DropdownButtonFormField<String>(
              value: tipoAttivita,
              decoration: InputDecoration(
                labelText: 'Tipo attività',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: [
                'innaffiatura',
                'potatura',
                'rinvaso',
              ].map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.capitalize()),
              )).toList(),
              onChanged: (v) => tipoAttivita = v ?? 'innaffiatura',
            ),
            const SizedBox(height: 16),
            
            // Campo data
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: data,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  data = date;
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                child: Text(_formattaData(data)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final attivitaAggiornata = AttivitaCura(
          id: attivita.id,
          idPianta: attivita.idPianta,
          tipoAttivita: tipoAttivita,
          data: data,
        );
        
        await _dbHelper.updateAttivitaCura(attivitaAggiornata);
        
        setState(() {
          final index = _attivita.indexOf(attivita);
          if (index != -1) {
            _attivita[index] = attivitaAggiornata;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attività aggiornata con successo'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'aggiornamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Aggiunge una nuova attività di cura.
  void _aggiungiAttivita() async {
    String tipoAttivita = 'innaffiatura';
    DateTime data = DateTime.now().add(const Duration(days: 1));
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Aggiungi attività'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown tipo attività
            DropdownButtonFormField<String>(
              value: tipoAttivita,
              decoration: InputDecoration(
                labelText: 'Tipo attività',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: [
                'innaffiatura',
                'potatura',
                'rinvaso',
              ].map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.capitalize()),
              )).toList(),
              onChanged: (v) => tipoAttivita = v ?? 'innaffiatura',
            ),
            const SizedBox(height: 16),
            
            // Campo data
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: data,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  data = date;
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                child: Text(_formattaData(data)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final nuovaAttivita = AttivitaCura(
          idPianta: _pianta.id!,
          tipoAttivita: tipoAttivita,
          data: data,
        );
        
        final id = await _dbHelper.addAttivitaCura(nuovaAttivita);
        
        setState(() {
          _attivita.add(AttivitaCura(
            id: id,
            idPianta: _pianta.id!,
            tipoAttivita: tipoAttivita,
            data: data,
          ));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attività aggiunta con successo'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'aggiunta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Costruisce l'interfaccia utente della schermata dettagli
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Caricamento...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header semplice
          SliverAppBar(
            title: Text(_pianta.nome),
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _modificaPianta,
                tooltip: 'Modifica pianta',
              ),
            ],
          ),
          
          // Contenuto principale
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Sezione informazioni generali
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header sezione semplificato
                            Row(
                              children: [
                                Image.asset('assets/icon.png', width: 60, height: 60),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_pianta.nome, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                      Text(_specie?.nome ?? 'Specie sconosciuta', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                      Text('Acquisita il: ${_formattaData(_pianta.dataAcquisto)}', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                      Text('Innaffiatura: ogni ${_pianta.frequenzaInnaffiatura} giorni', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Sezione attività di cura
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header sezione semplificato
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Attività di Cura',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 28,
                                  ),
                                  onPressed: _aggiungiAttivita,
                                  tooltip: 'Aggiungi attività',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Lista attività
                            _attivita.isEmpty
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.task_outlined,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Nessuna attività registrata',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Aggiungi la tua prima attività di cura!',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      // Lista delle attività
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _attivita.length,
                                        itemBuilder: (context, index) {
                                          final a = _attivita[index];
                                          final tipo = a.tipoAttivita;
                                           
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.withOpacity(0.15),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.04),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              leading: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: _getActivityColor(tipo).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _getActivityIcon(tipo),
                                                  color: _getActivityColor(tipo),
                                                  size: 20,
                                                ),
                                              ),
                                              title: Text(
                                                tipo.capitalize(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.green),
                                                    onPressed: () => _modificaAttivita(a),
                                                    tooltip: 'Modifica',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _eliminaAttivita(a),
                                                    tooltip: 'Elimina',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Sezione note personali
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_alt, color: Theme.of(context).colorScheme.primary, size: 28),
                                const SizedBox(width: 12),
                                Text('Note personali', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _notePersonali,
                              maxLines: 4,
                              minLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Aggiungi qui le tue note personali su questa pianta...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onChanged: (v) => setState(() => _notePersonali = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estensione per capitalizzare la prima lettera
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
} 