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
    return Column(
      children: [
        const SizedBox(height: 50), // Spessore per far partire lo Scaffold più in basso
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 0,
                  right: 0,
                  top: 0,
                ),
                child: PiantaForm(
                  onSave: (piantaDaAggiungere) {
                    ref.read(pianteProvider.notifier).aggiungiPianta(piantaDaAggiungere);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}