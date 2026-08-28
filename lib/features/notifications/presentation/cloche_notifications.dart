import 'package:flutter/material.dart';

import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/injection_container.dart';

import '../data/notifications_remote_datasource.dart';
import 'notifications_page.dart';

/// cloche_notifications.dart — La cloche et sa pastille.
///
/// Se place dans les `actions` d'une barre haute. Elle interroge le compteur à
/// sa création et à chaque retour de l'application au premier plan : une
/// notification arrivée pendant que l'écran était en veille doit apparaître
/// sans que l'utilisateur ait à naviguer.
///
/// La pastille n'est affichée que s'il y a quelque chose à signaler — une
/// pastille à zéro attire l'œil pour rien.
class ClocheNotifications extends StatefulWidget {
  /// Couleur de l'icône, à accorder à la barre qui la porte.
  final Color couleur;

  const ClocheNotifications({super.key, this.couleur = Colors.white});

  @override
  State<ClocheNotifications> createState() => _ClocheNotificationsState();
}

class _ClocheNotificationsState extends State<ClocheNotifications>
    with WidgetsBindingObserver {
  int _nonLues = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rafraichir();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _rafraichir();
  }

  Future<void> _rafraichir() async {
    final compte = await sl<NotificationsRemoteDataSource>().compterNonLues();
    // `null` = appel en échec : on garde la dernière valeur connue plutôt que
    // de faire disparaître la pastille sur un simple incident réseau.
    if (!mounted || compte == null) return;
    setState(() => _nonLues = compte);
  }

  Future<void> _ouvrir() async {
    final restantes = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    if (!mounted) return;
    // La page renvoie le compteur à jour ; sinon on redemande.
    if (restantes != null) {
      setState(() => _nonLues = restantes);
    } else {
      _rafraichir();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: _nonLues == 0
              ? 'Notifications'
              : '$_nonLues notification${_nonLues > 1 ? 's' : ''} non lue${_nonLues > 1 ? 's' : ''}',
          icon: Icon(Icons.notifications_none_rounded,
              color: widget.couleur, size: 26),
          onPressed: _ouvrir,
        ),
        if (_nonLues > 0)
          Positioned(
            top: 6,
            right: 5,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 17),
                decoration: BoxDecoration(
                  color: const Color(0xFFE03131),
                  borderRadius: BorderRadius.circular(9),
                  // Liseré de la couleur de la barre : sans lui, la pastille
                  // se confond avec l'icône quand elle la chevauche.
                  border: Border.all(color: widget.couleur, width: 1.4),
                ),
                child: Text(
                  _nonLues > 99 ? '99+' : '$_nonLues',
                  textAlign: TextAlign.center,
                  style: AppTypo.jakarta(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
