import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/analisi_provider.dart';

/// Un widget che mostra un grafico delle attività di cura annuali,
class StoricoCure extends ConsumerWidget {
  const StoricoCure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Ascolta" il provider che contiene i dati già raggruppati per giorno.
    final conteggioAttivita = ref.watch(conteggioAttivitaGiornalieroProvider);

    // Gestisce il caso in cui non ci siano ancora attività registrate.
    if (conteggioAttivita.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text(
          'Nessuna attività registrata.\nInizia a prenderti cura delle tue piante!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Costruisce il grafico usando il pacchetto flutter_heatmap_calendar.
    return HeatMapCalendar(
      datasets: conteggioAttivita,
      colorMode: ColorMode.color,
      showColorTip: false,

      // Imposta i colori in base al numero di attività
      colorsets: const {
        1: Color.fromARGB(255, 160, 215, 162), // Verde chiaro per poche attività
        3: Color.fromARGB(255, 100, 190, 103),
        5: Color.fromARGB(255, 50, 160, 54),
        7: Color.fromARGB(255, 30, 130, 33),
        10: Color.fromARGB(255, 20, 100, 23), // Verde scuro per molte attività
      },
      // Mostra una SnackBar quando l'utente clicca su un giorno.
      onClick: (date) {
        final count = conteggioAttivita[date] ?? 0;
        final formattedDate = DateFormat.yMMMMd('it_IT').format(date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count attività registrate il $formattedDate'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
