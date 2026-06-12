import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_contrats.dart';
import '../../domain/usecases/get_autre_contrat_detail.dart';
import '../../domain/usecases/creer_autre_contrat.dart';
import '../../domain/usecases/signer_autre_contrat.dart';
import '../../domain/usecases/telecharger_autre_contrat.dart';
import 'autres_contrats_event.dart';
import 'autres_contrats_state.dart';

class AutresContratsBloc extends Bloc<AutresContratsEvent, AutresContratsState> {
  final GetContrats getContrats;
  final GetAutreContratDetail getDetail;
  final CreerAutreContrat creerContrat;
  final SignerAutreContrat signerContrat;
  final TelechargerAutreContrat telechargerContrat;

  AutresContratsBloc({
    required this.getContrats,
    required this.getDetail,
    required this.creerContrat,
    required this.signerContrat,
    required this.telechargerContrat,
  }) : super(AutresContratsInitial()) {
    on<LoadContrats>(_onLoadContrats);
    on<LoadDetail>(_onLoadDetail);
    on<CreerContrat>(_onCreerContrat);
    on<SignerContrat>(_onSignerContrat);
    on<TelechargerContrat>(_onTelechargerContrat);
    on<ResetState>((_, emit) => emit(AutresContratsInitial()));
  }

  Future<void> _onLoadContrats(LoadContrats event, Emitter<AutresContratsState> emit) async {
    emit(AutresContratsLoading());
    final result = await getContrats(event.type);
    result.fold(
      (failure) => emit(AutresContratsError(failure.errorMessage)),
      (contrats) => emit(AutresContratsListLoaded(type: event.type, contrats: contrats)),
    );
  }

  Future<void> _onLoadDetail(LoadDetail event, Emitter<AutresContratsState> emit) async {
    emit(AutresContratsLoading());
    final result = await getDetail(event.type, event.id);
    result.fold(
      (failure) => emit(AutresContratsError(failure.errorMessage)),
      (contrat) => emit(AutresContratsDetailLoaded(contrat)),
    );
  }

  Future<void> _onCreerContrat(CreerContrat event, Emitter<AutresContratsState> emit) async {
    emit(AutresContratsLoading());
    final result = await creerContrat(event.type, event.body);
    result.fold(
      (failure) => emit(AutresContratsError(failure.errorMessage)),
      (_) => emit(AutresContratsSuccess(message: 'Contrat créé avec succès')),
    );
  }

  Future<void> _onSignerContrat(SignerContrat event, Emitter<AutresContratsState> emit) async {
    emit(AutresContratsLoading());
    final result = await signerContrat(event.type, event.id, event.signature);
    result.fold(
      (failure) => emit(AutresContratsError(failure.errorMessage)),
      (_) => emit(AutresContratsSuccess(message: 'Contrat signé avec succès')),
    );
  }

  Future<void> _onTelechargerContrat(TelechargerContrat event, Emitter<AutresContratsState> emit) async {
    emit(AutresContratsLoading());
    final result = await telechargerContrat(event.type, event.id);
    result.fold(
      (failure) => emit(AutresContratsError(failure.errorMessage)),
      (bytes) => emit(AutresContratsBytes(bytes: bytes, id: event.id, titre: event.titre)),
    );
  }
}
