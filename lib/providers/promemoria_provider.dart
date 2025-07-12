import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/AttivitaCuraModel.dart';
import '../models/PromemoriaModel.dart';
import '../services/db/DatabaseHelper.dart';
import '../providers/attivita_cura_provider.dart';
import '../providers/piante_provider.dart';

/// Definisce lo stato per i promemoria.
class PromemoriaState {
  final List<Promemoria> promemoria;
  final bool isLoading;
  final int? idAttivitaAppenaCompletata;

  PromemoriaState({
    this.promemoria = const [],
    this.isLoading = false,
    this.idAttivitaAppenaCompletata,
  });

  PromemoriaState copyWith({
    List<Promemoria>? promemoria,
    bool? isLoading,
    int? idAttivitaAppenaCompletata,
  }) {
    return PromemoriaState(
      promemoria: promemoria ?? this.promemoria,
      isLoading: isLoading ?? this.isLoading,
      idAttivitaAppenaCompletata: idAttivitaAppenaCompletata,
    );
  }
}

/// Il Notifier che gestisce la logica dei promemoria.
class PromemoriaNotifier extends StateNotifier<PromemoriaState> {
  final Ref _ref;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  PromemoriaNotifier(this._ref) : super(PromemoriaState()) {
    // Ascolta le modifiche per mantenere la UI sempre aggiornata
    _ref.listen(pianteProvider, (_, __) => calcolaPromemoria());
    _ref.listen(attivitaCuraProvider, (_, __) => calcolaPromemoria());
  }

  /// Calcola e carica i promemoria per le attività di cura scadute e imminenti.
  Future<void> calcolaPromemoria() async {
    state = state.copyWith(isLoading: true);

    final piante = _ref.read(pianteProvider).piante;
    final List<Promemoria> promemoriaGenerati = [];
    final now = DateTime.now();
    // Definiamo una soglia per le attività "imminenti" (es. i prossimi 7 giorni)
    final sogliaImminenza = now.add(const Duration(days: 7));

    for (var pianta in piante) {
      // Controlla l'innaffiatura
      if (pianta.frequenzaInnaffiatura > 0) {
        final ultima = await _dbHelper.getUltimaAttivita(pianta.id!, 'innaffiatura');
        final prossimaScadenza = (ultima ?? pianta.dataAcquisto).add(Duration(days: pianta.frequenzaInnaffiatura));
        // Mostra l'attività se è già scaduta OPPURE se scade entro la soglia di imminenza.
        if (prossimaScadenza.isBefore(sogliaImminenza)) {
          promemoriaGenerati.add(Promemoria(
            pianta: pianta,
            attivita: TipoAttivita.innaffiatura,
            dataScadenza: prossimaScadenza,
          ));
        }
      }

      // Controlla la potatura
      if (pianta.frequenzaPotatura > 0) {
        final ultima = await _dbHelper.getUltimaAttivita(pianta.id!, 'potatura');
        final prossimaScadenza = (ultima ?? pianta.dataAcquisto).add(Duration(days: pianta.frequenzaPotatura));
        if (prossimaScadenza.isBefore(sogliaImminenza)) {
          promemoriaGenerati.add(Promemoria(
            pianta: pianta,
            attivita: TipoAttivita.potatura,
            dataScadenza: prossimaScadenza,
          ));
        }
      }

      // Controlla il rinvaso
      if (pianta.frequenzaRinvaso > 0) {
        final ultima = await _dbHelper.getUltimaAttivita(pianta.id!, 'rinvaso');
        final prossimaScadenza = (ultima ?? pianta.dataAcquisto).add(Duration(days: pianta.frequenzaRinvaso));
        if (prossimaScadenza.isBefore(sogliaImminenza)) {
          promemoriaGenerati.add(Promemoria(
            pianta: pianta,
            attivita: TipoAttivita.rinvaso,
            dataScadenza: prossimaScadenza,
          ));
        }
      }
    }

    promemoriaGenerati.sort((a, b) => a.dataScadenza.compareTo(b.dataScadenza));

    state = state.copyWith(promemoria: promemoriaGenerati, isLoading: false);
  }

  /// Metodo che viene chiamato quando un utente completa un'attività.
  Future<void> completaAttivita(Promemoria promemoria) async {
    state = state.copyWith(idAttivitaAppenaCompletata: promemoria.pianta.id);

    print('Creazione di una nuova attività di cura dal promemoria completato...');

    final nuovaAttivita = AttivitaCura(
      idPianta: promemoria.pianta.id!,
      tipoAttivita: promemoria.attivita.name,
      data: DateTime.now(),
    );

    await _ref.read(attivitaCuraProvider.notifier).aggiungiAttivita(nuovaAttivita);

    print('Nuova attività aggiunta e stato aggiornato.');

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        state = state.copyWith(idAttivitaAppenaCompletata: null);
      }
    });
  }
}

// Definisce il provider, passando il 'ref' al notifier.
final promemoriaProvider = StateNotifierProvider<PromemoriaNotifier, PromemoriaState>((ref) {
  return PromemoriaNotifier(ref);
});
