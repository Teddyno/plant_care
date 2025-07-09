import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/PiantaModel.dart';
import '../models/repository/PianteRepository.dart';

// 1. MODIFICA: Aggiungiamo la lista delle piante recenti allo stato.
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

// 2. MODIFICA: Il Notifier ora calcola e imposta entrambe le liste.
class PianteNotifier extends StateNotifier<PianteState> {
  final PianteRepository _pianteRepository = PianteRepository();

  PianteNotifier() : super(PianteState()) {
    caricaPiante();
  }

  Future<void> caricaPiante() async {
    state = state.copyWith(isLoading: true);

    final tutteLePiante = await _pianteRepository.getTutteLePiante();

    // Calcoliamo qui le piante recenti
    final pianteOrdinate = List<Pianta>.from(tutteLePiante)
      ..sort((a, b) => b.dataAcquisto.compareTo(a.dataAcquisto));
    final recenti = pianteOrdinate.take(5).toList();

    // Aggiorniamo lo stato con entrambe le liste
    state = state.copyWith(
      piante: tutteLePiante,
      pianteRecenti: recenti,
      isLoading: false,
    );
  }

  Future<void> aggiungiPianta(Pianta pianta) async {
    await _pianteRepository.aggiungiPianta(pianta);
    await caricaPiante();
  }

  Future<void> aggiornaPianta(Pianta pianta) async {
    await _pianteRepository.aggiornaPianta(pianta);
    await caricaPiante();
  }

  Future<void> eliminaPianta(int id) async {
    await _pianteRepository.eliminaPianta(id);
    await caricaPiante();
  }
}


final pianteProvider = StateNotifierProvider<PianteNotifier, PianteState>((ref) {
  return PianteNotifier();
});