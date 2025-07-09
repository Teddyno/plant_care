import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/AttivitaCuraModel.dart';
import '../models/PiantaModel.dart';
import '../models/PromemoriaModel.dart';
import '../models/repository/AttivitaCuraRepository.dart';
import 'piante_provider.dart';

// Funzione helper per "pulire" una data dall'orario
DateTime _giornoPreciso(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

class PromemoriaState {
  final List<Promemoria> promemoria;
  final bool isLoading;
  final String? idAttivitaAppenaCompletata;

  PromemoriaState({
    this.promemoria = const [],
    this.isLoading = false,
    this.idAttivitaAppenaCompletata,
  });

  PromemoriaState copyWith({
    List<Promemoria>? promemoria,
    bool? isLoading,
    String? idAttivitaAppenaCompletata,
  }) {
    return PromemoriaState(
      promemoria: promemoria ?? this.promemoria,
      isLoading: isLoading ?? this.isLoading,
      idAttivitaAppenaCompletata: idAttivitaAppenaCompletata,
    );
  }
}

class PromemoriaNotifier extends StateNotifier<PromemoriaState> {
  final Ref _ref;
  final AttivitaCuraRepository _attivitaRepository = AttivitaCuraRepository.instance;

  PromemoriaNotifier(this._ref) : super(PromemoriaState()) {
    _ref.listen(pianteProvider, (previous, next) {
      if (!next.isLoading) {
        calcolaPromemoria();
      }
    });
  }

  Future<void> calcolaPromemoria() async {
    state = state.copyWith(isLoading: true);

    final tutteLePiante = _ref.read(pianteProvider).piante;
    final tutteLeAttivita = await _attivitaRepository.getTutteLeAttivita();
    List<Promemoria> promemoriaCalcolati = [];

    for (var pianta in tutteLePiante) {
      _calcolaProssimaAttivita(pianta, TipoAttivita.innaffiatura, tutteLeAttivita, promemoriaCalcolati);
      _calcolaProssimaAttivita(pianta, TipoAttivita.potatura, tutteLeAttivita, promemoriaCalcolati);
      _calcolaProssimaAttivita(pianta, TipoAttivita.rinvaso, tutteLeAttivita, promemoriaCalcolati);
    }

    promemoriaCalcolati.sort((a, b) => a.dataScadenza.compareTo(b.dataScadenza));
    state = state.copyWith(promemoria: promemoriaCalcolati, isLoading: false);
  }

  void _calcolaProssimaAttivita(Pianta pianta, TipoAttivita tipo, List<AttivitaCura> attivita, List<Promemoria> listaPromemoria) {
    final attivitaPrecedenti = attivita.where((a) => a.idPianta == pianta.id && a.tipoAttivita == tipo.name).toList();
    DateTime ultimaData;
    if (attivitaPrecedenti.isNotEmpty) {
      attivitaPrecedenti.sort((a, b) => b.data.compareTo(a.data));
      ultimaData = attivitaPrecedenti.first.data;
    } else {
      ultimaData = pianta.dataAcquisto;
    }

    // CORREZIONE: Usa la data "pulita" per il calcolo
    int frequenza = _getFrequenza(pianta, tipo);
    DateTime dataScadenza = _giornoPreciso(ultimaData).add(Duration(days: frequenza));

    if (dataScadenza.isBefore(_giornoPreciso(DateTime.now()).add(const Duration(days: 30)))) {
      listaPromemoria.add(Promemoria(
        pianta: pianta,
        attivita: tipo,
        dataScadenza: dataScadenza,
      ));
    }
  }

  int _getFrequenza(Pianta pianta, TipoAttivita tipo) {
    switch(tipo) {
      case TipoAttivita.innaffiatura: return pianta.frequenzaInnaffiatura;
      case TipoAttivita.potatura: return pianta.frequenzaPotatura;
      case TipoAttivita.rinvaso: return pianta.frequenzaRinvaso;
    }
  }

  Future<void> completaAttivita(Promemoria promemoria) async {
    final uniqueId = '${promemoria.pianta.id}_${promemoria.attivita.name}';
    state = state.copyWith(idAttivitaAppenaCompletata: uniqueId);

    // CORREZIONE: Salva la nuova attività con la data di oggi "pulita"
    final nuovaAttivita = AttivitaCura(
      idPianta: promemoria.pianta.id!,
      tipoAttivita: promemoria.attivita.name,
      data: _giornoPreciso(DateTime.now()),
    );
    await _attivitaRepository.aggiungiAttivita(nuovaAttivita);

    await Future.delayed(const Duration(milliseconds: 1500));
    await calcolaPromemoria();

    // Resetta lo stato per sicurezza (anche se calcolaPromemoria già lo fa)
    state = state.copyWith(idAttivitaAppenaCompletata: null);
  }
}

final promemoriaProvider = StateNotifierProvider<PromemoriaNotifier, PromemoriaState>((ref) {
  return PromemoriaNotifier(ref);
});