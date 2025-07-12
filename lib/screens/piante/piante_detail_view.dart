import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/AttivitaCuraModel.dart';
import '../../components/PiantaForm.dart';
import '../../providers/piante_provider.dart';
import '../../providers/attivita_cura_provider.dart';
import '../../providers/specie_provider.dart';

/// Schermata che mostra i dettagli di una pianta specifica.
/// Ora è un ConsumerWidget per una gestione dello stato più pulita e reattiva.
class PianteDetailView extends ConsumerWidget {
  // [CORREZIONE] Ripristinato il parametro 'pianta' per compatibilità con le altre viste.
  final Pianta pianta;
  const PianteDetailView({super.key, required this.pianta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Ascolta" i provider per ottenere i dati aggiornati in modo reattivo.
    // Questo assicura che se i dati cambiano (es. una specie viene aggiornata),
    // la UI si ricostruisce.
    final tutteLeSpecie = ref.watch(tutteLeSpecieProvider);
    final attivitaDellaPianta = ref.watch(attivitaCuraProvider).tutteLeAttivita.where((a) => a.idPianta == pianta.id).toList();

    // Trova la specie corrispondente in modo sicuro.
    Specie? specie;
    final specieList = tutteLeSpecie.asData?.value;
    if (specieList != null) {
      try {
        specie = specieList.firstWhere((s) => s.id == pianta.idSpecie);
      } catch (e) {
        specie = null; // La specie non è stata trovata
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(pianta.nome),
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _modificaPianta(context, ref, pianta), tooltip: 'Modifica pianta'),
              IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: () => _eliminaPiantaDialog(context, ref, pianta.id!), tooltip: 'Elimina pianta'),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCardDettagliPianta(context, pianta, specie),
                const SizedBox(height: 24),
                _buildCardAttivita(context, ref, pianta, attivitaDellaPianta),
                const SizedBox(height: 24),
                _buildCardNote(context, pianta),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DI COSTRUZIONE UI ---

  Widget _buildCardDettagliPianta(BuildContext context, Pianta pianta, Specie? specie) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            pianta.foto != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.memory(pianta.foto!, width: 60, height: 60, fit: BoxFit.cover))
                : Image.asset('assets/icon.png', width: 60, height: 60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_florist, size: 60)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pianta.nome, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(specie?.nome ?? 'Specie sconosciuta', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  Text('Acquisita il: ${_formattaData(pianta.dataAcquisto)}', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  Text('Innaffiatura: ogni ${pianta.frequenzaInnaffiatura} giorni', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAttivita(BuildContext context, WidgetRef ref, Pianta pianta, List<AttivitaCura> attivita) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  onPressed: () => _aggiungiOModificaAttivitaDialog(context, ref, pianta: pianta),
                  tooltip: 'Aggiungi attività',
                ),
              ],
            ),
            const SizedBox(height: 20),
            attivita.isEmpty
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
              itemCount: attivita.length,
              itemBuilder: (context, index) {
                final a = attivita[index];
                return ListTile(
                  leading: Icon(_getActivityIcon(a.tipoAttivita), color: _getActivityColor(a.tipoAttivita)),
                  title: Text(a.tipoAttivita.capitalize(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_formattaData(a.data)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _aggiungiOModificaAttivitaDialog(context, ref, pianta: pianta, attivita: a), tooltip: 'Modifica'),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminaAttivitaDialog(context, ref, a), tooltip: 'Elimina'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardNote(BuildContext context, Pianta pianta) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
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
            (pianta.note != null && pianta.note!.isNotEmpty)
                ? Text(pianta.note!, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5))
                : Text('Nessuna nota personale.', style: TextStyle(fontSize: 16, color: Colors.grey[500], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // --- METODI DI LOGICA ---

  String _formattaData(DateTime data) => '${data.day}/${data.month}/${data.year}';

  IconData _getActivityIcon(String tipo) {
    switch (tipo) {
      case 'innaffiatura': return Icons.water_drop;
      case 'potatura': return Icons.content_cut;
      case 'rinvaso': return Icons.grass;
      default: return Icons.task;
    }
  }

  Color _getActivityColor(String tipo) {
    switch (tipo) {
      case 'innaffiatura': return Colors.blue;
      case 'potatura': return Colors.green;
      case 'rinvaso': return Colors.brown;
      default: return Colors.grey;
    }
  }

  void _eliminaPiantaDialog(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questa pianta? L\'azione è irreversibile.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annulla')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await ref.read(pianteProvider.notifier).eliminaPianta(id);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(); // Chiude il dialogo
              }
              if (context.mounted) {
                Navigator.of(context).pop(); // Torna indietro dalla pagina dei dettagli
              }
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Future<void> _modificaPianta(BuildContext context, WidgetRef ref, Pianta pianta) async {
    await showModalBottomSheet<Pianta>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PiantaForm(
        piantaIniziale: pianta,
        onSave: (piantaDaAggiornare) async {
          await ref.read(pianteProvider.notifier).aggiornaPianta(piantaDaAggiornare);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  void _eliminaAttivitaDialog(BuildContext context, WidgetRef ref, AttivitaCura attivita) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina attività'),
        content: const Text('Sei sicuro di voler eliminare questa attività di cura?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (result == true) {
      await ref.read(attivitaCuraProvider.notifier).eliminaAttivita(attivita.id!);
    }
  }

  void _aggiungiOModificaAttivitaDialog(BuildContext context, WidgetRef ref, {required Pianta pianta, AttivitaCura? attivita}) async {
    final isModifica = attivita != null;
    String tipoAttivita = attivita?.tipoAttivita ?? 'innaffiatura';
    DateTime data = attivita?.data ?? DateTime.now();

    final result = await showDialog<AttivitaCura?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isModifica ? 'Modifica attività' : 'Aggiungi attività'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipoAttivita,
                  items: ['innaffiatura', 'potatura', 'rinvaso'].map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize()))).toList(),
                  onChanged: (v) => setStateDialog(() => tipoAttivita = v ?? 'innaffiatura'),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: data, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (date != null) setStateDialog(() => data = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Data'),
                    child: Text(_formattaData(data)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () {
                  final nuovaAttivita = AttivitaCura(
                    id: attivita?.id,
                    idPianta: pianta.id!,
                    tipoAttivita: tipoAttivita,
                    data: data,
                  );
                  Navigator.of(context).pop(nuovaAttivita);
                },
                child: const Text('Salva'),
              ),
            ],
          );
        });
      },
    );

    if (result != null) {
      if (isModifica) {
        await ref.read(attivitaCuraProvider.notifier).aggiornaAttivita(result);
      } else {
        await ref.read(attivitaCuraProvider.notifier).aggiungiAttivita(result);
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() => (isEmpty) ? this : this[0].toUpperCase() + substring(1);
}
