import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetAuthState>((_, emit) => emit(AuthInitial()));
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await loginUser(event.identifiant, event.mot_de_passe);

    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.errorMessage)),
      (user) async {
        emit(AuthSuccess(user: user));
        // Le token FCM est uploadé dans FcmService.init() appelé depuis la home page,
        // après que les permissions ont été demandées et accordées.
      },
    );
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await registerUser(
      onSendProgress: (sent, total) {
        if (total > 0) emit(AuthUploadProgress(sent / total));
      },
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      mot_de_passe: event.mot_de_passe,
      adresse: event.adresse,
      telephone: event.telephone,
      carte_identite_national_num: event.carte_identite_national_num,
      role: event.role,
      typeDocumentIdentite: event.typeDocumentIdentite,
      documentIdentite: event.documentIdentite,
      photoProfil: event.photoProfil,
      logo: event.logo,
      rc: event.rc,
      ninea: event.ninea,
      signature: event.signature,
      nomEntreprise: event.nomEntreprise,
      adresseEntreprise: event.adresseEntreprise,
      telephoneEntreprise: event.telephoneEntreprise,
      emailEntreprise: event.emailEntreprise,
    );

    result.fold(
          (failure) => emit(AuthFailure(message: failure.errorMessage)),
          (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.forgotPassword(event.email);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.errorMessage)),
      (_) => emit(const ForgotPasswordSuccess(
          message: 'Un code de réinitialisation a été envoyé à votre adresse email.')),
    );
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.resetPassword(
        event.email, event.otpRecu, event.newPassword);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.errorMessage)),
      (_) => emit(ResetPasswordSuccess()),
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final storage = sl<FlutterSecureStorage>();

      // Révoquer le refresh token côté backend (best-effort — erreur réseau ignorée)
      await revokeRefreshToken(sl());

      // Effacer access token + refresh token du stockage sécurisé
      await sl<TokenService>().clearToken();
      await storage.delete(key: 'user_id');
      await storage.delete(key: 'user_role'); // Évite navigation FCM incorrecte si 2 users partagent le device

      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: 'Erreur lors de la déconnexion : $e'));
    }
  }
}
