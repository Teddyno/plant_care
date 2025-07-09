import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/AttivitaCuraModel.dart';
import '../models/repository/AttivitaCuraRepository.dart';

class AttivitaCuraState {
  final List<AttivitaCura> tutteLeAttivita;
  final bool isLoading;

  AttivitaCuraState({this.tutteLeAttivita = const [], this.isLoading = false});

  AttivitaCuraState copyWith({List<AttivitaCura>? tutteLeAttivita, bool? isLoading}) {
    return AttivitaCuraState(
      tutteLeAttivita: tutteLeAttivita ?? this.tutteLeAttivita,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AttivitaCuraNotifier extends StateNotifier<AttivitaCuraState> {
  final AttivitaCuraRepository _repository = AttivitaCuraRepository.instance;

  AttivitaCuraNotifier() : super(AttivitaCuraState()) {
    caricaAttivita();
  }

  Future<void> caricaAttivita() async {
    state = state.copyWith(isLoading: true);
    final attivita = await _repository.getTutteLeAttivita();
    state = state.copyWith(tutteLeAttivita: attivita, isLoading: false);
  }
}

final attivitaCuraProvider = StateNotifierProvider<AttivitaCuraNotifier, AttivitaCuraState>((ref) {
  return AttivitaCuraNotifier();
});