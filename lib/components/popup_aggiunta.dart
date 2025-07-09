/*
 * POPUP AGGIUNTA PIANTA - COMPONENTE PER AGGIUNGERE NUOVE PIANTE
 * * Questo file contiene il popup per l'aggiunta di nuove piante
 * alla collezione. Si apre dal basso dello schermo e fornisce un form
 * completo per inserire tutti i dati necessari di una pianta.
 * */

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
// Import per formattare la data (ora funzionerà dopo aver aggiunto la dipendenza)
import 'package:intl/intl.dart';

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
  final _formKey = GlobalKey<FormState>();

  // Controller dei campi
  final _nomeController = TextEditingController();
  final _frequenzaInnaffiaturaController = TextEditingController();
  final _frequenzaPotaturaController = TextEditingController();
  final _frequenzaRinvasoController = TextEditingController();
  final _noteController = TextEditingController();
  final _nuovaCategoriaController = TextEditingController();
  final _nuovaSpecieController = TextEditingController();
  final _dataAcquistoController = TextEditingController();

  /// Data di acquisto della pianta selezionata dall'utente.
  DateTime? _dataAcquisto;

  /// File della foto selezionata dall'utente.
  File? _foto;

  /// Picker per selezionare le immagini dalla galleria.
  final ImagePicker _picker = ImagePicker();

  // Liste e selezioni per i dropdown
  List<Categoria> _categorie = [];
  List<Specie> _specie = [];
  Categoria? _categoriaSelezionata;
  Specie? _specieSelezionata;
  String _statoSelezionato = 'Sana';

  // Stati per la UI
  bool _creandoNuovaCategoria = false;
  bool _creandoNuovaSpecie = false;

  /// Stati possibili per una pianta.
  static const List<String> _statiPossibili = [
    'Sana',
    'Malata',
    'In crescita',
    'In fiore',
    'Dormiente',
    'Bisognosa di cure'
  ];

  // Repository
  final PianteRepository _pianteRepository = PianteRepository();
  final SpecieRepository _specieRepository = SpecieRepository.instance;
  final CategorieRepository _categorieRepository = CategorieRepository.instance;

  @override
  void initState() {
    super.initState();
    _caricaCategorie();
  }

  // ===================================================================
  // == METODI ORIGINALI REINSERITI (SENZA MODIFICHE ALLA LOGICA) ==
  // ===================================================================

  /// Carica le categorie dal database.
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
      await _caricaCategorie();
      final categoriaCreata = _categorie.firstWhere((c) => c.nome == nomeCategoria);

      if (mounted) {
        setState(() {
          _categoriaSelezionata = categoriaCreata;
          _creandoNuovaCategoria = false;
        });
        _nuovaCategoriaController.clear();
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
  Future<void> _creaNuovaSpecie() async {
    final nomeSpecie = _nuovaSpecieController.text.trim();
    if (nomeSpecie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome per la specie')),
      );
      return;
    }
    if (_categoriaSelezionata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona prima una categoria')),
      );
      return;
    }
    try {
      final nuovaSpecie = Specie(nome: nomeSpecie, idCategoria: _categoriaSelezionata!.id!);
      await _specieRepository.aggiungiSpecie(nuovaSpecie);
      await _caricaSpecie(_categoriaSelezionata!);
      final specieCreata = _specie.firstWhere((s) => s.nome == nomeSpecie);

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

  /// Salva la nuova pianta nel database.
  Future<void> _salvaPianta() async {
    if (_formKey.currentState!.validate() &&
        _dataAcquisto != null &&
        _specieSelezionata != null) {
      try {
        FocusScope.of(context).unfocus();

        Uint8List? fotoBytes;
        if (_foto != null) {
          fotoBytes = await _convertiImmagineInBytes(_foto!);
          if (fotoBytes == null) return;
        }

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

        final pianta = Pianta(
          nome: _nomeController.text.trim(),
          dataAcquisto: _dataAcquisto!,
          foto: fotoBytes,
          frequenzaInnaffiatura: frequenzaInnaffiatura ?? 7,
          frequenzaPotatura: frequenzaPotatura ?? 30,
          frequenzaRinvaso: frequenzaRinvaso ?? 365,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          stato: _statoSelezionato,
          idSpecie: _specieSelezionata!.id!,
        );

        await _pianteRepository.aggiungiPianta(pianta);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pianta "${pianta.nome}" aggiunta con successo!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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

  // ===================================================================
  // ===================================================================

  @override
  void dispose() {
    _nomeController.dispose();
    _frequenzaInnaffiaturaController.dispose();
    _frequenzaPotaturaController.dispose();
    _frequenzaRinvasoController.dispose();
    _noteController.dispose();
    _nuovaCategoriaController.dispose();
    _nuovaSpecieController.dispose();
    _dataAcquistoController.dispose();
    super.dispose();
  }

  /// Costruisce l'interfaccia utente del popup.
  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
    );

    return Padding(
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
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        shape: const CircleBorder(),
                      ),
                      tooltip: 'Chiudi',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome pianta *',
                    hintText: 'Es: Rosa del balcone',
                    prefixIcon: const Icon(Icons.grass),
                    border: inputBorder,
                    focusedBorder: focusedInputBorder,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Inserisci un nome' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<Categoria>(
                  value: _categoriaSelezionata,
                  decoration: InputDecoration(
                    labelText: 'Categoria *',
                    hintText: 'Seleziona una categoria',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: inputBorder,
                    focusedBorder: focusedInputBorder,
                  ),
                  items: _categorie.map((c) => DropdownMenuItem(value: c, child: Text(c.nome))).toList(),
                  onChanged: (categoria) {
                    if (categoria != null) {
                      setState(() {
                        _categoriaSelezionata = categoria;
                        _specieSelezionata = null; // Resetta la specie quando cambia la categoria
                      });
                      _caricaSpecie(categoria);
                    }
                  },
                  validator: (v) => v == null ? 'Seleziona una categoria' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<Specie>(
                  value: _specieSelezionata,
                  decoration: InputDecoration(
                    labelText: 'Specie *',
                    hintText: _categoriaSelezionata == null ? 'Prima scegli una categoria' : 'Seleziona una specie',
                    prefixIcon: const Icon(Icons.spa_outlined),
                    border: inputBorder,
                    focusedBorder: focusedInputBorder,
                  ),
                  items: _specie.map((s) => DropdownMenuItem(value: s, child: Text(s.nome))).toList(),
                  onChanged: (specie) => setState(() => _specieSelezionata = specie),
                  validator: (v) => v == null ? 'Seleziona una specie' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _statoSelezionato,
                  decoration: InputDecoration(
                    labelText: 'Stato della pianta *',
                    prefixIcon: const Icon(Icons.favorite_border_outlined),
                    border: inputBorder,
                    focusedBorder: focusedInputBorder,
                  ),
                  items: _statiPossibili.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (stato) => setState(() => _statoSelezionato = stato!),
                ),
                const SizedBox(height: 24),

                Text(
                  'Frequenze di cura (giorni)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FrequencyInput(
                        controller: _frequenzaInnaffiaturaController,
                        icon: Icons.water_drop_outlined,
                        hintText: 'Innaffiatura',
                        inputBorder: inputBorder,
                        focusedInputBorder: focusedInputBorder,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FrequencyInput(
                        controller: _frequenzaPotaturaController,
                        icon: Icons.content_cut_outlined,
                        hintText: 'Potatura',
                        inputBorder: inputBorder,
                        focusedInputBorder: focusedInputBorder,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FrequencyInput(
                        controller: _frequenzaRinvasoController,
                        icon: Icons.yard_outlined,
                        hintText: 'Rinvaso',
                        inputBorder: inputBorder,
                        focusedInputBorder: focusedInputBorder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _dataAcquistoController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Data acquisto *',
                    hintText: 'Seleziona una data',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: inputBorder,
                    focusedBorder: focusedInputBorder,
                  ),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dataAcquisto ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _dataAcquisto = picked;
                        _dataAcquistoController.text = DateFormat('dd/MM/yyyy').format(picked);
                      });
                    }
                  },
                  validator: (v) => _dataAcquisto == null ? 'Seleziona una data' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (opzionale)',
                    hintText: 'Note aggiuntive sulla pianta...',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: inputBorder,
                    focusedBorder: focusedInputBorder,
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: _foto != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_foto!, fit: BoxFit.cover),
                      )
                          : const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Scegli foto'),
                        onPressed: () async {
                          final picked = await _picker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() => _foto = File(picked.path));
                          }
                        },
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            )
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annulla'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            )
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _salvaPianta,
                        child: const Text('Salva Pianta'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
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

/// Widget helper per i campi di input della frequenza
class _FrequencyInput extends StatelessWidget {
  const _FrequencyInput({
    required this.controller,
    required this.icon,
    required this.hintText,
    required this.inputBorder,
    required this.focusedInputBorder,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final InputBorder inputBorder;
  final InputBorder focusedInputBorder;

  @override
  Widget build(BuildContext context) {
    // Definiamo i bordi specifici per lo stato di errore.
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
    );

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        border: inputBorder,
        focusedBorder: focusedInputBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        errorStyle: const TextStyle(height: 0, fontSize: 0),
      ),
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          final numero = int.tryParse(v.trim());
          if (numero == null || numero <= 0) {
            // Restituiamo una stringa non vuota (ma invisibile)
            // per attivare lo stato di errore del campo, che mostrerà il bordo rosso.
            return ' ';
          }
        }
        return null; // Nessun errore, il campo è valido.
      },
      textInputAction: TextInputAction.next,
    );
  }

}