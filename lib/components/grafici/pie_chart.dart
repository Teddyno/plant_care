import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget che visualizza un grafico a torta per rappresentare la distribuzione delle piante per categoria.
/// Mostra la percentuale di piante appartenenti a ciascuna categoria con colori distinti.
/// Include una legenda interattiva che mostra le categorie e le relative percentuali.
/// Il layout si adatta automaticamente all'orientamento del dispositivo.
class PlantPieChart extends StatefulWidget {
  /// Mappa che contiene le categorie delle piante come chiave e il conteggio come valore.
  /// Utilizzata per calcolare le percentuali e generare le sezioni del grafico.
  final Map<String, int> conteggioCategorie;

  /// Costruttore del grafico a torta
  /// @param conteggioCategorie Mappa con le categorie e i relativi conteggi
  const PlantPieChart({super.key, required this.conteggioCategorie});

  @override
  State<PlantPieChart> createState() => _PlantPieChartState();
}

/// Stato interno del grafico a torta.
/// Gestisce l'interazione dell'utente e l'aggiornamento dell'aspetto del grafico.
class _PlantPieChartState extends State<PlantPieChart> {
  /// Indice della sezione attualmente toccata dall'utente nel grafico.
  /// Utilizzato per evidenziare la sezione selezionata.
  /// -1 indica che nessuna sezione è toccata.
  int touchedIndex = -1;

  /// Costruisce l'interfaccia utente del grafico a torta
  @override
  Widget build(BuildContext context) {
    // Se non ci sono dati, mostra un messaggio informativo
    if (widget.conteggioCategorie.isEmpty) {
      return Center(
        child: Text(
          "Nessuna pianta trovata secondo i criteri selezionati.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final orientation = MediaQuery.of(context).orientation;
    final screenHeight = MediaQuery.of(context).size.height;

    if (orientation == Orientation.landscape) {
      // Layout orizzontale: grafico e legenda affiancati per sfruttare lo spazio
      return Row(
        children: [
          // Grafico a torta (occupa 2/5 dello spazio)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 1,
                  centerSpaceRadius: 0,
                  sections: _showingSections(widget.conteggioCategorie),
                ),
              ),
            ),
          ),
          // Legenda (occupa 3/5 dello spazio)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildLegenda(widget.conteggioCategorie),
            ),
          ),
        ],
      );
    } else {
      // Layout verticale: grafico sopra, dettagli/legenda sotto
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grafico a torta che si espande per occupare lo spazio disponibile
          Expanded(
            child: AspectRatio(
              aspectRatio: screenHeight < 600 ? 1.0 : 1.3, // Più compatto su schermi piccoli
              child: PieChart(
                PieChartData(
                  sectionsSpace: 1,
                  centerSpaceRadius: 0,
                  sections: _showingSections(widget.conteggioCategorie),
                ),
              ),
            ),
          ),
          // Spazio tra grafico e dettagli
          const SizedBox(height: 24),
          // Dettagli/Legenda in basso, scrollabile se necessario
          Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight < 600 ? 80 : 120, // Altezza adattiva
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SingleChildScrollView(
              child: _buildLegenda(widget.conteggioCategorie),
            ),
          ),
        ],
      );
    }
  }

  /// Genera le sezioni del grafico a torta in base ai dati delle categorie.
  /// Ogni sezione rappresenta una categoria con un colore distinto e un raggio personalizzato.
  /// Le sezioni toccate dall'utente vengono evidenziate con un raggio maggiore.
  ///
  /// @param conteggioCategorie Mappa delle categorie e del numero di piante per ciascuna categoria.
  /// @return Lista di [PieChartSectionData] da visualizzare nel grafico.
  List<PieChartSectionData> _showingSections(
    Map<String, int> conteggioCategorie,
  ) {
    // Palette di colori per le diverse categorie
    final List<Color> colori = Colors.primaries;
    List<PieChartSectionData> sezioni = [];
    int index = 0;
    
    // Crea una sezione per ogni categoria
    for (var entry in conteggioCategorie.entries) {
      final isTouched = index == touchedIndex;
      final colore = colori[index % colori.length]; // Cicla i colori se ci sono più categorie
      
      sezioni.add(
        PieChartSectionData(
          color: colore,
          value: entry.value.toDouble(),
          title: '', // Non mostra testo sulle sezioni
          radius: isTouched ? 80 : 70, // Raggio maggiore se toccata
        ),
      );
      index++;
    }
    return sezioni;
  }

  /// Costruisce la legenda che mostra le categorie e le relative percentuali.
  /// Ogni voce della legenda include un quadrato colorato, il nome della categoria
  /// e la percentuale corrispondente rispetto al totale.
  ///
  /// @param conteggioCategorie Mappa delle categorie e del numero di piante per ciascuna categoria.
  /// @return Widget [Wrap] contenente la legenda colorata con testo e percentuali.
  Widget _buildLegenda(Map<String, int> conteggioCategorie) {
    // Calcola il totale delle piante per calcolare le percentuali
    final totale = conteggioCategorie.values.fold<int>(0, (a, b) => a + b);
    final List<Color> colori = Colors.primaries;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return Wrap(
      spacing: isSmallScreen ? 16 : 24,
      runSpacing: isSmallScreen ? 12 : 16,
      children: conteggioCategorie.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final categoria = entry.value.key;
        final valore = entry.value.value;
        final colore = colori[index % colori.length];
        final percentuale = (valore / totale) * 100;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quadrato colorato che rappresenta la categoria
            Container(
              width: isSmallScreen ? 10 : 12, 
              height: isSmallScreen ? 10 : 12, 
              color: colore
            ),
            SizedBox(width: isSmallScreen ? 4 : 6),
            // Testo con nome categoria e percentuale
            Flexible(
              child: Text(
                isSmallScreen 
                  ? '$categoria\n${percentuale.toStringAsFixed(1)}%'
                  : '$categoria (${percentuale.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                ),
                maxLines: isSmallScreen ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
