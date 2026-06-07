import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sign_application/core/services/token_service.dart';

@GenerateMocks([FlutterSecureStorage])
import 'token_service_test.mocks.dart';

/// VULN-L03 : Tests de sécurité — TokenService
void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenService tokenService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenService = TokenService(secureStorage: mockStorage);
  });

  group('TokenService — Sécurité', () {
    // JWT valide généré avec exp = maintenant + 1 heure (pour les tests)
    // eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIxMjMiLCJleHAiOjk5OTk5OTk5OTl9.xxx
    const validToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJ1c2VySWQiOiIxMjMiLCJleHAiOjk5OTk5OTk5OTl9'
        '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    // JWT expiré (exp = 1 = 1970-01-01)
    const expiredToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJ1c2VySWQiOiIxMjMiLCJleHAiOjF9'
        '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    test('isAuthenticated retourne false si aucun token', () async {
      when(mockStorage.read(key: 'jwt_token')).thenAnswer((_) async => null);
      expect(await tokenService.isAuthenticated, false);
    });

    test('isAuthenticated retourne false si token vide', () async {
      when(mockStorage.read(key: 'jwt_token')).thenAnswer((_) async => '');
      expect(await tokenService.isAuthenticated, false);
    });

    test('isAuthenticated retourne false si token expiré (VULN-M05)', () async {
      when(mockStorage.read(key: 'jwt_token'))
          .thenAnswer((_) async => expiredToken);
      expect(await tokenService.isAuthenticated, false);
    });

    test('isAuthenticated retourne true si token valide', () async {
      when(mockStorage.read(key: 'jwt_token'))
          .thenAnswer((_) async => validToken);
      expect(await tokenService.isAuthenticated, true);
    });

    test('getValidToken efface le token expiré (VULN-C04)', () async {
      when(mockStorage.read(key: 'jwt_token'))
          .thenAnswer((_) async => expiredToken);
      when(mockStorage.delete(key: 'jwt_token')).thenAnswer((_) async => null);

      final result = await tokenService.getValidToken();
      expect(result, isNull);
      verify(mockStorage.delete(key: 'jwt_token')).called(1);
    });

    test('clearToken supprime le token et émet false sur le stream', () async {
      when(mockStorage.delete(key: 'jwt_token')).thenAnswer((_) async => null);

      final events = <bool>[];
      tokenService.authChanges.listen(events.add);

      await tokenService.clearToken();
      await Future.delayed(Duration.zero);

      expect(events, contains(false));
    });

    test('setToken null supprime le token (VULN-C03)', () async {
      when(mockStorage.delete(key: 'jwt_token')).thenAnswer((_) async => null);
      when(mockStorage.read(key: 'jwt_token')).thenAnswer((_) async => null);

      await tokenService.setToken(null);
      verify(mockStorage.delete(key: 'jwt_token')).called(1);
    });
  });
}
