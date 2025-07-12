import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main/main_view.dart';
import 'themes/themes.dart';
import 'services/db/DatabaseHelper.dart';

void main() async {
  // Assicura che i widget Flutter siano pronti prima di eseguire altro codice
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza la formattazione per la lingua italiana
  await initializeDateFormatting('it_IT', null);

  // Inizializza il database con dati di default se necessario
  try {
    print('Inizializzazione del database...');
    await DatabaseHelper.instance.database; // Questo triggera _initDB e _onCreate
    print('Database inizializzato con successo');
  } catch (e) {
    print('Errore durante l\'inizializzazione del database: $e');
  }

  // Avvia l'applicazione avvolgendo MyApp con ProviderScope.
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
    return MaterialApp(
      title: 'PlantCare',
      theme: appTheme,
      home: const MainView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
