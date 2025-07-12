import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/SpecieModel.dart';
import '../models/repository/SpecieRepository.dart';

// Il Notifier che gestisce la logica per le Specie.
class SpecieNotifier extends StateNotifier<AsyncValue<List<Specie>>> {
  final SpecieRepository _repository = SpecieRepository.instance;

  SpecieNotifier() : super(const AsyncValue.loading()) {
    caricaSpecie();
  }

  // Carica tutte le specie dal database.
  Future<void> caricaSpecie() async {
    try {
      state = const AsyncValue.loading();
      final specie = await _repository.getTutteLeSpecie();
      state = AsyncValue.data(specie);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Aggiunge una nuova specie e ricarica la lista.
  Future<void> aggiungiSpecie(Specie specie) async {
    await _repository.aggiungiSpecie(specie);
    await caricaSpecie();
  }

  // Aggiorna una specie esistente e ricarica la lista.
  Future<void> aggiornaSpecie(Specie specie) async {
    await _repository.aggiornaSpecie(specie);
    await caricaSpecie();
  }

  // Elimina una specie e ricarica la lista.
  Future<void> eliminaSpecie(int id) async {
    await _repository.eliminaSpecie(id);
    await caricaSpecie();
  }
}

final tutteLeSpecieProvider = StateNotifierProvider<SpecieNotifier, AsyncValue<List<Specie>>>((ref) {
  return SpecieNotifier();
});
