class AttivitaCura {
    final int? id;
    final int idPianta;
    final String tipoAttivita; // "innaffiatura", "potatura", "rinvaso"
    final DateTime data;

    AttivitaCura({
      this.id, 
      required this.idPianta, 
      required this.tipoAttivita, 
      required this.data}
      );

    Map<String, dynamic> toMap() => {
      'id': id, 
      'idPianta': idPianta, 
      'tipoAttivita': tipoAttivita, 
      'data': data.toIso8601String()
      };
      
    factory AttivitaCura.fromMap(Map<String, dynamic> map) => AttivitaCura(
      id: map['id'],
      idPianta: map['idPianta'], 
      tipoAttivita: map['tipoAttivita'], 
      data: DateTime.parse(map['data'])
      );
}