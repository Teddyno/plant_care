import 'dart:typed_data'; // Necessario per Uint8List (BLOB)

// La PK `id` è nullabile (`int?`) perché un oggetto Categoria
// appena creato in Dart (e non ancora salvato nel DB) non ha ancora un ID.
// L'ID viene assegnato dal DB solo al momento dell'inserimento.

class Pianta {
  final int? id; // Nullabile per lo stesso motivo della Categoria
  final String nome;
  final DateTime dataAcquisto;
  final Uint8List? foto; // Utilizziamo Uint8List per il tipo BLOB
  final int frequenzaInnaffiatura;
  final int frequenzaPotatura;
  final int frequenzaRinvaso;
  final String? note;
  final String stato;
  final int idSpecie;

  Pianta({
    this.id,
    required this.nome,
    required this.dataAcquisto,
    this.foto,
    required this.frequenzaInnaffiatura,
    required this.frequenzaPotatura,
    required this.frequenzaRinvaso,
    this.note,
    required this.stato,
    required this.idSpecie,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dataAcquisto': dataAcquisto.toIso8601String(),
      'foto': foto,
      'frequenzaInnaffiatura': frequenzaInnaffiatura,
      'frequenzaPotatura': frequenzaPotatura,
      'frequenzaRinvaso': frequenzaRinvaso,
      'note': note,
      'stato': stato,
      'idSpecie': idSpecie,
    };
  }

  factory Pianta.fromMap(Map<String, dynamic> map) {
    return Pianta(
      id: map['id'],
      nome: map['nome'],
      dataAcquisto: DateTime.parse(map['dataAcquisto']),
      foto: map['foto'] as Uint8List?,
      frequenzaInnaffiatura: map['frequenzaInnaffiatura'],
      frequenzaPotatura: map['frequenzaPotatura'],
      frequenzaRinvaso: map['frequenzaRinvaso'],
      note: map['note'],
      stato: map['stato'],
      idSpecie: map['idSpecie'],
    );
  }
}
