import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/modifier_info_personnelles.dart';
import '../../domain/usecases/change_password.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetMe getMe;
  final ModifierInfoPersonnelles modifierInfoPersonnelles;
  final ChangePassword changePassword;

  AccountBloc({
    required this.getMe,
    required this.modifierInfoPersonnelles,
    required this.changePassword,
  }) : super(AccountInitial()) {
    on<LoadMe>(_onLoadMe);
    on<ModifierInfoPersonnellesEvent>(_onModifierInfo);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ResetAccountState>((_, emit) => emit(AccountInitial()));
  }

  Future<void> _onLoadMe(LoadMe event, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    final result = await getMe();
    result.fold(
      (failure) => emit(AccountError(failure.errorMessage)),
      (user) => emit(AccountLoaded(user)),
    );
  }

  Future<void> _onModifierInfo(
    ModifierInfoPersonnellesEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    final result = await modifierInfoPersonnelles(
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      telephone: event.telephone,
      adresse: event.adresse,
      carteIdentiteNationalNum: event.carteIdentiteNationalNum,
      rc: event.rc,
      ninea: event.ninea,
      nomEntreprise: event.nomEntreprise,
      adresseEntreprise: event.adresseEntreprise,
      telephoneEntreprise: event.telephoneEntreprise,
      emailEntreprise: event.emailEntreprise,
      photoProfilPath: event.photoProfilPath,
      logoPath: event.logoPath,
      signaturePath: event.signaturePath,
    );
    result.fold(
      (failure) => emit(AccountError(failure.errorMessage)),
      (user) => emit(AccountSuccess(user: user, message: 'Profil mis à jour avec succès')),
    );
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    final result = await changePassword(
      oldPassword: event.oldPassword,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(AccountError(failure.errorMessage)),
      (_) => emit(PasswordChanged(message: 'Mot de passe modifié avec succès')),
    );
  }
}
