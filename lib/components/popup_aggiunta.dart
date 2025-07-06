/*
 * POPUP AGGIUNTA PIANTA - COMPONENTE PER AGGIUNGERE NUOVE PIANTE
 * 
 * Questo file contiene il popup per l'aggiunta di nuove piante
 * alla collezione. Si apre dal basso dello schermo e fornisce un form
 * completo per inserire tutti i dati necessari di una pianta.
 * 
 */

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/PiantaModel.dart';
import '../models/SpecieModel.dart';
import '../models/CategoriaModel.dart';
import '../models/repository/PianteRepository.dart';
import '../models/repository/SpecieRepository.dart';
import '../models/repository/CategorieRepository.dart';

/// Widget popup per l'aggiunta di una nuova pianta alla collezione.
/// 
class PopupAggiunta extends StatefulWidget {

  const PopupAggiunta({super.key});

  @override
  State<PopupAggiunta> createState() => _PopupAggiuntaState();
}

/// Stato interno del popup di aggiunta pianta.
/// 
class _PopupAggiuntaState extends State<PopupAggiunta> {
  /// Chiave per la validazione del form.
  /// 
  /// Utilizzata per accedere al FormState e validare
  /// tutti i campi prima del salvataggio.
  final _formKey = GlobalKey<FormState>();
  
  /// Controller per il campo nome della pianta.
  /// 
  /// Gestisce il testo inserito dall'utente nel campo
  /// "Nome pianta" e fornisce metodi per manipolare il contenuto.
  final _nomeController = TextEditingController();
  
  /// Controller per il campo frequenza di innaffiatura.
  /// 
  /// Gestisce il testo inserito dall'utente nel campo
  /// "Frequenza innaffiatura" e fornisce metodi per manipolare il contenuto.
  final _frequenzaInnaffiaturaController = TextEditingController();
  
  /// Controller per il campo frequenza di potatura.
  /// 
  /// Gestisce il testo inserito dall'utente nel campo
  /// "Frequenza potatura" e fornisce metodi per manipolare il contenuto.
  final _frequenzaPotaturaController = TextEditingController();
  
  /// Controller per il campo frequenza di rinvaso.
  /// 
  /// Gestisce il testo inserito dall'utente nel campo
  /// "Frequenza rinvaso" e fornisce metodi per manipolare il contenuto.
  final _frequenzaRinvasoController = TextEditingController();
  
  /// Controller per il campo note.
  /// 
  /// Gestisce il testo inserito dall'utente nel campo
  /// "Note" e fornisce metodi per manipolare il contenuto.
  final _noteController = TextEditingController();
  
  /// Controller per il campo nuova categoria.
  /// 
  /// Gestisce il testo inserito dall'utente quando crea
  /// una nuova categoria.
  final _nuovaCategoriaController = TextEditingController();
  
  /// Controller per il campo nuova specie.
  /// 
  /// Gestisce il testo inserito dall'utente quando crea
  /// una nuova specie.
  final _nuovaSpecieController = TextEditingController();
  
  /// Data di acquisto della pianta selezionata dall'utente.
  /// 
  DateTime? _dataAcquisto;

  /// File della foto selezionata dall'utente.
  /// 
  /// Utilizzato per mostrare l'anteprima e convertire in BLOB.
  File? _foto;
  
  /// Picker per selezionare le immagini dalla galleria.
  final ImagePicker _picker = ImagePicker();

  /// Lista delle categorie disponibili nel database.
  /// 
  /// Caricata all'inizializzazione del widget.
  List<Categoria> _categorie = [];
  
  /// Lista delle specie disponibili per la categoria selezionata.
  /// 
  /// Aggiornata quando l'utente cambia categoria.
  List<Specie> _specie = [];
  
  /// Categoria attualmente selezionata.
  /// 
  /// Utilizzata per filtrare le specie disponibili.
  Categoria? _categoriaSelezionata;
  
  /// Specie attualmente selezionata.
  /// 
  /// Utilizzata per creare la pianta nel database.
  Specie? _specieSelezionata;
  
  /// Stato della pianta attualmente selezionato.
  /// 
  /// Utilizzato per creare la pianta nel database.
  String _statoSelezionato = 'Sana';
  
  /// Indica se l'utente sta creando una nuova categoria.
  /// 
  /// Quando true, mostra il campo di input per la nuova categoria.
  bool _creandoNuovaCategoria = false;
  
  /// Indica se l'utente sta creando una nuova specie.
  /// 
  /// Quando true, mostra il campo di input per la nuova specie.
  bool _creandoNuovaSpecie = false;
  
  /// Stati possibili per una pianta.
  /// 
  /// Utilizzati nel dropdown per la selezione dello stato.
  static const List<String> _statiPossibili = [
    'Sana',
    'Malata',
    'In crescita',
    'In fiore',
    'Dormiente',
    'Bisognosa di cure'
  ];

  /// Repository per le operazioni sulle piante.
  final PianteRepository _pianteRepository = PianteRepository();
  
  /// Repository per le operazioni sulle specie.
  final SpecieRepository _specieRepository = SpecieRepository.instance;
  
  /// Repository per le operazioni sulle categorie.
  final CategorieRepository _categorieRepository = CategorieRepository.instance;

  /// Inizializza il widget caricando i dati necessari.
  /// 
  /// Questo metodo viene chiamato una sola volta quando il widget
  /// viene creato. Carica le categorie dal database e inizializza
  /// i dati di default.
  /// 
  /// AZIONI:
  /// - Carica tutte le categorie dal database
  /// - Imposta lo stato di default
  /// - Gestisce eventuali errori di caricamento
  @override
  void initState() {
    super.initState();
    _caricaCategorie();
  }

  /// Carica le categorie dal database.
  /// 
  /// Questo metodo recupera tutte le categorie disponibili
  /// e le memorizza nello stato del widget.
  Future<void> _caricaCategorie() async {
    try {
      final categorie = await _categorieRepository.getTutteLeCategorie();
      if (mounted) {
        setState(() {
          _categorie = categorie;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento delle categorie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Carica le specie per una categoria specifica.
  /// 
  /// Questo metodo viene chiamato quando l'utente seleziona
  /// una categoria e aggiorna la lista delle specie disponibili.
  /// 
  Future<void> _caricaSpecie(Categoria categoria) async {
    try {
      final specie = await _specieRepository.getSpecieByCategoria(categoria.id!);
      if (mounted) {
        setState(() {
          _specie = specie;
          _specieSelezionata = null; // Reset della selezione
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento delle specie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Crea una nuova categoria nel database.
  /// 
  /// Questo metodo aggiunge una nuova categoria al database
  /// e la seleziona automaticamente.
  /// 
  Future<void> _creaNuovaCategoria() async {
    final nomeCategoria = _nuovaCategoriaController.text.trim();
    if (nomeCategoria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un nome per la categoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final nuovaCategoria = Categoria(nome: nomeCategoria);
      await _categorieRepository.aggiungiCategoria(nuovaCategoria);
      
      // Ricarica le categorie per ottenere l'ID assegnato
      await _caricaCategorie();
      
      // Trova la categoria appena creata e la seleziona
      final categoriaCreata = _categorie.firstWhere(
        (c) => c.nome == nomeCategoria,
        orElse: () => _categorie.last,
      );
      
      if (mounted) {
        setState(() {
          _categoriaSelezionata = categoriaCreata;
          _creandoNuovaCategoria = false;
        });
        _nuovaCategoriaController.clear();
        
        // Carica le specie per la nuova categoria
        await _caricaSpecie(categoriaCreata);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoria "$nomeCategoria" creata con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella creazione della categoria: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Crea una nuova specie nel database.
  /// 
  /// Questo metodo aggiunge una nuova specie al database
  /// per la categoria selezionata e la seleziona automaticamente.
  /// 
  Future<void> _creaNuovaSpecie() async {
    final nomeSpecie = _nuovaSpecieController.text.trim();
    if (nomeSpecie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un nome per la specie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_categoriaSelezionata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona prima una categoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final nuovaSpecie = Specie(
        nome: nomeSpecie,
        idCategoria: _categoriaSelezionata!.id!,
      );
      await _specieRepository.aggiungiSpecie(nuovaSpecie);
      
      // Ricarica le specie per ottenere l'ID assegnato
      await _caricaSpecie(_categoriaSelezionata!);
      
      // Trova la specie appena creata e la seleziona
      final specieCreata = _specie.firstWhere(
        (s) => s.nome == nomeSpecie,
        orElse: () => _specie.last,
      );
      
      if (mounted) {
        setState(() {
          _specieSelezionata = specieCreata;
          _creandoNuovaSpecie = false;
        });
        _nuovaSpecieController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Specie "$nomeSpecie" creata con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella creazione della specie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Converte un file immagine in Uint8List per il database.
  /// 
  /// Questo metodo legge il file immagine e lo converte
  /// nel formato BLOB richiesto dal database SQLite.
  /// 
  Future<Uint8List?> _convertiImmagineInBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella conversione dell\'immagine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Pulisce le risorse quando il widget viene distrutto.
  /// 
  /// Questo metodo viene chiamato automaticamente quando il widget
  /// viene rimosso dall'albero dei widget. È importante per evitare
  /// memory leak liberando i controller dei text field.
  @override
  void dispose() {
    _nomeController.dispose();
    _frequenzaInnaffiaturaController.dispose();
    _frequenzaPotaturaController.dispose();
    _frequenzaRinvasoController.dispose();
    _noteController.dispose();
    _nuovaCategoriaController.dispose();
    _nuovaSpecieController.dispose();
    super.dispose();
  }

  /// Salva la nuova pianta nel database.
  /// 
  Future<void> _salvaPianta() async {
    if (_formKey.currentState!.validate() && 
        _dataAcquisto != null && 
        _specieSelezionata != null) {
      try {
        // Nasconde la tastiera per migliorare l'esperienza utente
        FocusScope.of(context).unfocus();
        
        // Converte l'immagine se presente
        Uint8List? fotoBytes;
        if (_foto != null) {
          fotoBytes = await _convertiImmagineInBytes(_foto!);
          if (fotoBytes == null) return; // Errore nella conversione
        }
        
        // Ottiene i valori delle frequenze (opzionali)
        int? frequenzaInnaffiatura;
        int? frequenzaPotatura;
        int? frequenzaRinvaso;
        
        if (_frequenzaInnaffiaturaController.text.trim().isNotEmpty) {
          frequenzaInnaffiatura = int.parse(_frequenzaInnaffiaturaController.text.trim());
        }
        if (_frequenzaPotaturaController.text.trim().isNotEmpty) {
          frequenzaPotatura = int.parse(_frequenzaPotaturaController.text.trim());
        }
        if (_frequenzaRinvasoController.text.trim().isNotEmpty) {
          frequenzaRinvaso = int.parse(_frequenzaRinvasoController.text.trim());
        }
        
        // Crea un nuovo oggetto pianta con i dati del form
        final pianta = Pianta(
          nome: _nomeController.text.trim(),
          dataAcquisto: _dataAcquisto!,
          foto: fotoBytes,
          frequenzaInnaffiatura: frequenzaInnaffiatura ?? 7, // Default a 7 giorni
          frequenzaPotatura: frequenzaPotatura ?? 30, // Default a 30 giorni
          frequenzaRinvaso: frequenzaRinvaso ?? 365, // Default a 365 giorni
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          stato: _statoSelezionato,
          idSpecie: _specieSelezionata!.id!,
        );
        
        // Salva la pianta nel database
        await _pianteRepository.aggiungiPianta(pianta);
        
        // Verifica che il widget sia ancora montato prima di aggiornare l'UI
        // Questo previene errori se il widget viene distrutto durante l'operazione
        if (mounted) {
          // Chiude il popup e restituisce true per indicare successo
          // Il valore true viene utilizzato dal chiamante per aggiornare le schermate
          Navigator.of(context).pop(true);
          
          // Mostra messaggio di successo con SnackBar
          // Il colore verde indica successo, il testo conferma l'azione
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pianta "${pianta.nome}" aggiunta con successo!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // In caso di errore, mostra un messaggio di errore
        // Il colore rosso indica errore, il testo spiega il problema
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante il salvataggio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Mostra messaggio se mancano campi obbligatori
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compila tutti i campi obbligatori'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Costruisce l'interfaccia utente del popup.
  /// 
  @override
  Widget build(BuildContext context) {
    return Padding(
      // Adatta il padding in base alla tastiera
      // viewInsets contiene l'altezza della tastiera
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con titolo e pulsante di chiusura
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Aggiungi una nuova pianta', 
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ), 
                        textAlign: TextAlign.center
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: const CircleBorder(),
                      ),
                      tooltip: 'Chiudi',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campo nome pianta
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome pianta *',
                    hintText: 'Es: Rosa del balcone',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Inserisci un nome' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                
                // Dropdown categoria con opzione per creare nuova
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Categoria>(
                        value: _categoriaSelezionata,
                        decoration: const InputDecoration(
                          labelText: 'Categoria *',
                          hintText: 'Seleziona una categoria',
                        ),
                        items: _categorie.map((categoria) {
                          return DropdownMenuItem(
                            value: categoria,
                            child: Text(categoria.nome),
                          );
                        }).toList(),
                        onChanged: (Categoria? categoria) {
                          setState(() {
                            _categoriaSelezionata = categoria;
                            _specieSelezionata = null;
                          });
                          if (categoria != null) {
                            _caricaSpecie(categoria);
                          }
                        },
                        validator: (value) => value == null ? 'Seleziona una categoria' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _creandoNuovaCategoria = !_creandoNuovaCategoria;
                          if (!_creandoNuovaCategoria) {
                            _nuovaCategoriaController.clear();
                          }
                        });
                      },
                      icon: Icon(_creandoNuovaCategoria ? Icons.close : Icons.add),
                      tooltip: _creandoNuovaCategoria ? 'Annulla' : 'Aggiungi categoria',
                      style: IconButton.styleFrom(
                        backgroundColor: _creandoNuovaCategoria ? Colors.red.shade100 : Colors.green.shade100,
                        foregroundColor: _creandoNuovaCategoria ? Colors.red.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                
                // Campo per nuova categoria
                if (_creandoNuovaCategoria) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nuovaCategoriaController,
                          decoration: const InputDecoration(
                            labelText: 'Nome nuova categoria',
                            hintText: 'Es: Piante grasse',
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _creaNuovaCategoria,
                        child: const Text('Crea'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                
                // Dropdown specie con opzione per creare nuova
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Specie>(
                        value: _specieSelezionata,
                        decoration: const InputDecoration(
                          labelText: 'Specie *',
                          hintText: 'Seleziona una specie',
                        ),
                        items: _specie.map((specie) {
                          return DropdownMenuItem(
                            value: specie,
                            child: Text(specie.nome),
                          );
                        }).toList(),
                        onChanged: (Specie? specie) {
                          setState(() {
                            _specieSelezionata = specie;
                          });
                        },
                        validator: (value) => value == null ? 'Seleziona una specie' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _categoriaSelezionata == null ? null : () {
                        setState(() {
                          _creandoNuovaSpecie = !_creandoNuovaSpecie;
                          if (!_creandoNuovaSpecie) {
                            _nuovaSpecieController.clear();
                          }
                        });
                      },
                      icon: Icon(_creandoNuovaSpecie ? Icons.close : Icons.add),
                      tooltip: _creandoNuovaSpecie ? 'Annulla' : 'Aggiungi specie',
                      style: IconButton.styleFrom(
                        backgroundColor: _creandoNuovaSpecie ? Colors.red.shade100 : Colors.green.shade100,
                        foregroundColor: _creandoNuovaSpecie ? Colors.red.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                
                // Campo per nuova specie
                if (_creandoNuovaSpecie) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nuovaSpecieController,
                          decoration: const InputDecoration(
                            labelText: 'Nome nuova specie',
                            hintText: 'Es: Echeveria elegans',
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _creaNuovaSpecie,
                        child: const Text('Crea'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                
                // Dropdown stato
                DropdownButtonFormField<String>(
                  value: _statoSelezionato,
                  decoration: const InputDecoration(
                    labelText: 'Stato della pianta *',
                    hintText: 'Seleziona lo stato',
                  ),
                  items: _statiPossibili.map((stato) {
                    return DropdownMenuItem(
                      value: stato,
                      child: Text(stato),
                    );
                  }).toList(),
                  onChanged: (String? stato) {
                    setState(() {
                      _statoSelezionato = stato!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Campo frequenza innaffiatura (opzionale)
                TextFormField(
                  controller: _frequenzaInnaffiaturaController,
                  decoration: const InputDecoration(
                    labelText: 'Frequenza innaffiatura (giorni)',
                    hintText: 'Es: 3 (opzionale)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final numero = int.tryParse(v.trim());
                      if (numero == null || numero <= 0) {
                        return 'Inserisci un numero valido maggiore di 0';
                      }
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                
                // Campo frequenza potatura (opzionale)
                TextFormField(
                  controller: _frequenzaPotaturaController,
                  decoration: const InputDecoration(
                    labelText: 'Frequenza potatura (giorni)',
                    hintText: 'Es: 30 (opzionale)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final numero = int.tryParse(v.trim());
                      if (numero == null || numero <= 0) {
                        return 'Inserisci un numero valido maggiore di 0';
                      }
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                
                // Campo frequenza rinvaso (opzionale)
                TextFormField(
                  controller: _frequenzaRinvasoController,
                  decoration: const InputDecoration(
                    labelText: 'Frequenza rinvaso (giorni)',
                    hintText: 'Es: 365 (opzionale)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final numero = int.tryParse(v.trim());
                      if (numero == null || numero <= 0) {
                        return 'Inserisci un numero valido maggiore di 0';
                      }
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                
                // Campo note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (opzionale)',
                    hintText: 'Note aggiuntive sulla pianta',
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                
                // Campo data acquisto
                Row(
                  children: [
                    Expanded(
                      child: Text(_dataAcquisto == null
                          ? 'Data acquisto non selezionata *'
                          : 'Data acquisto: ${_dataAcquisto!.day}/${_dataAcquisto!.month}/${_dataAcquisto!.year}'),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Scegli data'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dataAcquisto = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Campo foto con anteprima
                Text('Foto della pianta (opzionale)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: _foto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_foto!, fit: BoxFit.cover, width: 64, height: 64),
                          )
                        : const Icon(Icons.image, size: 36, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Scegli foto'),
                        onPressed: () async {
                          final picked = await _picker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() => _foto = File(picked.path));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Pulsanti di azione
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _salvaPianta,
                        child: const Text('Salva'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
