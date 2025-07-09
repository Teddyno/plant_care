import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/CategoriaModel.dart';
import '../models/repository/CategorieRepository.dart';

final tutteLeCategorieProvider = FutureProvider<List<Categoria>>((ref) async {
  final repository = CategorieRepository.instance;
  return repository.getTutteLeCategorie();
});