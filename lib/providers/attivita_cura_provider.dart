import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/AttivitaCuraModel.dart';
import '../models/repository/AttivitaCuraRepository.dart';

/// Definisce lo stato per le attività di cura, che include la lista
/// di tutte le attività e un flag per indicare lo stato di caricamento.
class AttivitaCuraState {
  final List<AttivitaCura> tutteLeAttivita;
  final bool isLoading;

  AttivitaCuraState({this.tutteLeAttivita = const [], this.isLoading = false});

  AttivitaCuraState copyWith({List<AttivitaCura>? tutteLeAttivita, bool? isLoading}) {
    return AttivitaCuraState(
      tutteLeAttivita: tutteLeAttivita ?? this.tutteLeAttivita,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Il Notifier che gestisce la logica per caricare e aggiungere attività di cura.
class AttivitaCuraNotifier extends StateNotifier<AttivitaCuraState> {
  final AttivitaCuraRepository _repository = AttivitaCuraRepository.instance;

  AttivitaCuraNotifier() : super(AttivitaCuraState()) {
    caricaAttivita();
  }

  /// Carica tutte le attività dal database all'avvio.
  Future<void> caricaAttivita() async {
    state = state.copyWith(isLoading: true);
    final attivita = await _repository.getTutteLeAttivita();
    state = state.copyWith(tutteLeAttivita: attivita, isLoading: false);
  }

  /// Aggiunge una nuova attività di cura.
  /// Questo è il metodo chiamato dall'esterno per aggiornare lo stato.
  Future<void> aggiungiAttivita(AttivitaCura nuovaAttivita) async {
    // Salva la nuova attività nel database.
    await _repository.aggiungiAttivita(nuovaAttivita);

    // [SOLUZIONE] Ricarica tutte le attività dal database.
    // Questo approccio è robusto e garantisce che lo stato sia sempre
    // sincronizzato dopo un'aggiunta, risolvendo l'errore 'void' e
    // assicurando l'aggiornamento automatico della UI.
    await caricaAttivita();
  }
}

/// Il provider globale che espone il `AttivitaCuraNotifier` al resto dell'app.
final attivitaCuraProvider = StateNotifierProvider<AttivitaCuraNotifier, AttivitaCuraState>((ref) {
  return AttivitaCuraNotifier();
});
