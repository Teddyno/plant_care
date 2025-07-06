import 'PiantaModel.dart';

enum TipoAttivita { innaffiatura, potatura, rinvaso }

class Promemoria {
  final Pianta pianta;
  final TipoAttivita attivita;
  final DateTime dataScadenza;
  
  Promemoria({
    required this.pianta, 
    required this.attivita, 
    required this.dataScadenza}
    );
}