import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/PiantaModel.dart';
import '../providers/piante_provider.dart';
import 'PiantaForm.dart';

/// Popup che ospita il form per aggiungere una pianta.
class PopupAggiunta extends ConsumerWidget { 
  const PopupAggiunta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi Nuova Pianta'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PiantaForm(
        onSave: (piantaDaAggiungere) {
          // Usa ref.read per chiamare il metodo aggiungiPianta sul notifier.
          // Questo aggiornerà lo stato e tutte le schermate in ascolto (es. PianteListView)
          // si aggiorneranno automaticamente.
          ref.read(pianteProvider.notifier).aggiungiPianta(piantaDaAggiungere);

          // Chiude il popup
          Navigator.of(context).pop();
        },
      ),
    );
  }
}