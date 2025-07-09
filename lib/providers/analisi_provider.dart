import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'piante_provider.dart';
import 'specie_provider.dart';
import 'categorie_provider.dart';
import 'attivita_cura_provider.dart';

/// Provider che calcola la distribuzione delle piante per categoria.
/// Si aggiorna automaticamente se le piante, le specie o le categorie cambiano.
final distribuzioneCategorieProvider = Provider<Map<String, int>>((ref) {
  // "Ascolta" lo stato dei provider da cui dipende
  final piante = ref.watch(pianteProvider).piante;
  final tutteLeSpecie = ref.watch(tutteLeSpecieProvider).value ?? [];
  final tutteLeCategorie = ref.watch(tutteLeCategorieProvider).value ?? [];

  if (piante.isEmpty || tutteLeSpecie.isEmpty || tutteLeCategorie.isEmpty) {
    return {}; // Restituisce dati vuoti se non è ancora tutto pronto
  }

  final Map<String, int> distribuzione = {};
  for (var pianta in piante) {
    try {
      final specie = tutteLeSpecie.firstWhere((s) => s.id == pianta.idSpecie);
      final categoria = tutteLeCategorie.firstWhere((c) => c.id == specie.idCategoria);
      final nomeCategoria = categoria.nome;
      distribuzione[nomeCategoria] = (distribuzione[nomeCategoria] ?? 0) + 1;
    } catch (e) {
      distribuzione['Senza categoria'] = (distribuzione['Senza categoria'] ?? 0) + 1;
    }
  }
  return distribuzione;
});


/// Provider che calcola le attività mensili per il grafico a barre.
final attivitaMensiliProvider = Provider<List<double>>((ref) {
  final tutteLeAttivita = ref.watch(attivitaCuraProvider).tutteLeAttivita;

  final now = DateTime.now();
  final List<double> attivitaMensili = List.filled(12, 0.0);

  for (var attivita in tutteLeAttivita) {
    final mesiFa = now.difference(attivita.data).inDays ~/ 30;
    if (mesiFa < 12) {
      attivitaMensili[11 - mesiFa]++;
    }
  }
  return attivitaMensili;
});