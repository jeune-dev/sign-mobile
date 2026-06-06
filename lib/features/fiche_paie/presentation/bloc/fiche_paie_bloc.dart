import 'package:flutter_bloc/flutter_bloc.dart';
import 'fiche_paie_event.dart';
import 'fiche_paie_state.dart';
import '../../domain/usecases/cree_fiche_paie.dart';

class FichePaieBloc extends Bloc<FichePaieEvent, FichePaieState> {
  final CreerFichePaie creerFichePaie;

  FichePaieBloc(this.creerFichePaie) : super(FichePaieInitial()) {
    on<CreerFichePaieEvent>(_onCreerFichePaie);
  }

  Future<void> _onCreerFichePaie(
      CreerFichePaieEvent event,
      Emitter<FichePaieState> emit,
      ) async {
    emit(FichePaieLoading());

    try {
      final result = await creerFichePaie(event.fiche);
      emit(FichePaieSuccess(result));
    } catch (e) {
      emit(FichePaieError(e.toString()));
    }
  }
}