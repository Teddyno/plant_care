import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/piante_provider.dart';
import '../../models/PiantaModel.dart';
import 'piante_detail_view.dart';

/// Schermata che mostra la lista completa di tutte le piante.
/// Questo widget "ascolta" i cambiamenti dal pianteProvider e si
/// aggiorna automaticamente.
class PianteListView extends ConsumerWidget {
  const PianteListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usiamo ref.watch per "osservare" lo stato del nostro provider.
    // Ogni volta che lo stato in PianteNotifier cambia, questo widget si ricostruisce.
    final pianteState = ref.watch(pianteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie piante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Chiamiamo l'azione di ricarica sul notifier.
              ref.read(pianteProvider.notifier).caricaPiante();
            },
            tooltip: 'Aggiorna lista',
          )
        ],
      ),
      body: _buildBody(context, ref, pianteState),
    );
  }

  /// Costruisce il corpo della schermata in base allo stato attuale.
  Widget _buildBody(BuildContext context, WidgetRef ref, PianteState state) {
    // Se sta caricando, mostra un indicatore di progresso
    if (state.isLoading && state.piante.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Se la lista è vuota, mostra un messaggio amichevole
    if (state.piante.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.park_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Nessuna pianta nella tua collezione',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tocca il pulsante "+" nella home per aggiungerne una!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Se ci sono dati, mostra la lista
    return RefreshIndicator(
      onRefresh: () => ref.read(pianteProvider.notifier).caricaPiante(),
      child: ListView.builder(
        itemCount: state.piante.length,
        itemBuilder: (context, index) {
          final pianta = state.piante[index];
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

  String _formattaData(DateTime data) {
    return '${data.day}/${data.month}/${data.year}';
  }
}