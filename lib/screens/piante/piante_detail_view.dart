import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/AttivitaCuraModel.dart';
import '../../models/repository/SpecieRepository.dart';
import '../../services/db/DatabaseHelper.dart';
import '../../components/PiantaForm.dart';
import '../../providers/piante_provider.dart';

/// Schermata che mostra i dettagli di una pianta specifica.
/// è un ConsumerStatefulWidget per interagire con i provider.
class PianteDetailView extends ConsumerStatefulWidget { 
  final Pianta pianta;
  const PianteDetailView({super.key, required this.pianta});

  @override
  ConsumerState<PianteDetailView> createState() => _PianteDetailViewState();
}

class _PianteDetailViewState extends ConsumerState<PianteDetailView> {
  late Pianta _pianta;
  List<AttivitaCura> _attivita = [];
  Specie? _specie;

  final SpecieRepository _specieRepository = SpecieRepository.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pianta = widget.pianta;
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    setState(() => _isLoading = true);
    try {
      _specie = await _specieRepository.getSpecie(_pianta.idSpecie);
      _attivita = await _dbHelper.getAttivitaCuraByPianta(_pianta.id!);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Errore nel caricamento dei dati: $e');
    }
  }

  String _formattaData(DateTime data) {
    return '${data.day}/${data.month}/${data.year}';
  }

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

  Future<void> _modificaPianta() async {
    final piantaAggiornata = await showModalBottomSheet<Pianta>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Modifica Pianta'),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                body: PiantaForm(
                  piantaIniziale: _pianta,
                  onSave: (piantaDaAggiornare) async {
                    // MODIFICATO: Ora chiama il notifier per aggiornare lo stato globale
                    await ref.read(pianteProvider.notifier).aggiornaPianta(piantaDaAggiornare);
                    if (mounted) {
                      Navigator.of(context).pop(piantaDaAggiornare);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );

    if (piantaAggiornata != null) {
      setState(() {
        _pianta = piantaAggiornata;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pianta aggiornata con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _eliminaAttivita(AttivitaCura attivita) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.delete, color: Colors.red, size: 28), SizedBox(width: 12), Text('Elimina attività')]),
        content: const Text('Sei sicuro di voler eliminare questa attività di cura?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _dbHelper.deleteAttivitaCura(attivita.id!);
        setState(() => _attivita.removeWhere((a) => a.id == attivita.id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attività eliminata con successo'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nell\'eliminazione: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _modificaAttivita(AttivitaCura attivita) async {
    String tipoAttivita = attivita.tipoAttivita;
    DateTime data = attivita.data;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(children: [Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 28), const SizedBox(width: 12), const Text('Modifica attività')]),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipoAttivita,
                      decoration: InputDecoration(labelText: 'Tipo attività', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                      items: ['innaffiatura', 'potatura', 'rinvaso'].map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize()))).toList(),
                      onChanged: (v) => tipoAttivita = v ?? 'innaffiatura',
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: data, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (date != null) {
                          setStateDialog(() {
                            data = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'Data', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                        child: Text(_formattaData(data)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Salva'),
                  ),
                ],
              );
            }
        );
      },
    );

    if (result == true) {
      try {
        final attivitaAggiornata = AttivitaCura(id: attivita.id, idPianta: attivita.idPianta, tipoAttivita: tipoAttivita, data: data);
        await _dbHelper.updateAttivitaCura(attivitaAggiornata);
        setState(() {
          final index = _attivita.indexOf(attivita);
          if (index != -1) _attivita[index] = attivitaAggiornata;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attività aggiornata con successo'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nell\'aggiornamento: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _aggiungiAttivita() async {
    String tipoAttivita = 'innaffiatura';
    DateTime data = DateTime.now().add(const Duration(days: 1));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(children: [Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 28), const SizedBox(width: 12), const Text('Aggiungi attività')]),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipoAttivita,
                      decoration: InputDecoration(labelText: 'Tipo attività', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                      items: ['innaffiatura', 'potatura', 'rinvaso'].map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize()))).toList(),
                      onChanged: (v) => tipoAttivita = v ?? 'innaffiatura',
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: data, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (date != null) {
                          setStateDialog(() {
                            data = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'Data', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                        child: Text(_formattaData(data)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Aggiungi'),
                  ),
                ],
              );
            }
        );
      },
    );

    if (result == true) {
      try {
        final nuovaAttivita = AttivitaCura(idPianta: _pianta.id!, tipoAttivita: tipoAttivita, data: data);
        final id = await _dbHelper.addAttivitaCura(nuovaAttivita);
        setState(() => _attivita.add(AttivitaCura(id: id, idPianta: _pianta.id!, tipoAttivita: tipoAttivita, data: data)));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attività aggiunta con successo'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nell\'aggiunta: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caricamento...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(_pianta.nome),
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _modificaPianta, tooltip: 'Modifica pianta'),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            _pianta.foto != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.memory(_pianta.foto!, width: 60, height: 60, fit: BoxFit.cover),
                            )
                                : Image.asset('assets/icon.png', width: 60, height: 60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_florist, size: 60)),
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
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Attività di Cura', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary, size: 28),
                                  onPressed: _aggiungiAttivita,
                                  tooltip: 'Aggiungi attività',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _attivita.isEmpty
                                ? Center(
                              child: Column(
                                children: [
                                  Icon(Icons.task_outlined, size: 60, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('Nessuna attività registrata', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  Text('Aggiungi la tua prima attività di cura!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                                ],
                              ),
                            )
                                : ListView.builder(
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
                                    border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3, offset: const Offset(0, 1))],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: _getActivityColor(tipo).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(_getActivityIcon(tipo), color: _getActivityColor(tipo), size: 20),
                                    ),
                                    title: Text(tipo.capitalize(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 1),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _modificaAttivita(a), tooltip: 'Modifica'),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminaAttivita(a), tooltip: 'Elimina'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
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
                            (_pianta.note != null && _pianta.note!.isNotEmpty)
                                ? Text(
                              _pianta.note!,
                              style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                            )
                                : Text(
                              'Nessuna nota personale.',
                              style: TextStyle(fontSize: 16, color: Colors.grey[500], fontStyle: FontStyle.italic),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}