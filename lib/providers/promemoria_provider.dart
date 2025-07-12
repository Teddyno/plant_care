import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/AttivitaCuraModel.dart';
import '../models/PromemoriaModel.dart';
import '../models/PiantaModel.dart';
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
    // Imposta i listener per reagire ai cambiamenti.
    _ref.listen(pianteProvider, (_, __) => calcolaPromemoria());
    _ref.listen(attivitaCuraProvider, (_, __) => calcolaPromemoria());

    // Esegue il calcolo iniziale.
    calcolaPromemoria();
  }

  /// [SOLUZIONE] Metodo reso asincrono per restituire un Future,
  /// come richiesto dalla UI (es. RefreshIndicator).
  Future<void> calcolaPromemoria() async {
    // Se una delle dipendenze sta ancora caricando, non fare nulla.
    if (_ref.read(pianteProvider).isLoading) return;

    final piante = _ref.read(pianteProvider).piante;
    // Aggiunto 'await' per attendere il completamento del calcolo.
    await _eseguiCalcoloPromemoria(piante);
  }

  /// Metodo privato che esegue il calcolo effettivo dei promemoria.
  Future<void> _eseguiCalcoloPromemoria(List<Pianta> piante) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final List<Promemoria> promemoriaGenerati = [];
    final now = DateTime.now();
    final sogliaImminenza = now.add(const Duration(days: 7));

    for (var pianta in piante) {
      // Controlla l'innaffiatura
      if (pianta.frequenzaInnaffiatura > 0) {
        final ultima = await _dbHelper.getUltimaAttivita(pianta.id!, 'innaffiatura');
        final prossimaScadenza = (ultima ?? pianta.dataAcquisto).add(Duration(days: pianta.frequenzaInnaffiatura));
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

    if (mounted) {
      state = state.copyWith(promemoria: promemoriaGenerati, isLoading: false);
    }
  }

  /// Metodo che viene chiamato quando un utente completa un'attività.
  Future<void> completaAttivita(Promemoria promemoria) async {
    state = state.copyWith(idAttivitaAppenaCompletata: promemoria.pianta.id);

    final nuovaAttivita = AttivitaCura(
      idPianta: promemoria.pianta.id!,
      tipoAttivita: promemoria.attivita.name,
      data: DateTime.now(),
    );

    await _ref.read(attivitaCuraProvider.notifier).aggiungiAttivita(nuovaAttivita);

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
