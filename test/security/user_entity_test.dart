import 'package:flutter_test/flutter_test.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/auth/data/models/user_model.dart';

/// VULN-L03 : Tests de sécurité — Entité User
void main() {
  group('User Entity — Sécurité des données (VULN-C03)', () {
    test('Le modèle User ne contient pas de champ mot_de_passe', () {
      final user = UserModel(
        id: '1',
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean@example.com',
        adresse: '123 Rue',
        telephone: '0600000000',
        carte_identite_national_num: 'ABC123',
        role: 'Professionnel',
      );

      // Vérifie que toJson() ne contient pas le mot de passe
      final json = user.toJson();
      expect(json.containsKey('mot_de_passe'), false,
          reason: 'Le mot de passe ne doit JAMAIS être sérialisé');
    });

    test('UserModel.fromJson ignore le mot_de_passe reçu du serveur', () {
      final json = {
        'id': '1',
        'nom': 'Dupont',
        'prenom': 'Jean',
        'email': 'jean@example.com',
        'mot_de_passe': 'SECRET_HASH', // Envoyé par le serveur (ne doit pas être stocké)
        'adresse': '123 Rue',
        'telephone': '0600000000',
        'carte_identite_national_num': 'ABC123',
        'role': 'Professionnel',
      };

      final user = UserModel.fromJson(json);
      final serialized = user.toJson();

      expect(serialized.containsKey('mot_de_passe'), false,
          reason: 'mot_de_passe ne doit pas être dans toJson()');
    });

    test('AuthResponseModel.toJson redacte le token', () {
      final response = AuthResponseModel(
        token: 'super_secret_jwt_token',
        user: UserModel(
          id: '1', nom: 'D', prenom: 'J', email: 'j@e.com',
          adresse: '', telephone: '', carte_identite_national_num: '', role: '',
        ),
      );

      final json = response.toJson();
      expect(json['token'], equals('[REDACTED]'),
          reason: 'Le token ne doit pas être sérialisé en clair');
    });

    test('User.toJson ne révèle pas la signature en clair', () {
      final user = User(
        id: '1', nom: 'D', prenom: 'J', email: 'j@e.com',
        adresse: '', telephone: '', carte_identite_national_num: '', role: '',
        signature: 'data:image/png;base64,iVBORw0KGgo=',
      );

      final json = user.toJson();
      // La signature ne doit pas contenir le base64 complet
      expect(json['signature'], isNot(contains('iVBORw0KGgo=')),
          reason: 'La signature base64 ne doit pas être exposée dans les logs');
    });
  });
}
