/*
 * MAIN VIEW - SCHERMATA PRINCIPALE DELL'APPLICAZIONE
 * 
 * Questo file contiene la struttura principale dell'app FloraManager.
 * Implementa la navigazione tra le diverse sezioni dell'applicazione
 * tramite una barra di navigazione inferiore (BottomNavigationBar).
 * 
 * STRUTTURA DELL'APP:
 * - Tab 0: Dashboard (Home) - Panoramica generale della collezione
 * - Tab 1: Lista Piante - Vista completa di tutte le piante
 * - Tab 2: Analisi - Statistiche e grafici della collezione
 */

import 'package:flutter/material.dart';
import '../piante/piante_dashboard_view.dart';
import '../piante/piante_list_view.dart';
import '../analisi/analisi_view.dart';
import '../../components/popup_aggiunta.dart';

/// Schermata principale dell'applicazione che gestisce la navigazione tra le diverse sezioni.
/// 
class MainView extends StatefulWidget {
  /// Costruttore della schermata principale
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

/// Stato interno della schermata principale.
/// 
/// Gestisce:
/// - L'indice della tab attualmente selezionata
/// - La navigazione tra le diverse sezioni
class _MainViewState extends State<MainView> {
  /// Indice della tab attualmente selezionata nella barra di navigazione.
  int _selectedIndex = 0;

  /// Lista delle pagine principali mostrate nell'app.
  /// 
  /// Ogni elemento corrisponde a una tab della barra di navigazione.
  late List<Widget> _pages;

  /// Inizializza le pagine.
  /// 
  /// Questo metodo viene chiamato una sola volta quando il widget
  /// viene creato. Inizializza la lista delle pagine.
  @override
  void initState() {
    super.initState();
    _pages = [
      const PianteDashboardView(), // Dashboard principale
      const PianteListView(),      // Lista di tutte le piante
      const AnalisiView(),         // Analisi e statistiche
    ];
  }

  /// Gestisce il cambio di tab nella barra di navigazione.
  /// 
  /// Questo metodo viene chiamato quando l'utente tocca una tab
  /// diversa nella barra di navigazione inferiore. Aggiorna l'indice
  /// selezionato e ricostruisce l'interfaccia per mostrare la nuova
  /// schermata.
  /// 
  /// - index: Indice della nuova tab selezionata (0-2)
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Costruisce l'interfaccia utente della schermata principale.
  /// 
  /// STRUTTURA:
  /// - AppBar: Mostrato solo per la sezione Analisi
  /// - Body: IndexedStack con le schermate principali
  /// - BottomNavigationBar: Navigazione tra tab
  /// - FloatingActionButton: Aggiunta nuove piante
  /// 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superiore (mostrata solo per la sezione Analisi)
      appBar: _selectedIndex == 2
          ? AppBar(
              title: const Text('Analisi'),
            )
          : null,
      
      // Corpo principale con navigazione tra le pagine
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages.map((page) => 
          // Wrapper per gestire errori nelle pagine
          ErrorBoundary(
            child: page,
          ),
        ).toList(),
      ),
      
      // Barra di navigazione inferiore
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        enableFeedback: false,
        mouseCursor: SystemMouseCursors.basic,
        selectedIconTheme: const IconThemeData(opacity: 1),
        unselectedIconTheme: const IconThemeData(opacity: 1),
        items: const [
          // Tab Dashboard (Home)
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // Tab Lista Piante
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Piante',
          ),
          // Tab Analisi
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analisi',
          ),
        ],
      ),
      
      // Pulsante flottante per aggiungere nuove piante (solo nella dashboard)
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              // Adatta il padding in base all'orientamento del dispositivo
              padding: MediaQuery.of(context).orientation == Orientation.portrait
                  ? const EdgeInsets.only(bottom: 30.0)
                  : EdgeInsets.zero,
              child: FloatingActionButton(
                onPressed: () async {
                  // Mostra il popup di aggiunta pianta
                  await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return const PopupAggiunta();
                    },
                  );
                },
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }
}

/// Widget per gestire gli errori nelle pagine figlie.
/// 
/// Questo widget wrapper cattura eventuali errori che si verificano
/// nelle schermate figlie e previene il crash dell'applicazione.
/// 
class ErrorBoundary extends StatelessWidget {
  /// Widget figlio da wrappare.
  final Widget child;
  
  /// Costruttore dell'ErrorBoundary.
  /// - child: Widget da wrappare per la gestione degli errori
  const ErrorBoundary({super.key, required this.child});
  
  /// Costruisce l'ErrorBoundary.
  @override
  Widget build(BuildContext context) {
    return child;
  }
}
