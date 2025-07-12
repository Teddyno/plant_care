class Categoria {
  final int? id;
  final String nome;

  Categoria({
    this.id,
    required this.nome,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nome: map['nome'],
    );
  }

  Categoria copyWith({
    int? id,
    String? nome,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
    );
  }
}