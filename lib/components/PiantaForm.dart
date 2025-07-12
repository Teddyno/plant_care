import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import '../models/PiantaModel.dart';
import '../models/SpecieModel.dart';
import '../models/CategoriaModel.dart';
import '../providers/piante_provider.dart';
import '../providers/categorie_provider.dart';
import '../providers/specie_provider.dart';

/// Form per aggiungere o modificare una pianta, ora completamente integrato con Riverpod.
class PiantaForm extends ConsumerStatefulWidget {
  final Pianta? piantaIniziale;
  final Function(Pianta pianta) onSave;

  const PiantaForm({
    super.key,
    this.piantaIniziale,
    required this.onSave,
  });

  @override
  ConsumerState<PiantaForm> createState() => _PiantaFormState();
}

class _PiantaFormState extends ConsumerState<PiantaForm> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  final _nomeController = TextEditingController();
  final _frequenzaInnaffiaturaController = TextEditingController();
  final _frequenzaPotaturaController = TextEditingController();
  final _frequenzaRinvasoController = TextEditingController();
  final _noteController = TextEditingController();
  final _dataAcquistoController = TextEditingController();
  final _nuovaCategoriaController = TextEditingController();
  final _nuovaSpecieController = TextEditingController();

  // Variabili di stato
  DateTime? _dataAcquisto;
  File? _foto;
  Uint8List? _fotoEsistente;
  final ImagePicker _picker = ImagePicker();
  int? _categoriaSelezionataId;
  int? _specieSelezionataId;
  String _statoSelezionato = 'Sana';

  // Flag per la UI
  bool _creandoNuovaCategoria = false;
  bool _creandoNuovaSpecie = false;

  @override
  void initState() {
    super.initState();
    if (widget.piantaIniziale != null) {
      _caricaDatiIniziali(widget.piantaIniziale!);
    }
  }

  @override
  void dispose() {
    // Dispose di tutti i controller
    _nomeController.dispose();
    _frequenzaInnaffiaturaController.dispose();
    _frequenzaPotaturaController.dispose();
    _frequenzaRinvasoController.dispose();
    _noteController.dispose();
    _dataAcquistoController.dispose();
    _nuovaCategoriaController.dispose();
    _nuovaSpecieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    // Usa ref.watch per ottenere i dati in modo reattivo
    final categorieState = ref.watch(tutteLeCategorieProvider);
    final specieState = ref.watch(tutteLeSpecieProvider);

    return SafeArea(
      child: SingleChildScrollView(
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

              // Dropdown Categorie (ora basato su Riverpod)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: categorieState.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Errore caricamento categorie: $e'),
                      data: (categorie) => DropdownButtonFormField<int>(
                        value: _categoriaSelezionataId,
                        decoration: InputDecoration(labelText: 'Categoria *', prefixIcon: const Icon(Icons.category_outlined), border: inputBorder),
                        items: categorie.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _categoriaSelezionataId = value;
                            _specieSelezionataId = null;
                            if (_creandoNuovaSpecie) _creandoNuovaSpecie = false;
                          });
                        },
                        validator: (v) => v == null ? 'Seleziona una categoria' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_creandoNuovaCategoria ? Icons.close : Icons.add),
                    tooltip: _creandoNuovaCategoria ? 'Annulla' : 'Nuova categoria',
                    onPressed: () => setState(() => _creandoNuovaCategoria = !_creandoNuovaCategoria),
                  ),
                ],
              ),

              if (_creandoNuovaCategoria)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nuovaCategoriaController,
                          decoration: const InputDecoration(labelText: 'Nome nuova categoria', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _creaNuovaCategoria,
                        child: const Text('Crea'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Dropdown Specie (ora basato su Riverpod)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: specieState.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => Text('Errore caricamento specie: $e'),
                      data: (specie) {
                        final specieFiltrate = specie.where((s) => s.idCategoria == _categoriaSelezionataId).toList();
                        return DropdownButtonFormField<int>(
                          value: _specieSelezionataId,
                          decoration: InputDecoration(
                            labelText: 'Specie *',
                            hintText: _categoriaSelezionataId == null ? 'Scegli la categoria' : '',
                            prefixIcon: const Icon(Icons.spa_outlined),
                            border: inputBorder,
                          ),
                          items: specieFiltrate.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome))).toList(),
                          onChanged: (value) => setState(() => _specieSelezionataId = value),
                          validator: (v) => v == null ? 'Seleziona una specie' : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_creandoNuovaSpecie ? Icons.close : Icons.add),
                    tooltip: _creandoNuovaSpecie ? 'Annulla' : 'Nuova specie',
                    onPressed: _categoriaSelezionataId == null
                        ? null
                        : () => setState(() => _creandoNuovaSpecie = !_creandoNuovaSpecie),
                  ),
                ],
              ),

              if (_creandoNuovaSpecie)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nuovaSpecieController,
                          decoration: const InputDecoration(labelText: 'Nome nuova specie', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _creaNuovaSpecie,
                        child: const Text('Crea'),
                      ),
                    ],
                  ),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- METODI DI LOGICA (ora integrati con Riverpod) ---

  Widget _buildImagePreview() {
    if (_foto != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_foto!, fit: BoxFit.cover, width: 80, height: 80));
    }
    if (_fotoEsistente != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_fotoEsistente!, fit: BoxFit.cover, width: 80, height: 80));
    }
    return const Icon(Icons.image_outlined, size: 40, color: Colors.grey);
  }

  void _caricaDatiIniziali(Pianta pianta) {
    _nomeController.text = pianta.nome;
    _frequenzaInnaffiaturaController.text = pianta.frequenzaInnaffiatura.toString();
    _frequenzaPotaturaController.text = pianta.frequenzaPotatura.toString();
    _frequenzaRinvasoController.text = pianta.frequenzaRinvaso.toString();
    _noteController.text = pianta.note ?? '';
    _dataAcquisto = pianta.dataAcquisto;
    _dataAcquistoController.text = DateFormat('dd/MM/yyyy').format(pianta.dataAcquisto);
    _statoSelezionato = pianta.stato;
    _fotoEsistente = pianta.foto;
    _specieSelezionataId = pianta.idSpecie;

    final specieList = ref.read(tutteLeSpecieProvider).asData?.value;
    if (specieList != null) {
      try {
        final specieIniziale = specieList.firstWhere((s) => s.id == pianta.idSpecie);
        _categoriaSelezionataId = specieIniziale.idCategoria;
      } catch (e) {
        // La specie potrebbe non essere presente, gestisci il caso
      }
    }
  }

  Future<void> _creaNuovaCategoria() async {
    final nomeCategoria = _nuovaCategoriaController.text.trim();
    if (nomeCategoria.isEmpty) return;

    await ref.read(tutteLeCategorieProvider.notifier).aggiungiCategoria(nomeCategoria);

    setState(() {
      _creandoNuovaCategoria = false;
      _nuovaCategoriaController.clear();
    });
  }

  Future<void> _creaNuovaSpecie() async {
    if (_categoriaSelezionataId == null) return;
    final nomeSpecie = _nuovaSpecieController.text.trim();
    if (nomeSpecie.isEmpty) return;

    final nuovaSpecie = Specie(nome: nomeSpecie, idCategoria: _categoriaSelezionataId!);
    await ref.read(tutteLeSpecieProvider.notifier).aggiungiSpecie(nuovaSpecie);

    setState(() {
      _creandoNuovaSpecie = false;
      _nuovaSpecieController.clear();
    });
  }

  Future<Uint8List?> _convertiImmagineInBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

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
        idSpecie: _specieSelezionataId!,
      );

      await widget.onSave(piantaDaSalvare);

      ref.invalidate(tutteLeCategorieProvider);
      ref.invalidate(tutteLeSpecieProvider);
    }
  }
}

class _FrequencyInput extends StatelessWidget {
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
