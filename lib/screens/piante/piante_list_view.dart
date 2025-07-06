import 'package:flutter/material.dart';
import '../../models/PiantaModel.dart';
import '../../models/SpecieModel.dart';
import '../../models/CategoriaModel.dart';
import '../../models/repository/PianteRepository.dart';
import '../../models/repository/SpecieRepository.dart';
import '../../models/repository/CategorieRepository.dart';
import 'piante_detail_view.dart';

/// Schermata che mostra la lista di tutte le piante registrate nell'app.
/// Permette di visualizzare, eliminare e accedere ai dettagli di ogni pianta.
/// Include funzionalità di gestione degli stati di caricamento.
class PianteListView extends StatefulWidget {
  /// Costruttore della schermata lista piante
  const PianteListView({super.key});

  @override
  State<PianteListView> createState() => PianteListViewState();
}

/// Stato interno della schermata lista piante.
/// Gestisce il caricamento dei dati e le operazioni CRUD.
class PianteListViewState extends State<PianteListView> {
  final PianteRepository _pianteRepository = PianteRepository();
  final SpecieRepository _specieRepository = SpecieRepository.instance;
  final CategorieRepository _categorieRepository = CategorieRepository.instance;

  List<Pianta> _piante = [];
  List<Specie> _tutteLeSpecie = [];
  List<Categoria> _tutteLeCategorie = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String? _categoriaFiltro;
  String? _statoFiltro;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  /// Carica i dati dal database
  Future<void> _caricaDati() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carica i dati in parallelo per migliorare le performance
      final futures = await Future.wait([
        _pianteRepository.getTutteLePiante(),
        _specieRepository.getTutteLeSpecie(),
        _categorieRepository.getTutteLeCategorie(),
      ]);

      setState(() {
        _piante = futures[0] as List<Pianta>;
        _tutteLeSpecie = futures[1] as List<Specie>;
        _tutteLeCategorie = futures[2] as List<Categoria>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Errore nel caricamento dei dati: $e');
    }
  }

  /// Restituisce la specie corrispondente all'ID della specie
  Specie? _getSpecieById(int idSpecie) {
    try {
      return _tutteLeSpecie.firstWhere((specie) => specie.id == idSpecie);
    } catch (e) {
      return null;
    }
  }

  /// Restituisce la categoria corrispondente all'ID della categoria
  Categoria? _getCategoriaById(int idCategoria) {
    try {
      return _tutteLeCategorie.firstWhere((categoria) => categoria.id == idCategoria);
    } catch (e) {
      return null;
    }
  }

  List<String> get _categorie => _tutteLeSpecie
      .map((s) => _getCategoriaById(s.idCategoria)?.nome ?? 'Senza categoria')
      .toSet()
      .where((c) => c.isNotEmpty)
      .toList();

  List<String> get _stati => _piante
      .map((p) => p.stato)
      .toSet()
      .where((s) => s.isNotEmpty)
      .toList();

  List<Pianta> get _pianteFiltrate {
    return _piante.where((p) {
      final specie = _getSpecieById(p.idSpecie);
      final categoria = specie != null ? _getCategoriaById(specie.idCategoria) : null;
      final matchNome = p.nome.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchSpecie = specie?.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final matchCategoria = _categoriaFiltro == null || 
          (categoria?.nome == _categoriaFiltro);
      final matchStato = _statoFiltro == null || p.stato == _statoFiltro;
      return (matchNome || matchSpecie) && matchCategoria && matchStato;
    }).toList();
  }

  /// Elimina una pianta dalla collezione dopo conferma dell'utente.
  /// Mostra un dialog di conferma e, se confermato, elimina la pianta dal database.
  /// @param pianta La pianta da eliminare
  Future<void> _eliminaPianta(Pianta pianta) async {
    // Mostra dialog di conferma
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Elimina pianta'),
          ],
        ),
        content: Text('Sei sicuro di voler eliminare la pianta "${pianta.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    
    // Se l'utente ha confermato, elimina la pianta
    if (conferma == true) {
      try {
        await _pianteRepository.eliminaPianta(pianta.id!);
        setState(() {
          _piante.removeWhere((p) => p.id == pianta.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pianta "${pianta.nome}" eliminata.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'eliminazione: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  /// Formatta una data in formato leggibile
  String _formattaData(DateTime data) {
    return '${data.day}/${data.month}/${data.year}';
  }

  /// Restituisce l'icona e il colore appropriati per lo stato della pianta
  Widget _getStatoIcon(String stato) {
    IconData icon;
    Color color;
    
    switch (stato.toLowerCase()) {
      case 'sana':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'in crescita':
        icon = Icons.trending_up;
        color = Colors.blue;
        break;
      case 'malata':
        icon = Icons.sick;
        color = Colors.red;
        break;
      case 'in riposo':
        icon = Icons.bedtime;
        color = Colors.purple;
        break;
      case 'necessita cure':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'in fioritura':
        icon = Icons.local_florist;
        color = Colors.pink;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color, size: 16);
  }

  /// Costruisce l'interfaccia utente della schermata lista piante
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      // Header semplificato
      body: RefreshIndicator(
        onRefresh: _caricaDati,
        child: CustomScrollView(
          slivers: [
            // Header semplice con titolo
            SliverAppBar(
              title: const Text('Le mie piante'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cerca per nome o specie...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _categoriaFiltro,
                            hint: const Text('Categoria'),
                            isExpanded: true,
                            items: [null, ..._categorie].map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c ?? 'Tutte'),
                            )).toList(),
                            onChanged: (v) => setState(() => _categoriaFiltro = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _statoFiltro,
                            hint: const Text('Stato'),
                            isExpanded: true,
                            items: [null, ..._stati].map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s ?? 'Tutti'),
                            )).toList(),
                            onChanged: (v) => setState(() => _statoFiltro = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista delle piante
            _pianteFiltrate.isEmpty 
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nessuna pianta registrata',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aggiungi la tua prima pianta!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pianta = _pianteFiltrate[index];
                        final specie = _getSpecieById(pianta.idSpecie);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                key: ValueKey(pianta.id),
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PianteDetailView(pianta: pianta),
                                    ),
                                  );
                                  // Ricarica i dati quando torniamo dalla detail view
                                  _caricaDati();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Immagine della pianta
                                      Container(
                                        width: 60,
                                        height: 60,
                                        margin: const EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.grey[200],
                                        ),
                                        child: pianta.foto != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.memory(
                                                  pianta.foto!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(
                                                Icons.local_florist,
                                                color: Colors.grey[600],
                                                size: 30,
                                              ),
                                      ),
                                      
                                      // Informazioni pianta
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pianta.nome,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              specie?.nome ?? 'Specie sconosciuta',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _getStatoIcon(pianta.stato),
                                                const SizedBox(width: 4),
                                                Text(
                                                  pianta.stato,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Acquisita: ${_formattaData(pianta.dataAcquisto)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Pulsanti azione
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red[400],
                                            ),
                                            onPressed: () => _eliminaPianta(pianta),
                                            tooltip: 'Elimina',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 40,
                                              minHeight: 40,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.chevron_right,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            onPressed: () async {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => PianteDetailView(pianta: pianta),
                                                ),
                                              );
                                              // Ricarica i dati quando torniamo dalla detail view
                                              _caricaDati();
                                            },
                                            tooltip: 'Dettagli',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 40,
                                              minHeight: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _pianteFiltrate.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
} 