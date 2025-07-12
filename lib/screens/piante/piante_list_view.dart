import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/PiantaModel.dart';
import '../../providers/piante_provider.dart';
import '../../providers/categorie_provider.dart';
import '../../providers/specie_provider.dart';
import 'piante_detail_view.dart';

// Provider per mantenere lo stato del testo di ricerca.
final pianteSearchQueryProvider = StateProvider<String>((ref) => '');

/// Schermata che mostra la lista completa di tutte le piante, con funzionalità di ricerca.
class PianteListView extends ConsumerWidget {
  const PianteListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Ascolta" i provider necessari per la vista.
    final pianteState = ref.watch(pianteProvider);
    final searchQuery = ref.watch(pianteSearchQueryProvider);

    // Provider per le categorie e le specie, necessari per il filtraggio
    final categorieAsync = ref.watch(tutteLeCategorieProvider);
    final specieAsync = ref.watch(tutteLeSpecieProvider);

    // Costruisce la mappa delle specie e delle categorie per una ricerca efficiente
    final specieMap = { for (var s in specieAsync.asData?.value ?? []) s.id : s };
    final categorieMap = { for (var c in categorieAsync.asData?.value ?? []) c.id : c };

    // Filtra la lista delle piante in base alla query di ricerca
    final pianteFiltrate = pianteState.piante.where((pianta) {
      if (searchQuery.isEmpty) {
        return true; // Mostra tutte le piante se la ricerca è vuota
      }

      final query = searchQuery.toLowerCase();
      final nomePianta = pianta.nome.toLowerCase();
      final specie = specieMap[pianta.idSpecie];
      final nomeSpecie = specie?.nome.toLowerCase() ?? '';
      final categoria = specie != null ? categorieMap[specie.idCategoria] : null;
      final nomeCategoria = categoria?.nome.toLowerCase() ?? '';

      return nomePianta.contains(query) ||
          nomeSpecie.contains(query) ||
          nomeCategoria.contains(query);
    }).toList();

    // Logica per costruire il corpo della UI è ora direttamente nel build.
    Widget body;
    if (pianteState.isLoading && pianteFiltrate.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (pianteFiltrate.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Nessuna pianta trovata',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Prova a modificare i termini della ricerca o aggiungi una nuova pianta.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pianteProvider);
          ref.invalidate(tutteLeCategorieProvider);
          ref.invalidate(tutteLeSpecieProvider);
        },
        child: ListView.builder(
          itemCount: pianteFiltrate.length,
          itemBuilder: (context, index) {
            final pianta = pianteFiltrate[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: pianta.foto != null
                      ? Image.memory(
                    pianta.foto!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    'assets/icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.local_florist, size: 40, color: Colors.grey),
                  ),
                ),
                title: Text(pianta.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Acquistata il ${_formattaData(pianta.dataAcquisto)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PianteDetailView(pianta: pianta),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie piante'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cerca per nome, specie, categoria...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                ref.read(pianteSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: body,
    );
  }

  String _formattaData(DateTime data) {
    return '${data.day}/${data.month}/${data.year}';
  }
}
