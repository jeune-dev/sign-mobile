import 'package:intl_phone_field/countries.dart';

import 'identifiant_validator.dart';

/// pays_telephone_ui.dart — Le sélecteur d'indicatif, réduit aux pays gérés.
///
/// `IntlPhoneField` propose par défaut les deux cents pays du monde. Or un seul
/// jeu de règles était appliqué derrière : choisir le Brésil puis saisir un
/// numéro brésilien parfaitement valide se soldait par un refus incompréhensible,
/// et un numéro fantaisiste passait dès lors qu'il faisait neuf chiffres.
///
/// Le sélecteur n'offre donc plus que les pays dont SIGNS connaît les règles —
/// la liste vit dans [ReferentielIdentifiants.paysTelephone], synchronisée
/// depuis le backend au démarrage.
///
/// Ce fichier est séparé du validateur pour que celui-ci reste indépendant de
/// tout paquet d'interface : il est utilisé aussi bien hors écran.

/// Les pays proposés dans le sélecteur, dans l'ordre du référentiel — le pays
/// principal en tête.
List<Country> paysTelephoneAutorises() {
  final retenus = <Country>[];
  for (final pays in ReferentielIdentifiants.paysTelephone) {
    for (final country in countries) {
      if (country.code == pays.iso) {
        retenus.add(country);
        break;
      }
    }
  }
  // Un référentiel serveur ne correspondant à aucun code ISO connu du paquet
  // donnerait un sélecteur vide, donc un écran d'inscription inutilisable :
  // dans ce cas on rend la main à la liste complète.
  return retenus.isEmpty ? countries : retenus;
}

/// Code ISO présélectionné à l'ouverture du champ.
String paysTelephoneInitial() {
  final defaut = ReferentielIdentifiants.paysParDefaut.iso;
  final proposes = paysTelephoneAutorises();
  final connu = proposes.any((c) => c.code == defaut);
  return connu ? defaut : proposes.first.code;
}
