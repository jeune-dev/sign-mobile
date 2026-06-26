import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_etats_logement.dart';
import '../../domain/usecases/get_etat_logement_detail.dart';
import '../../domain/usecases/creer_etat_logement.dart';
import '../../domain/usecases/signer_etat_logement.dart';
import '../../domain/usecases/telecharger_etat_logement.dart';
import 'etat_logement_event.dart';
import 'etat_logement_state.dart';

class EtatLogementBloc extends Bloc<EtatLogementEvent, EtatLogementState> {
  final GetEtatsLogement getEtatsLogement;
  final GetEtatLogementDetail getEtatLogementDetail;
  final CreerEtatLogement creerEtatLogement;
  final SignerEtatLogement signerEtatLogement;
  final TelechargerEtatLogement telechargerEtatLogement;

  EtatLogementBloc({
    required this.getEtatsLogement,
    required this.getEtatLogementDetail,
    required this.creerEtatLogement,
    required this.signerEtatLogement,
    required this.telechargerEtatLogement,
  }) : super(EtatLogementInitial()) {
    on<LoadEtatsLogement>(_onLoad);
    on<LoadEtatLogementDetail>(_onLoadDetail);
    on<CreerEtatLogementEvent>(_onCreer);
    on<SignerEtatLogementEvent>(_onSigner);
    on<TelechargerEtatLogementEvent>(_onTelecharger);
    on<ResetEtatLogementState>((_, emit) => emit(EtatLogementInitial()));
  }

  Future<void> _onLoad(
      LoadEtatsLogement event, Emitter<EtatLogementState> emit) async {
    emit(EtatLogementLoading());
    final result = await getEtatsLogement();
    result.fold(
      (failure) => emit(EtatLogementError(failure.errorMessage)),
      (etats) => emit(EtatsLogementLoaded(etats)),
    );
  }

  Future<void> _onLoadDetail(
      LoadEtatLogementDetail event, Emitter<EtatLogementState> emit) async {
    emit(EtatLogementLoading());
    final result = await getEtatLogementDetail(event.etatId);
    result.fold(
      (failure) => emit(EtatLogementError(failure.errorMessage)),
      (etat) => emit(EtatLogementDetailLoaded(etat)),
    );
  }

  Future<void> _onCreer(
      CreerEtatLogementEvent event, Emitter<EtatLogementState> emit) async {
    emit(EtatLogementLoading());
    final result = await creerEtatLogement(event.contratId, event.data);
    result.fold(
      (failure) => emit(EtatLogementError(failure.errorMessage)),
      (_) => emit(EtatLogementSuccess(message: 'État des lieux créé avec succès')),
    );
  }

  Future<void> _onSigner(
      SignerEtatLogementEvent event, Emitter<EtatLogementState> emit) async {
    emit(EtatLogementLoading());
    final result = await signerEtatLogement(event.etatId, event.signature);
    result.fold(
      (failure) => emit(EtatLogementError(failure.errorMessage)),
      (_) => emit(EtatLogementSuccess(message: 'État des lieux signé avec succès')),
    );
  }

  Future<void> _onTelecharger(
      TelechargerEtatLogementEvent event, Emitter<EtatLogementState> emit) async {
    emit(EtatLogementLoading());
    final result = await telechargerEtatLogement(event.etatId);
    result.fold(
      (failure) => emit(EtatLogementError(failure.errorMessage)),
      (bytes) => emit(EtatLogementBytes(
        bytes: bytes,
        etatId: event.etatId,
        titre: event.titre,
      )),
    );
  }
}
