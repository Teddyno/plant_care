import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/PromemoriaModel.dart';
import '../../providers/piante_provider.dart';
import '../../providers/promemoria_provider.dart';
import '../../providers/specie_provider.dart';
import 'piante_detail_view.dart';

// Schermata dashboard "Consumer" reattivo ai dati globali.
class PianteDashboardView extends ConsumerWidget {
  const PianteDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Osserva lo stato di tutti i provider di cui abbiamo bisogno
    final pianteState = ref.watch(pianteProvider);
    final promemoriaState = ref.watch(promemoriaProvider);
    final specieAsyncValue = ref.watch(tutteLeSpecieProvider);

    final isLoading = pianteState.isLoading || promemoriaState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: isLoading && promemoriaState.promemoria.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await ref.read(pianteProvider.notifier).caricaPiante();
          await ref.read(promemoriaProvider.notifier).calcolaPromemoria();
          ref.invalidate(tutteLeSpecieProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPianteRecenti(context, pianteState.pianteRecenti, specieAsyncValue),
            const SizedBox(height: 24),
            _buildPromemoria(context, ref, promemoriaState),
          ],
        ),
      ),
    );
  }

  // Costruisce la sezione "Ultime piante aggiunte"
  Widget _buildPianteRecenti(BuildContext context, List<Pianta> pianteRecenti, AsyncValue<List<Specie>> specieAsyncValue) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(0.1), Theme.of(context).colorScheme.primary.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ultime piante aggiunte', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 16),
          if (pianteRecenti.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Nessuna pianta aggiunta ancora', style: TextStyle(color: Colors.grey, fontSize: 16))))
          else
            specieAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Errore specie: $err')),
              data: (tutteLeSpecie) {
                return Column(
                  children: pianteRecenti.map((pianta) {
                    final specie = _getSpecieById(pianta.idSpecie, tutteLeSpecie);
                    return Container(
                      key: ValueKey(pianta.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: ListTile(
                        leading: pianta.foto != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(pianta.foto!, width: 40, height: 40, fit: BoxFit.cover))
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.local_florist, size: 40, color: Colors.grey),
                                ),
                              ),
                        title: Text(pianta.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (specie != null) Text(specie.nome, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            Text('Acquisita il: ${_formattaData(pianta.dataAcquisto)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            Row(children: [_getStatoIcon(pianta.stato), const SizedBox(width: 4), Text(pianta.stato, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))]),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PianteDetailView(pianta: pianta))),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // Costruisce la sezione "Promemoria attività di cura"
  Widget _buildPromemoria(BuildContext context, WidgetRef ref, PromemoriaState promemoriaState) {
    final promemoria = promemoriaState.promemoria;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Promemoria attività di cura', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange[700])),
          const SizedBox(height: 16),
          if (promemoria.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Nessuna attività imminente. Ottimo lavoro!', style: TextStyle(color: Colors.grey, fontSize: 16))))
          else
            ...promemoria.map((p) {
              final differenzaGiorni = _calcolaDifferenzaGiorni(p.dataScadenza);
              final scadenza = _formattaScadenza(p.dataScadenza, differenzaGiorni);
              final isScadutoOggi = differenzaGiorni <= 0;

              final uniqueId = '${p.pianta.id}_${p.attivita.name}';
              final isCompletata = (uniqueId == promemoriaState.idAttivitaAppenaCompletata);

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: isCompletata ? 0.0 : 1.0,
                child: Card(
                  key: ValueKey(uniqueId),
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isScadutoOggi && !isCompletata ? Colors.red.shade50 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _getAttivitaColor(p.attivita).withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_getAttivitaIcon(p.attivita), color: _getAttivitaColor(p.attivita), size: 24),
                      ),
                      title: Text(
                        _getAttivitaNome(p.attivita),
                        style: TextStyle(fontWeight: FontWeight.w600, decoration: isCompletata ? TextDecoration.lineThrough : TextDecoration.none, color: isCompletata ? Colors.grey : Colors.black),
                      ),
                      subtitle: Text(
                        '${p.pianta.nome}\nScadenza: $scadenza',
                        style: TextStyle(color: isCompletata ? Colors.grey : (isScadutoOggi ? Colors.red.shade800 : Colors.grey.shade600), decoration: isCompletata ? TextDecoration.lineThrough : TextDecoration.none),
                      ),
                      isThreeLine: true,
                      // Mostra il pulsante o la spunta solo se l'attività è di oggi o passata
                      trailing: isCompletata
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                          : (isScadutoOggi
                          ? ElevatedButton(
                        onPressed: () => ref.read(promemoriaProvider.notifier).completaAttivita(p),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        child: const Text('Eseguita'),
                      )
                          : null // Non mostrare nulla per le attività future
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // --- METODI DI LOGICA ---
  
  // Restituisce la specie corrispondente all'ID, o null se non trovata.
  Specie? _getSpecieById(int idSpecie, List<Specie> tutteLeSpecie) {
    try {
      return tutteLeSpecie.firstWhere((specie) => specie.id == idSpecie);
    } catch (e) {
      return null;
    }
  }

  // Restituisce una stringa formattata della data in formato "dd/mm/yyyy".
  String _formattaData(DateTime data) {
    final oggi = DateTime.now();
    final differenza = oggi.difference(data).inDays;
    if (differenza == 0) return 'Oggi';
    if (differenza == 1) return 'Ieri';
    if (differenza < 7) return '$differenza giorni fa';
    return '${data.day}/${data.month}/${data.year}';
  }

  int _calcolaDifferenzaGiorni(DateTime data) {
    final now = DateTime.now();
    final oggi = DateTime(now.year, now.month, now.day);
    final giornoDaConfrontare = DateTime(data.year, data.month, data.day);
    return giornoDaConfrontare.difference(oggi).inDays;
  }

  String _formattaScadenza(DateTime dataScadenza, int differenzaGiorni) {
    if (differenzaGiorni < 0) return 'Scaduto da ${differenzaGiorni.abs()} giorni';
    if (differenzaGiorni == 0) return 'Oggi';
    if (differenzaGiorni == 1) return 'Domani';
    if (differenzaGiorni < 7) return 'Tra $differenzaGiorni giorni';
    return 'Tra ${(differenzaGiorni / 7).round()} settimane';
  }

  IconData _getAttivitaIcon(TipoAttivita tipoAttivita) {
    switch (tipoAttivita) {
      case TipoAttivita.innaffiatura: return Icons.water_drop;
      case TipoAttivita.potatura: return Icons.content_cut;
      case TipoAttivita.rinvaso: return Icons.grass;
    }
  }

  Color _getAttivitaColor(TipoAttivita tipoAttivita) {
    switch (tipoAttivita) {
      case TipoAttivita.innaffiatura: return Colors.blue;
      case TipoAttivita.potatura: return Colors.green;
      case TipoAttivita.rinvaso: return Colors.brown;
    }
  }

  Widget _getStatoIcon(String stato) {
    IconData icon;
    Color color;
    switch (stato.toLowerCase()) {
      case 'sana': icon = Icons.check_circle; color = Colors.green; break;
      case 'in crescita': icon = Icons.trending_up; color = Colors.blue; break;
      case 'malata': icon = Icons.sick; color = Colors.red; break;
      case 'in riposo': icon = Icons.bedtime; color = Colors.purple; break;
      case 'necessita cure': icon = Icons.warning; color = Colors.orange; break;
      case 'in fioritura': icon = Icons.local_florist; color = Colors.pink; break;
      default: icon = Icons.help; color = Colors.grey;
    }
    return Icon(icon, color: color, size: 16);
  }

  String _getAttivitaNome(TipoAttivita tipoAttivita) {
    switch (tipoAttivita) {
      case TipoAttivita.innaffiatura: return 'Innaffiatura';
      case TipoAttivita.potatura: return 'Potatura';
      case TipoAttivita.rinvaso: return 'Rinvaso';
    }
  }
}