import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget che visualizza un grafico a barre per rappresentare dati numerici relativi alle piante.
/// Utilizzato principalmente per mostrare statistiche come attività di cura mensili,
/// distribuzione delle piante per categoria, ecc.
/// Ogni barra rappresenta un valore associato a un'etichetta, con tooltip interattivo al tocco.
class PlantBarChart extends StatefulWidget {
  /// Etichette per l'asse X del grafico (es. mesi, categorie, ecc.)
  final List<String> labels;

  /// Valori numerici associati alle etichette, rappresentati come altezza delle barre
  final List<double> values;

  /// Costruttore del grafico a barre
  /// @param labels Lista delle etichette per l'asse X
  /// @param values Lista dei valori numerici corrispondenti
  const PlantBarChart({
    super.key,
    required this.labels,
    required this.values,
  });

  @override
  State<PlantBarChart> createState() => _PlantBarChartState();
}

/// Stato interno del grafico a barre.
/// Gestisce l'interazione dell'utente e l'aggiornamento dell'aspetto del grafico.
class _PlantBarChartState extends State<PlantBarChart> {
  /// Indice della barra attualmente toccata dall'utente.
  /// Utilizzato per evidenziare la barra selezionata e mostrare il tooltip.
  /// 
  /// -1 indica che nessuna barra è toccata.
  int touchedIndex = -1;

  /// Costruisce l'interfaccia utente del grafico a barre
  @override
  Widget build(BuildContext context) {
    /// @return Un widget [SizedBox] contenente il grafico a barre con tooltip e colori dinamici.
    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: BarChart(
                BarChartData(
                  // Calcola il valore massimo per l'asse Y (altezza massima delle barre)
                  maxY: (widget.values.isEmpty ? 1 : (widget.values.reduce((a, b) => a > b ? a : b) + 1)),
                  minY: 0,
                  
                  // Configurazione dell'interazione al tocco
                  barTouchData: BarTouchData(
                    // Configurazione del tooltip che appare al tocco
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = widget.labels[group.x];
                        return BarTooltipItem(
                          label,
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    // Callback chiamata quando l'utente tocca una barra
                    touchCallback: (event, response) {
                      setState(() {
                        touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
                      });
                    },
                  ),
                  
                  // Configurazione degli assi e delle etichette
                  titlesData: FlTitlesData(
                    show: true,
                    // Etichette dell'asse X (bottom)
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          (value.toInt() + 1).toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        reservedSize: 32,
                      ),
                    ),
                    // Etichette dell'asse Y (left)
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Nasconde gli assi destro e superiore
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  
                  // Configurazione del bordo e della griglia
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  
                  // Generazione delle barre del grafico
                  barGroups: List.generate(widget.values.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: widget.values[i],
                          width: 18,
                          // Colore dinamico: verde scuro se toccata, verde chiaro altrimenti
                          color: touchedIndex == i
                              ? Colors.green
                              : Colors.green.shade200,
                          borderRadius: BorderRadius.circular(6),
                          // Barra di sfondo che mostra il valore massimo possibile
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (widget.values.isEmpty ? 1 : (widget.values.reduce((a, b) => a > b ? a : b) + 1)),
                            color: Colors.green.shade50,
                          ),
                        ),
                      ],
                      // Mostra indicatori di tooltip solo per la barra toccata
                      showingTooltipIndicators: touchedIndex == i ? [0] : [],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    'Attività',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'Mesi (1-12)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
