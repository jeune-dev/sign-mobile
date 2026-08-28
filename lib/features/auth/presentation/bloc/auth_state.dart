import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Le compte visé date d'avant la refonte : le backend réclame son mot de
/// passe. L'écran de connexion affiche alors le champ correspondant, au lieu
/// d'un message d'erreur.
class AuthMotDePasseRequis extends AuthState {
  final String message;

  const AuthMotDePasseRequis({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Le compte existe mais son adresse n'a pas été confirmée : l'écran de
/// connexion doit envoyer vers la saisie du code.
class AuthVerificationEmailRequise extends AuthState {
  final String message;
  final String email;

  const AuthVerificationEmailRequise({required this.message, required this.email});

  @override
  List<Object?> get props => [message, email];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordSuccess extends AuthState {
  final String message;
  const ForgotPasswordSuccess({required this.message});
  @override
  List<Object?> get props => [message];
}

class ResetPasswordSuccess extends AuthState {}

class AuthUploadProgress extends AuthState {
  final double progress; // 0.0 → 1.0

  const AuthUploadProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}
