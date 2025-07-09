import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/SpecieModel.dart';
import '../models/repository/SpecieRepository.dart';

// Questo provider carica tutte le specie una volta e le mette a disposizione.
final tutteLeSpecieProvider = FutureProvider<List<Specie>>((ref) async {
  final repository = SpecieRepository.instance;
  return repository.getTutteLeSpecie();
});