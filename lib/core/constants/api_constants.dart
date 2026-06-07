/// REST-M02 : Ce fichier est conservé pour compatibilité mais
/// ne doit plus être utilisé directement — utiliser Env ou sl<Dio>().
/// L'URL pointe désormais vers le backend actif (ha5a).
@Deprecated('Utiliser Env.baseUrl ou sl<Dio>() via injection_container')
class ApiConstants {
  @Deprecated('Utiliser Env.baseUrl')
  static const String baseUrl = 'https://sign-backend-ha5a.onrender.com/sign';
}
