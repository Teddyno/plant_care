class Specie {
  final int? id;
  final String nome;
  final String? descrizione;
  final int idCategoria;

  Specie({
    this.id,
    required this.nome,
    this.descrizione,
    required this.idCategoria,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descrizione': descrizione,
      'idCategoria': idCategoria,
    };
  }

  factory Specie.fromMap(Map<String, dynamic> map) {
    return Specie(
      id: map['id'],
      nome: map['nome'],
      descrizione: map['descrizione'],
      idCategoria: map['idCategoria'],
    );
  }

  Specie copyWith({
    int? id,
    String? nome,
    String? descrizione,
    int? idCategoria,
  }) {
    return Specie(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descrizione: descrizione ?? this.descrizione,
      idCategoria: idCategoria ?? this.idCategoria,
    );
  }
}
