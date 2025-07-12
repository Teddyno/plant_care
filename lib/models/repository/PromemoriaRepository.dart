import '../../services/db/DatabaseHelper.dart';
import '../PiantaModel.dart';
import '../PromemoriaModel.dart';

class PromemoriaRepository {
  final dbHelper = DatabaseHelper.instance;


  // logica per calcolare e restituire i promemoria imminenti.
  Future<List<Promemoria>> getPromemoriaImminenti() async {
    final List<Promemoria> promemoriaFinali = [];

    // Recupero tutte le piante dal database.
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('piante');
    final List<Pianta> tutteLePiante = List.generate(maps.length, (i) => Pianta.fromMap(maps[i]));

    // Per ogni pianta, calcolo le prossime scadenze delle attività.
    for (final pianta in tutteLePiante) {

      // --- Calcolo scadenza INNAFFIATURA ---
      if (pianta.frequenzaInnaffiatura > 0) {
        // Recupero l'ultima volta che ho innaffiato questa pianta
        final ultimaInnaffiatura = await dbHelper.getUltimaAttivita(pianta.id!, 'innaffiatura');
        // La data di partenza è l'ultima innaffiatura o la data di acquisto se non è mai stata innaffiata.
        final dataPartenzaInnaffiatura = ultimaInnaffiatura ?? pianta.dataAcquisto;
        // Calcolo la prossima scadenza
        final prossimaInnaffiatura = dataPartenzaInnaffiatura.add(Duration(days: pianta.frequenzaInnaffiatura));
        promemoriaFinali.add(Promemoria(
          pianta: pianta, 
          attivita: TipoAttivita.innaffiatura, 
          dataScadenza: prossimaInnaffiatura));
      }

      // --- Calcolo scadenza POTATURA ---
      if (pianta.frequenzaPotatura > 0) {
        final ultimaPotatura = await dbHelper.getUltimaAttivita(pianta.id!, 'potatura');
        final dataPartenzaPotatura = ultimaPotatura ?? pianta.dataAcquisto;
        final prossimaPotatura = dataPartenzaPotatura.add(Duration(days: pianta.frequenzaPotatura));
        promemoriaFinali.add(Promemoria(pianta: pianta, attivita: TipoAttivita.potatura, dataScadenza: prossimaPotatura));
      }

      // --- Calcolo scadenza RINVASO ---
       if (pianta.frequenzaRinvaso > 0) {
        final ultimoRinvaso = await dbHelper.getUltimaAttivita(pianta.id!, 'rinvaso');
        final dataPartenzaRinvaso = ultimoRinvaso ?? pianta.dataAcquisto;
        final prossimoRinvaso = dataPartenzaRinvaso.add(Duration(days: pianta.frequenzaRinvaso));
        promemoriaFinali.add(Promemoria(pianta: pianta, attivita: TipoAttivita.rinvaso, dataScadenza: prossimoRinvaso));
      }
    }

    // Filtro i risultati per tenere solo quelli "imminenti" (es. nei prossimi 7 giorni)
    final oggi = DateTime.now();
    final promemoriaImminenti = promemoriaFinali.where((p) {
      return p.dataScadenza.isAfter(oggi.subtract(const Duration(days: 1))) && p.dataScadenza.isBefore(oggi.add(const Duration(days: 7)));
    }).toList();


    // Ordino i promemoria dal più urgente al meno urgente.
    promemoriaImminenti.sort((a, b) => a.dataScadenza.compareTo(b.dataScadenza));

    // Restituisco la lista pronta per la UI.
    return promemoriaImminenti;
  }
}
