/*
 * MAIN VIEW - SCHERMATA PRINCIPALE DELL'APPLICAZIONE
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../piante/piante_dashboard_view.dart';
import '../piante/piante_list_view.dart';
import '../analisi/analisi_view.dart';
import '../../components/popup_aggiunta.dart';

/// Schermata principale dell'applicazione che gestisce la navigazione.
/// è un ConsumerStatefulWidget per interagire con i provider.
class MainView extends ConsumerStatefulWidget { 
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

/// Stato interno della schermata principale.
class _MainViewState extends ConsumerState<MainView> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const PianteDashboardView(),
      const PianteListView(),
      const AnalisiView(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2
          ? AppBar(
        title: const Text('Analisi'),
      )
          : null,

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
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
        ],
      ),

      floatingActionButton: _selectedIndex == 0
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