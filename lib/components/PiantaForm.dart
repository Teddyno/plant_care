import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';

// Assicurati che i percorsi di importazione per i tuoi modelli e repository siano corretti
import '../models/PiantaModel.dart';
import '../models/SpecieModel.dart';
import '../models/CategoriaModel.dart';
import '../models/repository/SpecieRepository.dart';
import '../models/repository/CategorieRepository.dart';

class PiantaForm extends StatefulWidget {
  final Pianta? piantaIniziale;
  final Function(Pianta pianta) onSave;

  const PiantaForm({
    super.key,
    this.piantaIniziale,
    required this.onSave,
  });

  @override
  State<PiantaForm> createState() => _PiantaFormState();
}

class _PiantaFormState extends State<PiantaForm> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _frequenzaInnaffiaturaController = TextEditingController();
  final _frequenzaPotaturaController = TextEditingController();
  final _frequenzaRinvasoController = TextEditingController();
  final _noteController = TextEditingController();
  final _dataAcquistoController = TextEditingController();

  DateTime? _dataAcquisto;
  File? _foto;
  Uint8List? _fotoEsistente;
  final ImagePicker _picker = ImagePicker();
  List<Categoria> _categorie = [];
  List<Specie> _specie = [];
  Categoria? _categoriaSelezionata;
  Specie? _specieSelezionata;
  String _statoSelezionato = 'Sana';

  // CORREZIONE: Rimosso _pianteRepository perché non usato qui.
  final SpecieRepository _specieRepository = SpecieRepository.instance;
  final CategorieRepository _categorieRepository = CategorieRepository.instance;

  static const List<String> _statiPossibili = [
    'Sana', 'Malata', 'In crescita', 'In fiore', 'Dormiente', 'Bisognosa di cure'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.piantaIniziale != null) {
      _caricaDatiIniziali(widget.piantaIniziale!);
    } else {
      _caricaCategorie();
    }
  }

  @override
  void dispose() {
    // ... (dispose di tutti i controller come prima)
    _nomeController.dispose();
    _frequenzaInnaffiaturaController.dispose();
    _frequenzaPotaturaController.dispose();
    _frequenzaRinvasoController.dispose();
    _noteController.dispose();
    _dataAcquistoController.dispose();
    super.dispose();
  }

  /// CORREZIONE: Logica aggiornata per caricare i dati basandosi sul modello corretto.
  Future<void> _caricaDatiIniziali(Pianta pianta) async {
    // Popola i campi di testo e le variabili di stato
    _nomeController.text = pianta.nome;
    _frequenzaInnaffiaturaController.text = pianta.frequenzaInnaffiatura.toString();
    _frequenzaPotaturaController.text = pianta.frequenzaPotatura.toString();
    _frequenzaRinvasoController.text = pianta.frequenzaRinvaso.toString();
    _noteController.text = pianta.note ?? '';
    _dataAcquisto = pianta.dataAcquisto;
    _dataAcquistoController.text = DateFormat('dd/MM/yyyy').format(pianta.dataAcquisto);
    _statoSelezionato = pianta.stato;
    _fotoEsistente = pianta.foto;

    // Carica tutti i dati necessari per i dropdown
    await _caricaTuttiIDatiDropDown();

    // Trova la specie corrente della pianta
    _specieSelezionata = _specie.firstWhere((s) => s.id == pianta.idSpecie, orElse: () => _specie.first);

    // Da quella specie, trova l'id della categoria e imposta la categoria selezionata
    final idCategoriaCorrente = _specieSelezionata!.idCategoria;
    _categoriaSelezionata = _categorie.firstWhere((c) => c.id == idCategoriaCorrente, orElse: () => _categorie.first);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _caricaTuttiIDatiDropDown() async {
    // Carica in parallelo per efficienza
    final results = await Future.wait([
      _categorieRepository.getTutteLeCategorie(),
      _specieRepository.getTutteLeSpecie(), // Assumendo che tu abbia un metodo per prenderle tutte
    ]);
    if (mounted) {
      setState(() {
        _categorie = results[0] as List<Categoria>;
        _specie = results[1] as List<Specie>;
      });
    }
  }

  Future<void> _caricaCategorie() async {
    // ... (metodo invariato)
    _categorie = await _categorieRepository.getTutteLeCategorie();
    if(mounted) setState(() {});
  }

  Future<void> _caricaSpecie(Categoria categoria) async {
    // ... (metodo invariato)
    _specie = await _specieRepository.getSpecieByCategoria(categoria.id!);
    if(mounted) setState(() {});
  }

  Future<Uint8List?> _convertiImmagineInBytes(File file) async {
    // ... (metodo invariato)
    return await file.readAsBytes();
  }

  /// CORREZIONE: Rimosso idCategoria dalla creazione dell'oggetto Pianta.
  Future<void> _salva() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      Uint8List? fotoBytes;
      if (_foto != null) {
        fotoBytes = await _convertiImmagineInBytes(_foto!);
      } else {
        fotoBytes = _fotoEsistente;
      }

      final piantaDaSalvare = Pianta(
        id: widget.piantaIniziale?.id,
        nome: _nomeController.text.trim(),
        dataAcquisto: _dataAcquisto!,
        foto: fotoBytes,
        frequenzaInnaffiatura: int.tryParse(_frequenzaInnaffiaturaController.text.trim()) ?? 7,
        frequenzaPotatura: int.tryParse(_frequenzaPotaturaController.text.trim()) ?? 30,
        frequenzaRinvaso: int.tryParse(_frequenzaRinvasoController.text.trim()) ?? 365,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        stato: _statoSelezionato,
        idSpecie: _specieSelezionata!.id!,
        // Rimosso: idCategoria: _categoriaSelezionata!.id!,
      );

      widget.onSave(piantaDaSalvare);

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

  @override
  Widget build(BuildContext context) {
    // ... (Il build method rimane invariato, qui per completezza)
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.piantaIniziale == null ? 'Nuova Pianta' : 'Modifica Pianta',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: 'Nome pianta *', prefixIcon: const Icon(Icons.grass), border: inputBorder),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci un nome' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Categoria>(
              value: _categoriaSelezionata,
              decoration: InputDecoration(labelText: 'Categoria *', prefixIcon: const Icon(Icons.category_outlined), border: inputBorder),
              items: _categorie.map((c) => DropdownMenuItem(value: c, child: Text(c.nome))).toList(),
              onChanged: (categoria) {
                if (categoria != null) {
                  setState(() {
                    _categoriaSelezionata = categoria;
                    _specieSelezionata = null;
                  });
                  _caricaSpecie(categoria);
                }
              },
              validator: (v) => v == null ? 'Seleziona una categoria' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Specie>(
              value: _specieSelezionata,
              decoration: InputDecoration(labelText: 'Specie *', prefixIcon: const Icon(Icons.spa_outlined), border: inputBorder),
              items: _specie.map((s) => DropdownMenuItem(value: s, child: Text(s.nome))).toList(),
              onChanged: (specie) => setState(() => _specieSelezionata = specie),
              validator: (v) => v == null ? 'Seleziona una specie' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataAcquistoController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Data acquisto *', prefixIcon: const Icon(Icons.calendar_today_outlined), border: inputBorder),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _dataAcquisto ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                if (picked != null && mounted) {
                  setState(() {
                    _dataAcquisto = picked;
                    _dataAcquistoController.text = DateFormat('dd/MM/yyyy').format(picked);
                  });
                }
              },
              validator: (v) => _dataAcquisto == null ? 'Seleziona una data' : null,
            ),
            const SizedBox(height: 24),
            Text('Frequenze di cura (giorni)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _FrequencyInput(controller: _frequenzaInnaffiaturaController, icon: Icons.water_drop_outlined, hintText: 'Acqua')),
                const SizedBox(width: 12),
                Expanded(child: _FrequencyInput(controller: _frequenzaPotaturaController, icon: Icons.content_cut_outlined, hintText: 'Potatura')),
                const SizedBox(width: 12),
                Expanded(child: _FrequencyInput(controller: _frequenzaRinvasoController, icon: Icons.yard_outlined, hintText: 'Rinvaso')),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(labelText: 'Note (opzionale)', prefixIcon: const Icon(Icons.notes_outlined), border: inputBorder),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
                  child: _buildImagePreview(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(_fotoEsistente != null ? 'Cambia foto' : 'Scegli foto'),
                    onPressed: () async {
                      final picked = await _picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => _foto = File(picked.path));
                      }
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salva Pianta'),
              onPressed: _salva,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_foto != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_foto!, fit: BoxFit.cover, width: 80, height: 80));
    }
    if (_fotoEsistente != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_fotoEsistente!, fit: BoxFit.cover, width: 80, height: 80));
    }
    return const Icon(Icons.image_outlined, size: 40, color: Colors.grey);
  }
}

class _FrequencyInput extends StatelessWidget {
  // ... (Widget _FrequencyInput invariato)
  const _FrequencyInput({
    required this.controller,
    required this.icon,
    required this.hintText,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
        ),
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
            return ' ';
          }
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }
}