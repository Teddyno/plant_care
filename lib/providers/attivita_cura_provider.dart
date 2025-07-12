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

/// Il Notifier che gestisce la logica per caricare e modificare le attività di cura.
class AttivitaCuraNotifier extends StateNotifier<AttivitaCuraState> {
  // Assumo che tu abbia un AttivitaCuraRepository. Se non lo hai, puoi usare direttamente il DatabaseHelper.
  final AttivitaCuraRepository _repository = AttivitaCuraRepository.instance;

  AttivitaCuraNotifier() : super(AttivitaCuraState()) {
    caricaAttivita();
  }

  /// Carica tutte le attività dal database.
  Future<void> caricaAttivita() async {
    state = state.copyWith(isLoading: true);
    final attivita = await _repository.getTutteLeAttivita();
    state = state.copyWith(tutteLeAttivita: attivita, isLoading: false);
  }

  /// Aggiunge una nuova attività di cura e ricarica la lista.
  Future<void> aggiungiAttivita(AttivitaCura nuovaAttivita) async {
    await _repository.aggiungiAttivita(nuovaAttivita);
    await caricaAttivita();
  }

  /// [NUOVO] Aggiorna un'attività di cura esistente e ricarica la lista.
  Future<void> aggiornaAttivita(AttivitaCura attivita) async {
    await _repository.aggiornaAttivita(attivita);
    await caricaAttivita();
  }

  /// [NUOVO] Elimina un'attività di cura e ricarica la lista.
  Future<void> eliminaAttivita(int id) async {
    await _repository.eliminaAttivita(id);
    await caricaAttivita();
  }
}

/// Il provider globale che espone il `AttivitaCuraNotifier` al resto dell'app.
final attivitaCuraProvider = StateNotifierProvider<AttivitaCuraNotifier, AttivitaCuraState>((ref) {
  return AttivitaCuraNotifier();
});
