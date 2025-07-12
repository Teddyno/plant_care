import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/CategoriaModel.dart';
import '../models/repository/CategorieRepository.dart';

/// Il Notifier che gestisce la logica per le Categorie.
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

  Future<void> aggiungiCategoria(String nome) async {
    await _repository.aggiungiCategoria(Categoria(nome: nome));
    await caricaCategorie();
  }

  /// Aggiorna una categoria esistente e ricarica la lista.
  Future<void> aggiornaCategoria(Categoria categoria) async {
    await _repository.aggiornaCategoria(categoria);
    await caricaCategorie();
  }

  /// Elimina una categoria e ricarica la lista.
  Future<void> eliminaCategoria(int id) async {
    await _repository.eliminaCategoria(id);
    await caricaCategorie();
  }
}

final tutteLeCategorieProvider = StateNotifierProvider.autoDispose<CategorieNotifier, AsyncValue<List<Categoria>>>((ref) {
  return CategorieNotifier();
});
