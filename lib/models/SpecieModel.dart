class Specie {
  final int? id; // Nullabile per lo stesso motivo della Categoria
  final String nome;
  final String? descrizione;
  final int idCategoria;

  Specie({
    this.id,
    required this.nome,
    this.descrizione,
    required this.idCategoria,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'descrizione': descrizione,
        'idCategoria': idCategoria,
      };

  factory Specie.fromMap(Map<String, dynamic> map) => Specie(
        id: map['id'],
        nome: map['nome'],
        descrizione: map['descrizione'],
        idCategoria: map['idCategoria'],
      );
}
