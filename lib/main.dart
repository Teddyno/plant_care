/*
 * PLANTCARE - APPLICAZIONE DI GESTIONE PIANTE
 * 
 * Questo file contiene il punto di ingresso principale dell'applicazione.
 * PlantCare è un'app per la gestione di collezioni di piante domestiche,
 * che permette di:
 * - Registrare e catalogare piante
 * - Gestire attività di cura (innaffiatura, potatura, ecc.)
 * - Visualizzare statistiche e analisi della collezione
 * - Ricevere promemoria per le attività di manutenzione
 * 
 * FUNZIONALITÀ PRINCIPALI:
 * - Dashboard con panoramica della collezione
 * - Lista completa delle piante con dettagli
 * - Analisi e statistiche della collezione
 * - Sistema di promemoria per attività di cura
 * - Interfaccia moderna e intuitiva
 */

import 'package:flutter/material.dart';
import 'screens/main/main_view.dart';
import 'themes/themes.dart';
import 'services/db/DatabaseHelper.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Funzione principale dell'applicazione PlantCare.
/// 
/// Questa funzione viene chiamata automaticamente quando l'app viene lanciata
/// dal sistema operativo. È responsabile di:
/// - Inizializzare il framework Flutter
/// - Configurare le impostazioni globali
/// - Avviare l'interfaccia utente principale

void main() async {
  // Assicura che il framework Flutter sia completamente inizializzato
  // prima di eseguire qualsiasi interazione con il sistema operativo
  // o plugin nativi. Questo è necessario per:
  // - Gestione delle risorse del dispositivo
  // - Comunicazione con plugin nativi
  // - Inizializzazione di servizi di sistema
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il database con dati di default se necessario
  try {
    print('Inizializzazione del database...');
    await DatabaseHelper.instance.inizializzaSeVuoto();
    print('Database inizializzato con successo');
  } catch (e) {
    print('Errore durante l\'inizializzazione del database: $e');
    // Non blocchiamo l'avvio dell'app se il database fallisce
    // L'app può continuare a funzionare e riprovare più tardi
  }

  // Avvia l'applicazione passando il widget principale
  // MyApp è il widget root che definisce la struttura base dell'app
  runApp(const MyApp());
}

/// Widget principale dell'applicazione PlantCare.
/// 
/// Questo widget rappresenta la radice dell'interfaccia utente e definisce:
/// - Il tema globale dell'applicazione (colori, stili, font)
/// - La schermata iniziale da mostrare all'utente
/// - Le configurazioni base dell'app
/// 
/// CARATTERISTICHE:
/// - Tema personalizzato verde floreale
/// - Schermata iniziale: MainView (dashboard principale)
/// - Supporto per Material Design
/// - Configurazione responsive per diversi dispositivi
class MyApp extends StatelessWidget {

  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantCare',           // Nome dell'app mostrato nel sistema
      theme: appTheme,                 // Tema personalizzato verde floreale
      home: const MainView(),          // Schermata iniziale dell'app
    );
  }
}
