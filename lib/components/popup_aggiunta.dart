import 'package:flutter/material.dart';
import '../models/PiantaModel.dart';
import '../models/repository/PianteRepository.dart';

// Importiamo il nostro nuovo form riutilizzabile
import 'PiantaForm.dart';

/// Un popup che ospita il form per aggiungere una nuova pianta alla collezione.
/// Ora agisce come un semplice "contenitore" per PiantaForm.
class PopupAggiunta extends StatefulWidget {
  const PopupAggiunta({super.key});

  @override
  State<PopupAggiunta> createState() => _PopupAggiuntaState();
}

class _PopupAggiuntaState extends State<PopupAggiunta> {
  // L'unica dipendenza di cui ha bisogno questo widget è il repository
  // per eseguire l'azione di salvataggio.
  final PianteRepository _pianteRepository = PianteRepository();
  bool _isSaving = false;

  /// Definiamo la logica di salvataggio specifica per l'AGGIUNTA.
  /// Questa funzione verrà passata come callback al PiantaForm.
  Future<void> _handleSave(Pianta piantaDaAggiungere) async {
    if (_isSaving) return; // Previene doppi click

    setState(() {
      _isSaving = true;
    });

    try {
      // Usa il repository per aggiungere la nuova pianta
      await _pianteRepository.aggiungiPianta(piantaDaAggiungere);

      if (mounted) {
        // Mostra messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pianta "${piantaDaAggiungere.nome}" aggiunta con successo!'),
            backgroundColor: Colors.green,
          ),
        );
        // Chiude il popup e restituisce 'true' per indicare che la lista deve essere aggiornata.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // Mostra messaggio di errore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Il popup ora è una semplice Scaffold che contiene il PiantaForm.
    // L'intera UI del form e la sua logica interna sono incapsulate.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi Nuova Pianta'),
        automaticallyImplyLeading: false, // Non mostra il tasto "indietro" di default
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
            tooltip: 'Chiudi',
          ),
        ],
      ),
      body: _isSaving
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Salvataggio in corso...'),
          ],
        ),
      )
          : PiantaForm(
        // Non passiamo 'piantaIniziale', quindi PiantaForm sa
        // di essere in modalità "Aggiunta".
        onSave: _handleSave,
      ),
    );
  }
}