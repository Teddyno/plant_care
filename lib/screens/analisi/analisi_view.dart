import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/grafici/pie_chart.dart';
import '../../components/grafici/storico_cure_widget.dart';
import '../../providers/piante_provider.dart';
import '../../providers/analisi_provider.dart';
import '../../providers/attivita_cura_provider.dart';
import '../../providers/categorie_provider.dart';
import '../../providers/specie_provider.dart';

/// Schermata di analisi
class AnalisiView extends ConsumerWidget {
  const AnalisiView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Ascolta" i provider necessari per la vista.
    final pianteState = ref.watch(pianteProvider);
    final distribuzioneCategorie = ref.watch(distribuzioneCategorieProvider);

    // Gestisce lo stato di caricamento generale
    if (pianteState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Riverpod si occuperà di aggiornare a cascata tutti i provider dipendenti.
          ref.invalidate(pianteProvider);
          ref.invalidate(attivitaCuraProvider);
          ref.invalidate(tutteLeCategorieProvider);
          ref.invalidate(tutteLeSpecieProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Numero totale di piante
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.eco, color: Colors.green[700], size: 48),
                        const SizedBox(height: 8),
                        Text('${pianteState.piante.length}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 4),
                        const Text('Numero totale di piante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Distribuzione per tipologia/categoria
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Distribuzione per tipologia/categoria',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        distribuzioneCategorie.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.only(top: 24.0),
                          child: Text('Dati non disponibili o in caricamento...'),
                        )
                            : SizedBox(
                          height: 260,
                          child: PlantPieChart(conteggioCategorie: distribuzioneCategorie),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Grafico delle attività di cura annuali
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Attività di Cura Annuale',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        const StoricoCure(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
