import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main/main_view.dart';
import 'themes/themes.dart';
import 'services/db/DatabaseHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il database con dati di default se necessario
  try {
    print('Inizializzazione del database...');
    await DatabaseHelper.instance.inizializzaSeVuoto();
    print('Database inizializzato con successo');
  } catch (e) {
    print('Errore durante l\'inizializzazione del database: $e');
  }

  // Avvia l'applicazione avvolgendo MyApp con ProviderScope.
  // Questo è il passaggio fondamentale che risolve l'errore.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Widget principale dell'applicazione PlantCare.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // La MaterialApp rimane identica, ma ora si trova DENTRO un ProviderScope.
    return MaterialApp(
      title: 'PlantCare',
      theme: appTheme,
      home: const MainView(),
      debugShowCheckedModeBanner: false,
    );
  }
}