import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../piante/piante_dashboard_view.dart';
import '../piante/piante_list_view.dart';
import '../analisi/analisi_view.dart';
import '../categorie_specie/gestione_categorie_specie_view.dart';
import '../../components/popup_aggiunta.dart';

/// Provider per gestire lo stato dell'indice selezionato nella BottomNavBar.
final mainViewProvider = StateProvider<int>((ref) => 0);

/// Schermata principale dell'applicazione che gestisce la navigazione.
/// Ora è un ConsumerWidget per una gestione dello stato più pulita.
class MainView extends ConsumerWidget {
  const MainView({super.key});

  // Lista delle pagine navigabili
  static const List<Widget> _pages = [
    PianteDashboardView(),
    PianteListView(),
    AnalisiView(),
    GestioneCategorieSpecieView()
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Ascolta" il provider per ottenere e aggiornare l'indice corrente
    final selectedIndex = ref.watch(mainViewProvider);

    return Scaffold(
      appBar: selectedIndex == 2
          ? AppBar(
        title: const Text('Analisi'),
      )
          : null,

      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        // Aggiorna lo stato del provider quando un'icona viene toccata
        onTap: (index) => ref.read(mainViewProvider.notifier).state = index,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Piante',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analisi',
          ),
          // 3. Aggiunta la nuova voce per la gestione
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: 'Gestione',
          ),
        ],
      ),

      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return const PopupAggiunta();
            },
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
