class Categoria {
  final int? id;
  final String nome;

  Categoria({this.id, required this.nome});

  Map<String, dynamic> toMap() => {'id': id, 'nome': nome};
  
  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
    id: map['id'], 
    nome: map['nome']
  );
}
