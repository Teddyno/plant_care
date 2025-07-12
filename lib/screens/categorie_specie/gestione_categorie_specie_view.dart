import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/CategoriaModel.dart';
import '../../models/SpecieModel.dart';
import '../../providers/categorie_provider.dart';
import '../../providers/specie_provider.dart';

// Schermata per la gestione di Categorie e Specie
class GestioneCategorieSpecieView extends ConsumerStatefulWidget {
  const GestioneCategorieSpecieView({super.key});

  @override
  ConsumerState<GestioneCategorieSpecieView> createState() => _GestioneCategorieSpecieViewState();
}

class _GestioneCategorieSpecieViewState extends ConsumerState<GestioneCategorieSpecieView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Categorie'),
            Tab(text: 'Specie'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Passa i metodi come callback ai widget figli
          _CategorieListView(
            onEdit: (categoria) => _mostraDialogoCategoria(context, ref, categoria: categoria),
            onDelete: (id) => _confermaEliminazione(context, ref, 'categoria', id),
          ),
          _SpecieListView(
            onEdit: (specie) => _mostraDialogoSpecie(context, ref, specie: specie),
            onDelete: (id) => _confermaEliminazione(context, ref, 'specie', id),
            onAdd: (idCategoria) => _mostraDialogoSpecie(context, ref, idCategoria: idCategoria),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'gestione_categorie_specie_fab',
        onPressed: () {
          if (_tabController.index == 0) {
            _mostraDialogoCategoria(context, ref);
          } else {
            _mostraDialogoSpecie(context, ref);
          }
        },
        child: const Icon(Icons.add),
        tooltip: _tabController.index == 0 ? 'Aggiungi Categoria' : 'Aggiungi Specie',
      ),
    );
  }

  // --- DIALOGHI E FUNZIONI DI UTILITÀ---

  void _mostraDialogoCategoria(BuildContext context, WidgetRef ref, {Categoria? categoria}) {
    final isModifica = categoria != null;
    final controller = TextEditingController(text: categoria?.nome ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isModifica ? 'Modifica Categoria' : 'Nuova Categoria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome Categoria'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              final nome = controller.text;
              if (nome.isNotEmpty) {
                if (isModifica) {
                  ref.read(tutteLeCategorieProvider.notifier).aggiornaCategoria(categoria.copyWith(nome: nome));
                } else {
                  ref.read(tutteLeCategorieProvider.notifier).aggiungiCategoria(nome);
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  // Mostra un dialogo per aggiungere o modificare una specie.
  void _mostraDialogoSpecie(BuildContext context, WidgetRef ref, {int? idCategoria, Specie? specie}) {
    final isModifica = specie != null;
    final nomeController = TextEditingController(text: specie?.nome ?? '');
    final descController = TextEditingController(text: specie?.descrizione ?? '');
    final categorie = ref.read(tutteLeCategorieProvider).asData?.value ?? [];
    int? idCategoriaSelezionata = specie?.idCategoria ?? idCategoria ?? (categorie.isNotEmpty ? categorie.first.id : null);

    if (categorie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crea prima una categoria!')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(isModifica ? 'Modifica Specie' : 'Nuova Specie'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome Specie'), autofocus: true),
                      const SizedBox(height: 16),
                      TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrizione')),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: idCategoriaSelezionata,
                        items: categorie.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                        onChanged: (value) => setStateDialog(() => idCategoriaSelezionata = value),
                        decoration: const InputDecoration(labelText: 'Categoria'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
                  ElevatedButton(
                    onPressed: () {
                      final nome = nomeController.text;
                      if (nome.isNotEmpty && idCategoriaSelezionata != null) {
                        if (isModifica) {
                          ref.read(tutteLeSpecieProvider.notifier).aggiornaSpecie(specie.copyWith(nome: nome, descrizione: descController.text, idCategoria: idCategoriaSelezionata));
                        } else {
                          ref.read(tutteLeSpecieProvider.notifier).aggiungiSpecie(Specie(nome: nome, descrizione: descController.text, idCategoria: idCategoriaSelezionata!));
                        }
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Salva'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // Conferma l'eliminazione di una categoria o specie.
  void _confermaEliminazione(BuildContext context, WidgetRef ref, String tipo, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Sei sicuro di voler eliminare questa $tipo? L\'azione è irreversibile e potrebbe eliminare dati collegati (specie e piante).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              if (tipo == 'categoria') {
                ref.read(tutteLeCategorieProvider.notifier).eliminaCategoria(id);
              } else {
                ref.read(tutteLeSpecieProvider.notifier).eliminaSpecie(id);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

// Widget che mostra la lista delle Categorie.
class _CategorieListView extends ConsumerWidget {
  final Function(Categoria) onEdit;
  final Function(int) onDelete;

  const _CategorieListView({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorieState = ref.watch(tutteLeCategorieProvider);

    return categorieState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Errore: $err')),
      data: (categorie) {
        return RefreshIndicator(
          onRefresh: () => ref.read(tutteLeCategorieProvider.notifier).caricaCategorie(),
          child: ListView.builder(
            itemCount: categorie.length,
            itemBuilder: (context, index) {
              final categoria = categorie[index];
              return ListTile(
                title: Text(categoria.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => onEdit(categoria)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onDelete(categoria.id!)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Widget che mostra la lista delle Specie, raggruppate per categoria.
class _SpecieListView extends ConsumerWidget {
  final Function(Specie) onEdit;
  final Function(int) onDelete;
  final Function(int) onAdd;

  const _SpecieListView({required this.onEdit, required this.onDelete, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specieState = ref.watch(tutteLeSpecieProvider);
    final categorieState = ref.watch(tutteLeCategorieProvider);

    return specieState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Errore: $err')),
      data: (specie) {
        final categorie = categorieState.asData?.value ?? [];
        if (categorie.isEmpty) {
          return const Center(child: Text('Nessuna categoria trovata. Aggiungine una prima di creare una specie.'));
        }

        final specieRaggruppate = <int, List<Specie>>{};
        for (var s in specie) {
          specieRaggruppate.putIfAbsent(s.idCategoria, () => []).add(s);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(tutteLeCategorieProvider.notifier).caricaCategorie();
            await ref.read(tutteLeSpecieProvider.notifier).caricaSpecie();
          },
          child: ListView.builder(
            itemCount: categorie.length,
            itemBuilder: (context, index) {
              final categoria = categorie[index];
              final specieDellaCategoria = specieRaggruppate[categoria.id] ?? [];

              return ExpansionTile(
                title: Text(categoria.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  ...specieDellaCategoria.map((s) => ListTile(
                    title: Text(s.nome),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () => onEdit(s)),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () => onDelete(s.id!)),
                      ],
                    ),
                  )).toList(),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.green),
                    title: const Text('Aggiungi Specie a questa categoria', style: TextStyle(color: Colors.green)),
                    onTap: () => onAdd(categoria.id!),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
