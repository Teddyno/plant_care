import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/PiantaModel.dart';
import '../models/repository/PianteRepository.dart';

// Definisce lo stato per le piante, che include la lista
// di tutte le piante, una lista delle piante più recenti e un flag di caricamento.
class PianteState {
  final List<Pianta> piante;
  final List<Pianta> pianteRecenti;
  final bool isLoading;

  PianteState({
    this.piante = const [],
    this.pianteRecenti = const [],
    this.isLoading = false
  });

  PianteState copyWith({
    List<Pianta>? piante,
    List<Pianta>? pianteRecenti,
    bool? isLoading
  }) {
    return PianteState(
      piante: piante ?? this.piante,
      pianteRecenti: pianteRecenti ?? this.pianteRecenti,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Il Notifier che gestisce la logica per caricare, aggiungere,
// modificare ed eliminare le piante.
class PianteNotifier extends StateNotifier<PianteState> {
  final PianteRepository _repository = PianteRepository();

  PianteNotifier() : super(PianteState()) {
    caricaPiante();
  }

  // Carica tutte le piante e le piante recenti dal database.
  Future<void> caricaPiante() async {
    state = state.copyWith(isLoading: true);

    final results = await Future.wait([
      _repository.getTutteLePiante(),
      _repository.getPianteRecenti(),
    ]);

    final tutteLePiante = results[0];
    final pianteRecenti = results[1];

    state = state.copyWith(
        piante: tutteLePiante,
        pianteRecenti: pianteRecenti,
        isLoading: false
    );
  }

  // Aggiunge una nuova pianta e ricarica la lista per aggiornare la UI.
  Future<void> aggiungiPianta(Pianta pianta) async {
    await _repository.aggiungiPianta(pianta);
    await caricaPiante();
  }

  // Aggiorna una pianta esistente e ricarica la lista.
  Future<void> aggiornaPianta(Pianta pianta) async {
    await _repository.aggiornaPianta(pianta);
    await caricaPiante();
  }

  // Elimina una pianta e forza l'aggiornamento degli altri provider.
  Future<void> eliminaPianta(int id) async {
    await _repository.eliminaPianta(id);

    await caricaPiante();
  }
}

// Il provider globale che espone il `PianteNotifier` al resto dell'app.
final pianteProvider = StateNotifierProvider<PianteNotifier, PianteState>((ref) {
  return PianteNotifier();
});
