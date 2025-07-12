import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'attivita_cura_provider.dart';
import 'piante_provider.dart';
import 'categorie_provider.dart';
import 'specie_provider.dart';

/// Provider per il grafico a torta della distribuzione delle piante per categoria.
final distribuzioneCategorieProvider = Provider<Map<String, int>>((ref) {
  final pianteState = ref.watch(pianteProvider);
  final categorieState = ref.watch(tutteLeCategorieProvider);
  final specieState = ref.watch(tutteLeSpecieProvider);
  final piante = pianteState.piante;
  final categorie = categorieState.asData?.value ?? [];
  final specie = specieState.asData?.value ?? [];

  if (piante.isEmpty || categorie.isEmpty || specie.isEmpty) {
    return {};
  }

  final Map<int, String> mapIdCategoriaNome = { for (var c in categorie) c.id!: c.nome };
  final Map<int, int> mapIdSpecieIdCategoria = { for (var s in specie) s.id!: s.idCategoria };

  final conteggio = <String, int>{};
  for (var pianta in piante) {
    final idCategoria = mapIdSpecieIdCategoria[pianta.idSpecie];
    final nomeCategoria = mapIdCategoriaNome[idCategoria] ?? 'Sconosciuta';
    conteggio.update(nomeCategoria, (value) => value + 1, ifAbsent: () => 1);
  }
  return conteggio;
});


/// Questo provider deriva il suo stato direttamente da `attivitaCuraProvider`.
/// In questo modo, ogni volta che una nuova attività viene aggiunta (e quindi
/// lo stato di `attivitaCuraProvider` cambia), questo provider si ricalcola
/// automaticamente, garantendo che il grafico sia SEMPRE aggiornato.
final conteggioAttivitaGiornalieroProvider = Provider<Map<DateTime, int>>((ref) {
  // "Ascolta" lo stato delle attività di cura
  final tutteLeAttivita = ref.watch(attivitaCuraProvider).tutteLeAttivita;

  if (tutteLeAttivita.isEmpty) {
    return {};
  }

  // Raggruppa le attività per giorno, ignorando l'orario.
  // Usa il pacchetto 'collection' per la funzione groupBy.
  final groupedByDay = groupBy(
    tutteLeAttivita,
        (attivita) => DateTime(attivita.data.year, attivita.data.month, attivita.data.day),
  );

  // Converte i gruppi in una mappa che conta le attività per ogni giorno.
  final conteggio = groupedByDay.map((giorno, attivitaDelGiorno) {
    return MapEntry(giorno, attivitaDelGiorno.length);
  });

  return conteggio;
});
