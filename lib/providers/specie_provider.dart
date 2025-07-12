import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/SpecieModel.dart';
import '../models/repository/SpecieRepository.dart'; // Usa il tuo repository

/// Il Notifier che gestisce la logica per le Specie.
/// Permette di caricare, aggiungere, aggiornare ed eliminare specie.
class SpecieNotifier extends StateNotifier<AsyncValue<List<Specie>>> {
  // Assumo che il tuo SpecieRepository segua lo stesso pattern di CategorieRepository
  final SpecieRepository _repository = SpecieRepository.instance;

  SpecieNotifier() : super(const AsyncValue.loading()) {
    caricaSpecie();
  }

  /// Carica tutte le specie dal database.
  Future<void> caricaSpecie() async {
    try {
      state = const AsyncValue.loading();
      final specie = await _repository.getTutteLeSpecie();
      state = AsyncValue.data(specie);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Aggiunge una nuova specie e ricarica la lista.
  Future<void> aggiungiSpecie(Specie specie) async {
    // NOTA: Assicurati che il tuo SpecieRepository abbia un metodo 'aggiungiSpecie'.
    await _repository.aggiungiSpecie(specie);
    await caricaSpecie();
  }

  /// Aggiorna una specie esistente e ricarica la lista.
  Future<void> aggiornaSpecie(Specie specie) async {
    // NOTA: Assicurati che il tuo SpecieRepository abbia un metodo 'aggiornaSpecie'.
    await _repository.aggiornaSpecie(specie);
    await caricaSpecie();
  }

  /// Elimina una specie e ricarica la lista.
  Future<void> eliminaSpecie(int id) async {
    // NOTA: Assicurati che il tuo SpecieRepository abbia un metodo 'eliminaSpecie'.
    await _repository.eliminaSpecie(id);
    await caricaSpecie();
  }
}

/// Provider che espone la lista di specie e permette di interagire con essa.
/// Sostituisce il tuo precedente FutureProvider.
final tutteLeSpecieProvider = StateNotifierProvider<SpecieNotifier, AsyncValue<List<Specie>>>((ref) {
  return SpecieNotifier();
});
