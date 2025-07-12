import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/CategoriaModel.dart';
import '../models/repository/CategorieRepository.dart'; // Usa il tuo repository

/// Il Notifier che gestisce la logica per le Categorie.
/// Permette di caricare, aggiungere, aggiornare ed eliminare categorie.
class CategorieNotifier extends StateNotifier<AsyncValue<List<Categoria>>> {
  final CategorieRepository _repository = CategorieRepository.instance;

  CategorieNotifier() : super(const AsyncValue.loading()) {
    caricaCategorie();
  }

  /// Carica tutte le categorie dal database.
  Future<void> caricaCategorie() async {
    try {
      state = const AsyncValue.loading();
      final categorie = await _repository.getTutteLeCategorie();
      state = AsyncValue.data(categorie);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Aggiunge una nuova categoria e ricarica la lista.
  Future<void> aggiungiCategoria(String nome) async {
    // [CORREZIONE] Allineato il nome del metodo a quello del tuo repository.
    await _repository.aggiungiCategoria(Categoria(nome: nome));
    await caricaCategorie();
  }

  /// Aggiorna una categoria esistente e ricarica la lista.
  Future<void> aggiornaCategoria(Categoria categoria) async {
    // [CORREZIONE] Allineato il nome del metodo a quello del tuo repository.
    await _repository.aggiornaCategoria(categoria);
    await caricaCategorie();
  }

  /// Elimina una categoria e ricarica la lista.
  Future<void> eliminaCategoria(int id) async {
    // [CORREZIONE] Allineato il nome del metodo a quello del tuo repository.
    await _repository.eliminaCategoria(id);
    await caricaCategorie();
  }
}

/// Provider che espone la lista di categorie e permette di interagire con essa.
/// Sostituisce il tuo precedente FutureProvider.
final tutteLeCategorieProvider = StateNotifierProvider<CategorieNotifier, AsyncValue<List<Categoria>>>((ref) {
  return CategorieNotifier();
});
